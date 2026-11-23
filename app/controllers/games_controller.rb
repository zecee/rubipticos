class GamesController < PublicController
  before_action :require_player
  before_action :set_game, only: %i[show start]

  def new
    pending_game = current_player.pending_game
    redirect_to pending_game if pending_game
  end

  def create
    result = Games::Assign.new(player: current_player, difficulty: params[:difficulty]).call
    if result.success?
      redirect_to result.value, status: :see_other
    else
      @error = result.error
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @server_time = Time.current
  end

  def start
    @game.start!
    redirect_to @game, status: :see_other
  end

  private

  def set_game
    @game = current_player.games.find(params[:id])
  end
end
