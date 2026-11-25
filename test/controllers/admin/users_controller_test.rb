require "test_helper"

module Admin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    setup { sign_in_as users(:one) }

    test "index lists every user with role and state" do
      get admin_users_path

      assert_response :success
      assert_select "tr##{dom_id(users(:two))}", text: /Editor de puntajes/
      assert_select "tr##{dom_id(users(:inactive))}", text: /Inactivo/
    end

    test "creates a user" do
      assert_difference "User.count", 1 do
        post admin_users_path, params: { user: {
          email_address: "nuevo@example.com", password: "secreto123", password_confirmation: "secreto123",
          role: "score_editor"
        } }
      end

      assert_redirected_to admin_users_path
      user = User.find_by!(email_address: "nuevo@example.com")
      assert user.score_editor?
      assert user.active?
      assert user.authenticate("secreto123")
    end

    test "rerenders the form when the user is invalid" do
      assert_no_difference "User.count" do
        post admin_users_path, params: { user: { email_address: "", password: "", role: "admin" } }
      end

      assert_response :unprocessable_entity
      assert_select ".admin-flash--alert"
    end

    test "updates email and role keeping the password when left blank" do
      user = users(:two)

      patch admin_user_path(user), params: { user: {
        email_address: "editor@example.com", password: "", password_confirmation: "", role: "admin"
      } }

      assert_redirected_to admin_users_path
      user.reload
      assert_equal "editor@example.com", user.email_address
      assert user.admin?
      assert user.authenticate("password")
    end

    test "changes the password when given" do
      user = users(:two)

      patch admin_user_path(user), params: { user: { password: "otraclave1", password_confirmation: "otraclave1" } }

      assert user.reload.authenticate("otraclave1")
    end

    test "deactivates and reactivates a user" do
      user = users(:two)

      patch deactivate_admin_user_path(user)
      assert_redirected_to admin_users_path
      assert_not user.reload.active?

      patch activate_admin_user_path(user)
      assert user.reload.active?
    end

    test "an admin cannot deactivate themselves" do
      User.create!(email_address: "other-admin@example.com", password: "password123", role: "admin")

      patch deactivate_admin_user_path(users(:one))

      assert_redirected_to admin_users_path
      assert_equal "No podés desactivar tu propio usuario.", flash[:alert]
      assert users(:one).reload.active?
    end

    test "an admin cannot change their own role" do
      User.create!(email_address: "other-admin@example.com", password: "password123", role: "admin")

      patch admin_user_path(users(:one)), params: { user: { role: "score_editor" } }

      assert users(:one).reload.admin?
    end

    test "score editors cannot manage users" do
      sign_in_as users(:two)

      get new_admin_user_path
      assert_response :forbidden

      assert_no_difference "User.count" do
        post admin_users_path, params: { user: { email_address: "x@example.com", password: "password123", role: "admin" } }
      end
      assert_response :forbidden

      patch admin_user_path(users(:two)), params: { user: { role: "admin" } }
      assert_response :forbidden
      assert users(:two).reload.score_editor?

      patch deactivate_admin_user_path(users(:one))
      assert_response :forbidden
      assert users(:one).reload.active?
    end
  end
end
