require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "accepts only known roles" do
    user = users(:one)
    user.role = "superuser"

    assert_not user.valid?
    assert_includes user.errors[:role], "no está incluido en la lista"
  end

  test "admin? and score_editor? follow the role" do
    assert users(:one).admin?
    assert users(:two).score_editor?
    assert_not users(:two).admin?
  end

  test "requires a well formed and unique email" do
    assert_not User.new(email_address: "no-es-un-email", password: "password123").valid?

    duplicate = User.new(email_address: users(:one).email_address.upcase, password: "password123")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email_address], "ya está en uso"
  end

  test "requires a password of at least eight characters" do
    user = User.new(email_address: "new@example.com", password: "short")

    assert_not user.valid?
    assert user.errors[:password].any?
  end

  test "keeps the current password when none is given" do
    user = users(:two)

    assert user.update(email_address: "renamed@example.com")
    assert user.reload.authenticate("password")
  end

  test "cannot deactivate the last active admin" do
    admin = users(:one)

    assert_not admin.update(active: false)
    assert_includes admin.errors[:base], "Tiene que quedar al menos un administrador activo."
  end

  test "cannot demote the last active admin" do
    admin = users(:one)

    assert_not admin.update(role: "score_editor")
    assert admin.reload.admin?
  end

  test "can deactivate an admin when another active admin remains" do
    User.create!(email_address: "other-admin@example.com", password: "password123", role: "admin")

    assert users(:one).update(active: false)
  end
end
