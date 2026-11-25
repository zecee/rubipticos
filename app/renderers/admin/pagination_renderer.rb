require "will_paginate/view_helpers/action_view"

module Admin
  # Paginación del admin: primera, anterior, una ventana de páginas, siguiente y última.
  # Anterior y siguiente están siempre (deshabilitadas en los bordes); primera y última
  # se ocultan cuando ya se está en esa página.
  class PaginationRenderer < WillPaginate::ActionView::LinkRenderer
    ICONS = {
      first_page: '<path d="M11 17l-5-5 5-5M18 17l-5-5 5-5"/>',
      previous_page: '<path d="M15 18l-6-6 6-6"/>',
      next_page: '<path d="M9 18l6-6-6-6"/>',
      last_page: '<path d="M13 17l5-5-5-5M6 17l5-5-5-5"/>'
    }.freeze

    def pagination
      items = [ :previous_page, *page_window, :next_page ]
      items.unshift(:first_page) if current_page > 1
      items.push(:last_page) if current_page < total_pages
      items
    end

    protected

    def first_page
      arrow_link(1, :first_page, translate(:first_aria_label, "First page"))
    end

    def last_page
      arrow_link(total_pages, :last_page, translate(:last_aria_label, "Last page"))
    end

    def previous_page
      page = current_page > 1 && current_page - 1
      arrow_link(page, :previous_page, translate(:previous_aria_label, "Previous page"))
    end

    def next_page
      page = current_page < total_pages && current_page + 1
      arrow_link(page, :next_page, translate(:next_aria_label, "Next page"))
    end

    # En el celular solo se ven las páginas vecinas; las más lejanas llevan una clase para ocultarlas.
    def page_number(page)
      return super if (page - current_page).abs <= 1

      label = @template.will_paginate_translate(:page_aria_label, page: page) { "Page #{page}" }
      link(page, page, class: "admin-pagination__far", "aria-label": label)
    end

    private

    # Las páginas alrededor de la actual (inner_window para cada lado), con «…» si hay más.
    def page_window
      size = @options[:inner_window].to_i * 2
      from = (current_page - (size / 2)).clamp(1, [ total_pages - size, 1 ].max)
      to = [ from + size, total_pages ].min
      pages = (from..to).to_a
      pages.unshift(:gap) if from > 1
      pages.push(:gap) if to < total_pages
      pages
    end

    def arrow_link(page, name, label)
      classes = "#{name} admin-pagination__arrow"
      if page
        link(icon(name), page, class: classes, "aria-label": label, title: label)
      else
        tag(:span, icon(name), class: "#{classes} disabled", "aria-label": label, "aria-disabled": "true")
      end
    end

    def icon(name)
      %(<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true" focusable="false">#{ICONS.fetch(name)}</svg>)
    end

    def translate(key, default)
      @template.will_paginate_translate(key) { default }
    end
  end
end
