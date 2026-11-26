require "test_helper"

class AdminDisplayHelperTest < ActionView::TestCase
  include Admin::DisplayHelper

  test "admin_number groups thousands with the Spanish delimiter" do
    assert_equal "7", admin_number(7)
    assert_equal "12.345", admin_number(12_345)
    assert_equal "1.234.568", admin_number(1_234_567.8)
    assert_equal "1.234,6", admin_number(1_234.56, precision: 1)
    assert_equal "2", admin_number(2.0, precision: 2)
    assert_equal "—", admin_number(nil)
  end

  test "admin_percentage rounds and has no value without a total" do
    assert_equal "38 %", admin_percentage(3, 8)
    assert_equal "37,5 %", admin_percentage(3, 8, precision: 1)
    assert_equal "100 %", admin_percentage(5, 5)
    assert_equal "—", admin_percentage(0, 0)
  end

  test "admin_value joins lists and shows a dash when empty" do
    assert_equal "flor, río y ciudad", admin_value([ "flor", "río", "ciudad" ])
    assert_equal "—", admin_value([])
    assert_equal "—", admin_value("")
    assert_equal "—", admin_value(nil)
    assert_equal "Hola", admin_value("Hola")
  end
end
