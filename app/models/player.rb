require "digest"

class Player < ApplicationRecord
  NAME_LENGTH = 3..20

  has_many :games, dependent: :restrict_with_exception
  has_many :solved_games, -> { where.not(solved_at: nil) }, class_name: "Game", inverse_of: :player

  scope :blocked, -> { where.not(blocked_at: nil) }
  scope :unblocked, -> { where(blocked_at: nil) }

  attr_reader :identity_token

  normalizes :name, with: ->(name) { name.gsub(/\A\p{Space}+|\p{Space}+\z/, "") }

  before_validation :set_name_key
  before_validation :generate_identity_token, on: :create

  validates :name, presence: true, length: { in: NAME_LENGTH }
  validates :name_key, presence: true, uniqueness: true
  validates :token_digest, presence: true, length: { is: 64 }

  def self.from_identity_token(token)
    return unless token.is_a?(String) && token.match?(/\A[A-Za-z0-9_-]{43}\z/)

    find_by(token_digest: Digest::SHA256.hexdigest(token))
  end

  def save_with_name_conflict
    save
  rescue ActiveRecord::RecordNotUnique
    raise unless self.class.where(name_key: name_key).where.not(id: id).exists?

    errors.add(:name_key, :taken)
    false
  end

  def blocked?
    blocked_at.present?
  end

  # Bloquea un nombre ofensivo: el jugador deja de aparecer en la tabla de posiciones.
  def block!
    update!(blocked_at: Time.current) unless blocked?
  end

  def unblock!
    update!(blocked_at: nil)
  end

  # Días consecutivos con al menos un críptico resuelto, terminando hoy o ayer.
  # Si ayer no resolvió nada y hoy todavía tampoco, la racha se perdió.
  def current_streak(today: Time.zone.today)
    days = solved_games.map { |game| game.solved_at.in_time_zone.to_date }.to_set
    day = days.include?(today) ? today : today.yesterday
    streak = 0
    while days.include?(day)
      streak += 1
      day = day.yesterday
    end
    streak
  end

  def pending_game
    games.pending.first
  end

  def name_suggestion
    suffix_number = 2
    loop do
      suffix = "_#{suffix_number}"
      candidate = "#{name.to_s.first(NAME_LENGTH.max - suffix.length)}#{suffix}"
      return candidate unless self.class.exists?(name_key: candidate.downcase(:fold))

      suffix_number += 1
    end
  end

  private

  def set_name_key
    self.name_key = name&.downcase(:fold)
  end

  def generate_identity_token
    return if token_digest.present?

    @identity_token = SecureRandom.urlsafe_base64(32)
    self.token_digest = Digest::SHA256.hexdigest(identity_token)
  end
end
