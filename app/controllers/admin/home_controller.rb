module Admin
  # Entrada al backend: cada rol arranca en la sección que puede usar.
  class HomeController < BaseController
    allow_score_editors

    def show
      redirect_to current_user.admin? ? admin_cryptics_path : admin_scoring_path
    end
  end
end
