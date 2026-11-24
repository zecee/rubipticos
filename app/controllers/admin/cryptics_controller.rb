module Admin
  class CrypticsController < BaseController
    def index
      @cryptics = Cryptic.order(:external_id)
    end
  end
end
