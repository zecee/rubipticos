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

    test "index paginates the catalog" do
      create_extra_cryptics(Admin::CrypticsController::PER_PAGE)
      total = Cryptic.count

      get admin_cryptics_path

      assert_select ".admin-table tbody tr", count: Admin::CrypticsController::PER_PAGE
      assert_select ".admin-pagination a[href=?]", admin_cryptics_path(page: 2)
      assert_select ".admin-pagination-info", text: /de #{total}/

      get admin_cryptics_path(page: 2)

      assert_select ".admin-table tbody tr", count: total - Admin::CrypticsController::PER_PAGE
    end

    test "index falls back to the first page on an invalid page" do
      get admin_cryptics_path(page: "abc")

      assert_response :success
      assert_select ".admin-table tbody tr", count: Cryptic.count
    end

    private

    def create_extra_cryptics(count)
      now = Time.current
      rows = Array.new(count) do |i|
        { external_id: "extra-#{i.to_s.rjust(3, "0")}", clue: "Pista #{i}", answer: "GATO",
          puzzle_type: "doble_definicion", difficulty: "facil", source: "test",
          created_at: now, updated_at: now }
      end
      Cryptic.insert_all!(rows)
    end
  end
end
