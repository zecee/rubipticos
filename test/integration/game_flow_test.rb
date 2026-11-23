require "test_helper"

class GameFlowTest < ActionDispatch::IntegrationTest
  test "all game routes require identification and GET never assigns" do
    get root_path
    assert_response :success
    assert_select "nav a[href=?]", new_game_path, text: "Jugar"

    assert_no_difference "Game.count" do
      [ new_game_path, game_path(123) ].each do |path|
        get path
        assert_redirected_to new_player_path
      end
      post games_path, params: { difficulty: "facil" }
      assert_redirected_to new_player_path
      post start_game_path(123)
      assert_redirected_to new_player_path
      register_player
      get new_game_path
      assert_response :success
      assert_select "option[value=facil]", text: "Fácil"
      assert_select "option[value=medio]", text: "Medio"
      assert_select "option[value=avanzado]", text: "Avanzado"
    end
  end

  test "assignment is persisted but never exposes puzzle content before explicit start" do
    register_player
    other = Player.create!(name: "Otro jugador")
    assert_difference "Game.count", 1 do
      post games_path, params: { difficulty: "facil", cryptic_id: cryptics(:medium).id, player_id: other.id }
    end
    game = Game.last
    assert_equal Player.find_by!(name: "Jugador"), game.player
    assert_equal cryptics(:easy), game.cryptic
    assert_redirected_to game_path(game)
    follow_redirect!
    assert_response :success
    assert_select "form[action=?][method=post]", start_game_path(game)
    assert_no_puzzle_secrets
    [ *game.cryptic.definitions, *game.cryptic.indicators, *game.cryptic.material ].each do |part|
      assert_not_includes response.body, part
    end
    assert_not_includes response.body, game.cryptic.clue
    assert_not_includes response.body, game.cryptic.enumeration
    assert_not_includes response.body, "data-game-timer-started-at-value"
    assert_nil game.reload.started_at

    assert_no_difference "Game.count" do
      post games_path, params: { difficulty: "medio" }
      assert_redirected_to game_path(game)
      get new_game_path
      assert_redirected_to game_path(game)
    end
  end

  test "start is idempotent and another browser resumes using server elapsed time" do
    register_player
    post games_path, params: { difficulty: "facil" }
    game = Game.last
    game.cryptic.update!(active: false)

    freeze_time do
      post start_game_path(game), params: { started_at: 1.year.ago, status: "PREPARED" }
      assert_redirected_to game_path(game)
      assert_equal Time.current, game.reload.started_at
      follow_redirect!
      assert_select "h2", text: "#{game.cryptic.clue} #{game.cryptic.enumeration}"
      assert_no_puzzle_secrets
      assert_select "input[name=answer]", count: 0

      travel 25.hours + 65.seconds
      post start_game_path(game)
      assert_equal 90065, game.reload.elapsed_seconds
      browser = open_session
      browser.cookies[:player_token] = cookies[:player_token]
      browser.get new_game_path
      browser.assert_redirected_to game_path(game)
      browser.follow_redirect!
      browser.assert_select "time", text: "90065 s"
      browser.assert_select "[data-game-timer-started-at-value=?]", game.started_at.iso8601(3)
      browser.assert_select "[data-game-timer-server-time-value=?]", Time.current.iso8601(3)
      browser.assert_select "meta[name=turbo-cache-control][content=no-cache]"
      assert_equal 90065, game.reload.elapsed_seconds
    end
  end

  test "invalid difficulty and catalog exhaustion render clear errors" do
    register_player
    assert_no_difference "Game.count" do
      post games_path, params: { difficulty: "invalida" }
      assert_response :unprocessable_entity
      assert_select "[role=alert]", text: /dificultad válida/
      post games_path, params: { difficulty: "avanzado" }
      assert_response :unprocessable_entity
      assert_select "[role=alert]", text: "Críptico debe existir"
    end
  end

  test "another player cannot read or start a game even with forged player parameters" do
    owner = Player.create!(name: "Dueño")
    game = owner.games.create!(cryptic: cryptics(:easy))
    register_player

    get game_path(game), params: { player_id: owner.id }
    assert_response :not_found
    assert_not_includes response.body, game.cryptic.clue
    post start_game_path(game), params: { player_id: owner.id }
    assert_response :not_found
    assert_nil game.reload.started_at
    game.start!
    get game_path(game)
    assert_response :not_found
    assert_not_includes response.body, game.cryptic.answer
  end

  test "assignment and start require CSRF tokens when protection is enabled" do
    register_player
    previous_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    assert_no_difference "Game.count" do
      post games_path, params: { difficulty: "facil" }
      assert_response :unprocessable_entity
    end
    get new_game_path
    token = css_select("input[name=authenticity_token]").first["value"]
    post games_path, params: { difficulty: "facil", authenticity_token: token }
    game = Game.last
    assert_redirected_to game_path(game)
    post start_game_path(game)
    assert_response :unprocessable_entity
    assert_nil game.reload.started_at
  ensure
    ActionController::Base.allow_forgery_protection = previous_protection
  end

  private

  def register_player
    post player_path, params: { player: { name: "Jugador" } }
    assert_redirected_to root_path
  end

  def assert_no_puzzle_secrets
    cryptic = cryptics(:easy)
    [ cryptic.answer, cryptic.hint, cryptic.explanation ].each do |secret|
      assert_not_includes response.body, secret
    end
  end
end
