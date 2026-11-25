module Admin
  class CrypticsController < BaseController
    PER_PAGE = 10

    def index
      @cryptics = Cryptic.order(:external_id).paginate(page: current_page, per_page: PER_PAGE)
    end

    def show
      @cryptic = Cryptic.find(params[:id])
    end
  end
end
