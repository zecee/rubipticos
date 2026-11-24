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
end
