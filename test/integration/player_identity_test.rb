require "test_helper"

class PlayerIdentityTest < ActionDispatch::IntegrationTest
  test "home is public and only player-specific pages require identification" do
    get root_path
    assert_response :success
    assert_select "a[href=?]", new_player_path

    [ edit_player_path, new_identity_player_path ].each do |path|
      get path
      assert_redirected_to new_player_path
    end
    patch player_path, params: { player: { name: "Pedro" } }
    assert_redirected_to new_player_path
    post start_over_player_path, params: { confirmation: "1" }
    assert_redirected_to new_player_path
  end

  test "registration persists across requests and browser sessions using a signed cookie" do
    assert_difference "Player.count", 1 do
      post player_path, params: { player: { name: " Pedrito " } }
    end
    assert_redirected_to root_path
    player = Player.last
    assert_equal "Pedrito", player.name
    assert response.headers["Set-Cookie"].to_s.include?("httponly")
    assert response.headers["Set-Cookie"].to_s.include?("samesite=lax")
    assert response.headers["Set-Cookie"].to_s.include?("expires=")
    assert_not_equal player.id.to_s, cookies[:player_token]

    browser = open_session
    browser.cookies[:player_token] = cookies[:player_token]
    browser.get root_path
    browser.assert_select "nav strong", text: "Pedrito"
    browser.get edit_player_path
    browser.assert_response :success
  end

  test "invalid names and collisions are rendered with a valid suggestion without replacement" do
    Player.create!(name: "Pedrito")
    post player_path, params: { player: { name: "ab" } }
    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /al menos 3/

    assert_no_difference "Player.count" do
      post player_path, params: { player: { name: "PEDRITO" } }
    end
    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /Nombre ya está en uso/
    assert_select ".errors strong", text: "PEDRITO_2"
    assert_select "input[name='player[name]'][value='PEDRITO']"
    assert_predicate cookies[:player_token], :blank?

    post player_path, params: { player: { name: "PEDRITO_2" } }
    assert_redirected_to root_path
  end

  test "tampered malformed expired and orphaned cookies are treated as anonymous" do
    register_player
    signed_token = cookies[:player_token]
    player = Player.last

    cookies[:player_token] = "#{signed_token}tampered"
    assert_anonymous_navigation

    jar = ActionDispatch::Cookies::CookieJar.build(request, {})
    jar.signed[:player_token] = "invalid-token"
    cookies[:player_token] = jar[:player_token]
    assert_anonymous_navigation

    travel 1.year + 1.day do
      cookies[:player_token] = signed_token
      assert_anonymous_navigation
    end

    player.destroy!
    cookies[:player_token] = signed_token
    assert_anonymous_navigation
  end

  test "renaming preserves identity and ignores a client-provided player id and credentials" do
    register_player
    player = Player.last
    original_cookie = cookies[:player_token]
    other = Player.create!(name: "María")

    assert_no_difference "Player.count" do
      patch player_path, params: { player_id: other.id, player: {
        name: " Pedro ", id: other.id, token_digest: "forged", name_key: "forged"
      } }
    end
    assert_redirected_to root_path
    assert_equal "Pedro", player.reload.name
    assert_equal "María", other.reload.name
    assert_equal original_cookie, cookies[:player_token]
    get root_path
    assert_select "nav strong", text: "Pedro"
  end

  test "rename collisions preserve original database name and offer a suggestion" do
    register_player
    player = Player.last
    Player.create!(name: "María")

    patch player_path, params: { player: { name: "MARÍA" } }
    assert_response :unprocessable_entity
    assert_select ".errors strong", text: "MARÍA_2"
    assert_equal "Pedrito", player.reload.name
    get root_path
    assert_select "nav strong", text: "Pedrito"
  end

  test "starting over requires confirmation keeps the old player and issues a new identity" do
    register_player
    original = Player.last
    original_digest = original.token_digest
    original_cookie = cookies[:player_token]

    get new_identity_player_path
    assert_response :success
    assert_select "label[for=confirmation]", text: /no podré recuperar/
    assert_equal original_cookie, cookies[:player_token]

    post start_over_player_path
    assert_response :unprocessable_entity
    assert_equal original_cookie, cookies[:player_token]

    assert_no_difference "Player.count" do
      post start_over_player_path, params: { confirmation: "1" }
    end
    assert_redirected_to new_player_path
    assert_predicate cookies[:player_token], :blank?
    assert_equal original_digest, original.reload.token_digest

    post player_path, params: { player: { name: "Pedrito" } }
    assert_response :unprocessable_entity
    post player_path, params: { player: { name: "Otro jugador" } }
    assert_redirected_to root_path
    assert_not_equal original.id, Player.last.id
    assert_not_equal original_cookie, cookies[:player_token]
    assert Player.exists?(original.id)
  end

  test "deleting cookies loses access and a name alone cannot restore it" do
    register_player
    original = Player.last
    cookies.delete("player_token")

    get edit_player_path
    assert_redirected_to new_player_path
    post player_path, params: { player: { name: original.name } }
    assert_response :unprocessable_entity
    assert_predicate cookies[:player_token], :blank?
    assert Player.exists?(original.id)
  end

  test "an identified player cannot replace their identity through registration" do
    register_player
    original_cookie = cookies[:player_token]

    get new_player_path
    assert_redirected_to root_path
    assert_no_difference "Player.count" do
      post player_path, params: { player: { name: "Otro jugador" } }
    end
    assert_redirected_to root_path
    assert_equal original_cookie, cookies[:player_token]
  end

  test "identity writes require a CSRF token when forgery protection is enabled" do
    previous_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    assert_no_difference "Player.count" do
      post player_path, params: { player: { name: "Pedrito" } }
    end
    assert_response :unprocessable_entity

    get new_player_path
    token = css_select("input[name=authenticity_token]").first["value"]
    post player_path, params: { authenticity_token: token, player: { name: "Pedrito" } }
    assert_redirected_to root_path
    player = Player.last

    patch player_path, params: { player: { name: "Otro nombre" } }
    assert_response :unprocessable_entity
    assert_equal "Pedrito", player.reload.name

    post start_over_player_path, params: { confirmation: "1" }
    assert_response :unprocessable_entity
    get root_path
    assert_select "nav strong", text: "Pedrito"
  ensure
    ActionController::Base.allow_forgery_protection = previous_protection
  end

  private

  def register_player
    post player_path, params: { player: { name: "Pedrito" } }
    assert_redirected_to root_path
  end

  def assert_anonymous_navigation
    get root_path
    assert_response :success
    assert_select "nav strong", count: 0
    assert_predicate cookies[:player_token], :blank?
    get edit_player_path
    assert_redirected_to new_player_path
  end
end
