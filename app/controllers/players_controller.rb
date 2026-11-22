class PlayersController < PublicController
  before_action :require_player, only: %i[edit update new_identity start_over]
  before_action :redirect_identified_player, only: %i[new create]

  def new
    @player = Player.new
  end

  def create
    @player = Player.new(player_params)
    if @player.save_with_name_conflict
      identify_player(@player)
      redirect_to root_path, notice: "¡Bienvenido, #{@player.name}!", status: :see_other
    else
      render_name_form(:new)
    end
  end

  def edit
    @player = current_player
  end

  def update
    @player = current_player
    @player.assign_attributes(player_params)
    if @player.save_with_name_conflict
      redirect_to root_path, notice: "Tu nombre fue actualizado.", status: :see_other
    else
      render_name_form(:edit)
    end
  end

  def new_identity
  end

  def start_over
    unless params[:confirmation] == "1"
      flash.now[:alert] = "Tenés que confirmar que perderás el acceso al jugador anterior."
      return render :new_identity, status: :unprocessable_entity
    end

    forget_player
    redirect_to new_player_path, notice: "Elegí un nombre para tu nuevo jugador.", status: :see_other
  end

  private

  def player_params
    params.expect(player: [ :name ])
  end

  def render_name_form(template)
    @suggested_name = @player.name_suggestion if @player.errors.of_kind?(:name_key, :taken)
    render template, status: :unprocessable_entity
  end

  def redirect_identified_player
    redirect_to root_path if current_player
  end
end
