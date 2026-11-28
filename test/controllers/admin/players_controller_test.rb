require "test_helper"

module Admin
  class PlayersControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in_as users(:one)
      @player = Player.create!(name: "Ofensivo")
    end

    test "index lists players with their streak and state" do
      get admin_players_path

      assert_response :success
      assert_select "tr##{dom_id(@player)}" do
        assert_select "td", text: "Ofensivo"
        assert_select "td", text: "0 días"
        assert_select ".admin-pill", text: "Visible"
        assert_select "form[action=?] button", block_admin_player_path(@player), text: "Bloquear"
      end
    end

    test "block and reset buttons ask for confirmation" do
      get admin_players_path

      assert_select "form[action=?][data-turbo-confirm]", block_admin_player_path(@player)
      assert_select "form[action=?][data-turbo-confirm]", reset_leaderboard_admin_players_path
    end

    test "admin blocks and unblocks a player" do
      patch block_admin_player_path(@player)

      assert_redirected_to admin_players_path
      assert @player.reload.blocked?

      follow_redirect!
      assert_select "tr##{dom_id(@player)} .admin-pill", text: "Bloqueado"
      assert_select "form[action=?] button", unblock_admin_player_path(@player), text: "Desbloquear"

      patch unblock_admin_player_path(@player)

      assert_not @player.reload.blocked?
    end

    test "admin resets the leaderboard" do
      freeze_time do
        post reset_leaderboard_admin_players_path

        assert_redirected_to admin_players_path
        assert_equal Time.current, AppSetting.instance.leaderboard_reset_at
      end
    end

    test "index paginates players" do
      PlayersController::PER_PAGE.times { |i| Player.create!(name: "Jugador #{i}") }

      get admin_players_path

      assert_select ".admin-table tbody tr", count: PlayersController::PER_PAGE
      assert_select ".admin-pagination a[href=?]", admin_players_path(page: 2)
    end

    test "score editor cannot block players or reset the leaderboard" do
      sign_in_as users(:two)

      patch block_admin_player_path(@player)
      assert_response :forbidden
      assert_not @player.reload.blocked?

      post reset_leaderboard_admin_players_path
      assert_response :forbidden
      assert_nil AppSetting.instance.leaderboard_reset_at
    end
  end
end
