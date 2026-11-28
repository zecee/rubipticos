module Admin
  class PlayersController < BaseController
    PER_PAGE = 20

    def index
      @players = Player.includes(:solved_games).order(:name_key).paginate(page: current_page, per_page: PER_PAGE)
      @leaderboard_reset_at = AppSetting.instance.leaderboard_reset_at
    end

    def block
      player = Player.find(params[:id])
      player.block!
      redirect_back_to_list notice: "#{player.name} quedó bloqueado y no aparece en la tabla de posiciones."
    end

    def unblock
      player = Player.find(params[:id])
      player.unblock!
      redirect_back_to_list notice: "#{player.name} volvió a la tabla de posiciones."
    end

    def reset_leaderboard
      AppSetting.instance.reset_leaderboard!
      redirect_back_to_list notice: "Tabla de posiciones reiniciada."
    end

    private

    def redirect_back_to_list(notice:)
      redirect_to admin_players_path(page: params[:page]), status: :see_other, notice: notice
    end
  end
end
