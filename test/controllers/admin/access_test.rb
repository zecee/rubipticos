require "test_helper"

module Admin
  class AccessTest < ActionDispatch::IntegrationTest
    ADMIN_ONLY_PATHS = %i[
      admin_cryptics_path admin_syncs_path admin_players_path admin_settings_path admin_users_path
    ].freeze

    test "requires a session" do
      get admin_cryptics_path

      assert_redirected_to new_session_path
    end

    test "admin root sends each role to its first section" do
      sign_in_as users(:one)
      get admin_root_path
      assert_redirected_to admin_cryptics_path

      sign_in_as users(:two)
      get admin_root_path
      assert_redirected_to admin_scoring_path
    end

    test "admin can open every section" do
      sign_in_as users(:one)

      (ADMIN_ONLY_PATHS + [ :admin_scoring_path ]).each do |path|
        get public_send(path)
        assert_response :success, "#{path} should be reachable by an admin"
      end
    end

    test "score editor can open scoring" do
      sign_in_as users(:two)

      get admin_scoring_path

      assert_response :success
    end

    test "score editor is rejected from admin-only sections even typing the URL" do
      sign_in_as users(:two)

      ADMIN_ONLY_PATHS.each do |path|
        get public_send(path)
        assert_response :forbidden, "#{path} should be forbidden for a score editor"
      end

      get admin_cryptic_path(cryptics(:easy))
      assert_response :forbidden
    end

    test "menu shows only the sections the role can use" do
      sign_in_as users(:two)
      get admin_scoring_path

      assert_select ".admin-nav a", count: 1
      assert_select ".admin-nav a[href=?]", admin_scoring_path
      assert_select ".admin-nav a", text: "Crípticos", count: 0

      sign_in_as users(:one)
      get admin_scoring_path

      assert_select ".admin-nav a", count: 6
    end

    test "inactive user loses the session" do
      sign_in_as users(:inactive)

      get admin_scoring_path

      assert_redirected_to new_session_path
      assert_empty cookies[:session_id]
    end
  end
end
