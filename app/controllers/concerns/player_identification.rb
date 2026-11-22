module PlayerIdentification
  extend ActiveSupport::Concern

  included do
    helper_method :current_player
  end

  private

  def current_player
    return @current_player if defined?(@current_player)

    @current_player = Player.from_identity_token(cookies.signed[:player_token])
    cookies.delete(:player_token, path: "/") if @current_player.nil? && cookies[:player_token].present?
    @current_player
  end

  def require_player
    redirect_to new_player_path, alert: "Elegí un nombre para continuar." unless current_player
  end

  def identify_player(player)
    cookies.signed[:player_token] = {
      value: player.identity_token,
      expires: 1.year.from_now,
      httponly: true,
      same_site: :lax,
      secure: Rails.env.production?,
      path: "/"
    }
    @current_player = player
  end

  def forget_player
    cookies.delete(:player_token, path: "/")
    @current_player = nil
  end
end
