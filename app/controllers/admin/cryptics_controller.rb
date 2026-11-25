module Admin
  class CrypticsController < BaseController
    PER_PAGE = 10
    FILTERS = %i[difficulty puzzle_type status source].freeze

    before_action :set_cryptic, only: %i[show update]

    def index
      @filters = params.permit(*FILTERS).to_h.symbolize_keys
      @sources = Cryptic.sources
      @cryptics = Cryptic.filter_by(**@filters).order(:external_id)
                         .paginate(page: current_page, per_page: PER_PAGE)
    end

    def show
    end

    def update
      active = params.expect(cryptic: [ :active ]).fetch(:active)
      @cryptic.change_activation!(ActiveModel::Type::Boolean.new.cast(active))

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_cryptic_path(@cryptic), status: :see_other }
      end
    end

    private

    def set_cryptic
      @cryptic = Cryptic.find(params[:id])
    end
  end
end
