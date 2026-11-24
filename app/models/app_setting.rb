class AppSetting < ApplicationRecord
  DEFAULT_SOURCE_URL = "https://ecorrons.github.io/cryptics-api/v1/cryptics.json".freeze
  DEFAULT_WELCOME_TEXT = "Resolvé crípticos, sumá puntos y mantené tu racha.".freeze

  attribute :source_url, :string, default: DEFAULT_SOURCE_URL
  attribute :welcome_text, :string, default: DEFAULT_WELCOME_TEXT

  validates :source_url, :welcome_text, presence: true
  validate :source_url_is_http

  # Única fila de configuración.
  def self.instance
    find_or_create_by!(id: 1)
  end

  # La tabla de posiciones solo cuenta partidas resueltas desde este momento.
  def reset_leaderboard!
    update!(leaderboard_reset_at: Time.current)
  end

  private

  def source_url_is_http
    return if source_url.blank?

    uri = URI.parse(source_url)
    errors.add(:source_url, "debe ser una URL http o https válida") unless uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    errors.add(:source_url, "debe ser una URL http o https válida")
  end
end