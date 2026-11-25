require "test_helper"

class AdminCrypticsHelperTest < ActionView::TestCase
  include Admin::CrypticsHelper

  test "solve_time shows seconds alone or minutes with padded seconds" do
    assert_equal "—", solve_time(nil)
    assert_equal "42 s", solve_time(42)
    assert_equal "1 min 05 s", solve_time(65)
    assert_equal "12 min 00 s", solve_time(720)
  end
end
