module Admin
  class CrypticsController < BaseController
    PER_PAGE = 10
    FILTERS = %i[difficulty puzzle_type status].freeze

    def index
      @filters = params.permit(*FILTERS).to_h.symbolize_keys
      @cryptics = Cryptic.filter_by(**@filters).order(:external_id)
                         .paginate(page: current_page, per_page: PER_PAGE)
    end

    def show
      @cryptic = Cryptic.find(params[:id])
    end
  end
end
