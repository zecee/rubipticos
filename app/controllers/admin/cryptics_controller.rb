module Admin
  class CrypticsController < BaseController
    def index
      @cryptics = Cryptic.order(:external_id)
    end

    def show
      @cryptic = Cryptic.find(params[:id])
    end
  end
end
