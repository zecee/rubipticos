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

      get admin_cryptics_path(page: 2)

      assert_select ".admin-table tbody tr", count: total - Admin::CrypticsController::PER_PAGE
    end

    test "pagination hides first page arrow on the first page" do
      create_extra_cryptics(Admin::CrypticsController::PER_PAGE * 2)

      get admin_cryptics_path

      assert_select ".admin-pagination .first_page", count: 0
      assert_select ".admin-pagination span.previous_page.disabled[aria-disabled=true]"
      assert_select ".admin-pagination a.next_page[href=?][aria-label=?]", admin_cryptics_path(page: 2), "Página siguiente"
      assert_select ".admin-pagination a.last_page[href=?][aria-label=?]", admin_cryptics_path(page: 3), "Última página"
    end

    test "pagination shows every arrow on a middle page" do
      create_extra_cryptics(Admin::CrypticsController::PER_PAGE * 2)

      get admin_cryptics_path(page: 2)

      assert_select ".admin-pagination a.first_page[href=?][aria-label=?]", admin_cryptics_path(page: 1), "Primera página"
      assert_select ".admin-pagination a.previous_page[href=?]", admin_cryptics_path(page: 1)
      assert_select ".admin-pagination a.next_page[href=?]", admin_cryptics_path(page: 3)
      assert_select ".admin-pagination a.last_page[href=?]", admin_cryptics_path(page: 3)
      assert_select ".admin-pagination em.current[aria-current=page]", text: "2"
    end

    test "pagination hides last page arrow on the last page" do
      create_extra_cryptics(Admin::CrypticsController::PER_PAGE * 2)

      get admin_cryptics_path(page: 3)

      assert_select ".admin-pagination a.first_page[href=?]", admin_cryptics_path(page: 1)
      assert_select ".admin-pagination span.next_page.disabled"
      assert_select ".admin-pagination .last_page", count: 0
    end

    test "pagination shows a window of pages around the current one" do
      create_extra_cryptics(Admin::CrypticsController::PER_PAGE * 9)

      get admin_cryptics_path(page: 5)

      assert_select ".admin-pagination a[aria-label^='Página '], .admin-pagination em.current",
                    text: /\A\d+\z/, count: 5
      assert_select ".admin-pagination em.current", text: "5"
      assert_select ".admin-pagination a[href=?]", admin_cryptics_path(page: 3)
      assert_select ".admin-pagination a[href=?]", admin_cryptics_path(page: 7)
      assert_select ".admin-pagination .gap", count: 2
      assert_select ".admin-pagination a.admin-pagination__far", count: 2
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
