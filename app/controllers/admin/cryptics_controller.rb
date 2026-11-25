module Admin
  class CrypticsController < BaseController
    PER_PAGE = 10

    def index
      @cryptics = Cryptic.order(:external_id).paginate(page: current_page, per_page: PER_PAGE)
    end

    def show
      @cryptic = Cryptic.find(params[:id])
    end

    private

    # will_paginate falla con páginas que no son números positivos; en ese caso, la primera.
    def current_page
      page = params[:page].to_s
      page.match?(/\A[1-9]\d*\z/) ? page.to_i : 1
    end
  end
end
