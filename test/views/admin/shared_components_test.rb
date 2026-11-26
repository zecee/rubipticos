require "test_helper"

class AdminSharedComponentsTest < ActionView::TestCase
  test "card renders a labelled section with its title, actions and content" do
    render "admin/shared/card", title: "Fuente del catálogo", actions: tag.button("Sincronizar") do
      tag.p("Contenido", class: "inside")
    end

    assert_select "section.admin-card[aria-labelledby=?]", "fuente-del-catalogo-title" do
      assert_select "h2#fuente-del-catalogo-title", text: "Fuente del catálogo"
      assert_select ".admin-card__actions button", text: "Sincronizar"
      assert_select "p.inside", text: "Contenido"
    end
  end

  test "card can use another element and a modifier, and skips empty actions" do
    render "admin/shared/card", title: "Detalle", element: :article, modifier: "narrow" do
      "Texto"
    end

    assert_select "article.admin-card.admin-card--narrow"
    assert_select ".admin-card__actions", count: 0
  end

  test "kpi renders label, value, optional hint and tone" do
    render "admin/shared/kpi", label: "Crípticos activos", value: "1.234", hint: "de 1.500", tone: "ok"

    assert_select ".admin-kpi.admin-kpi--ok" do
      assert_select "dt.admin-kpi__label", text: "Crípticos activos"
      assert_select "dd.admin-kpi__value", text: "1.234"
      assert_select "dd.admin-kpi__hint", text: "de 1.500"
    end
  end

  test "kpi without hint or tone" do
    render "admin/shared/kpi", label: "Jugadores", value: "0"

    assert_select ".admin-kpi[class=?]", "admin-kpi"
    assert_select ".admin-kpi__hint", count: 0
  end
end
