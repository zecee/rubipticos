module Admin
  # Base de todo el backend. Por defecto cada acción exige rol administrador:
  # un controlador que también admite al editor de puntajes lo declara con
  # `allow_score_editors`. Así, una sección nueva nace cerrada.
  class BaseController < ApplicationController
    layout "admin"

    before_action :require_active_user
    before_action :require_admin

    helper_method :current_user

    def self.allow_score_editors(**options)
      skip_before_action :require_admin, **options
    end

    private

    def current_user
      Current.user
    end

    def require_active_user
      return if current_user&.active?

      terminate_session
      redirect_to new_session_path, alert: "Tu usuario está desactivado."
    end

    def require_admin
      return if current_user.admin?

      render "admin/shared/forbidden", status: :forbidden
    end
  end
end
