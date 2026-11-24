module Admin
  module NavigationHelper
    # Link del menú lateral. `section` es el controller_name que lo marca como activo.
    def admin_nav_link(label, path, section:)
      active = controller_name == section
      link_to label, path, class: [ "admin-nav__link", ("is-active" if active) ],
                           aria: { current: ("page" if active) }
    end
  end
end
