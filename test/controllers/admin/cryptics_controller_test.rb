require "test_helper"

module Admin
  class CrypticsControllerTest < ActionDispatch::IntegrationTest
    setup { sign_in_as users(:one) }

    test "index links each cryptic to the detail frame" do
      cryptic = cryptics(:easy)

      get admin_cryptics_path

      assert_response :success
      assert_select "turbo-frame#cryptic_detail"
      assert_select "a[href=?][data-turbo-frame=cryptic_detail]", admin_cryptic_path(cryptic), text: cryptic.external_id
    end

    test "show renders the detail inside the frame" do
      cryptic = cryptics(:easy)

      get admin_cryptic_path(cryptic), headers: { "Turbo-Frame" => "cryptic_detail" }

      assert_response :success
      assert_select "turbo-frame#cryptic_detail", text: /#{cryptic.answer}/
    end
  end
end
