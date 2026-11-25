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

    test "index filters by difficulty" do
      get admin_cryptics_path(difficulty: "medio")

      assert_select ".admin-table tbody tr", count: 1
      assert_select "tr[id=?]", dom_id(cryptics(:medium))
      assert_select "select[name=difficulty] option[selected][value=medio]"
    end

    test "pagination keeps the filters" do
      create_extra_cryptics(Admin::CrypticsController::PER_PAGE)

      get admin_cryptics_path(difficulty: "facil")

      assert_select ".admin-pagination a[href=?]", admin_cryptics_path(difficulty: "facil", page: 2)
    end

    test "index says when no cryptic matches the filters" do
      get admin_cryptics_path(difficulty: "avanzado")

      assert_select ".admin-table", count: 0
      assert_select ".admin-empty", text: /Ningún críptico coincide/
    end

    test "index filters by puzzle type" do
      get admin_cryptics_path(puzzle_type: "oculta")

      assert_select ".admin-table tbody tr", count: 1
      assert_select "tr[id=?]", dom_id(cryptics(:medium))
      assert_select "select[name=puzzle_type] option[selected][value=oculta]"
    end

    test "index filters by status" do
      get admin_cryptics_path(difficulty: "facil", status: "inactive")

      assert_select ".admin-table tbody tr", count: 1
      assert_select "tr[id=?]", dom_id(cryptics(:inactive))
      assert_select "select[name=status] option[selected][value=inactive]"
    end

    test "index filters by source" do
      cryptics(:medium).update_columns(source: "propia")

      get admin_cryptics_path(source: "propia")

      assert_select ".admin-table tbody tr", count: 1
      assert_select "tr[id=?]", dom_id(cryptics(:medium))
      assert_select "select[name=source] option[selected][value=propia]"
      assert_select "select[name=source] option[value=test]"
    end

    test "admin deactivates and reactivates a cryptic with turbo streams" do
      cryptic = cryptics(:easy)

      patch admin_cryptic_path(cryptic), params: { cryptic: { active: "false" } }, as: :turbo_stream

      assert_response :success
      assert_not cryptic.reload.active?
      assert_select "turbo-stream[action=update][target=cryptic_detail]"
      assert_select "turbo-stream[action=update][target=?]", dom_id(cryptic, :status)

      patch admin_cryptic_path(cryptic), params: { cryptic: { active: "true" } }

      assert_redirected_to admin_cryptic_path(cryptic)
      assert_predicate cryptic.reload, :active?
    end

    test "update only changes the activation" do
      cryptic = cryptics(:easy)

      patch admin_cryptic_path(cryptic), params: { cryptic: { active: "false", answer: "OTRA" } }

      assert_equal "SECRETO", cryptic.reload.answer
      assert_not cryptic.active?
    end

    test "score editor cannot change a cryptic" do
      sign_in_as users(:two)
      cryptic = cryptics(:easy)

      patch admin_cryptic_path(cryptic), params: { cryptic: { active: "false" } }

      assert_response :forbidden
      assert_predicate cryptic.reload, :active?
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
