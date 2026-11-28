class User < ApplicationRecord
  ROLES = %w[admin score_editor].freeze
  ROLE_LABELS = { "admin" => "Administrador", "score_editor" => "Editor de puntajes" }.freeze
  PASSWORD_MIN_LENGTH = 8

  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: PASSWORD_MIN_LENGTH }, allow_nil: true
  validates :role, inclusion: { in: ROLES }
  validate :keeps_an_active_admin, if: :losing_admin_access?

  scope :active, -> { where(active: true) }
  scope :active_admins, -> { active.where(role: "admin") }

  def admin?
    role == "admin"
  end

  def score_editor?
    role == "score_editor"
  end

  def role_label
    ROLE_LABELS.fetch(role)
  end

  private

  # Un administrador activo que deja de serlo, sea porque cambia de rol o porque se desactiva.
  def losing_admin_access?
    persisted? && role_was == "admin" && active_was && !(admin? && active?)
  end

  def keeps_an_active_admin
    return if User.active_admins.where.not(id: id).exists?

    errors.add(:base, "Tiene que quedar al menos un administrador activo.")
  end
end
