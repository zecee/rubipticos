class User < ApplicationRecord
  ROLES = %w[admin score_editor].freeze
  ROLE_LABELS = { "admin" => "Administrador", "score_editor" => "Editor de puntajes" }.freeze

  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :role, inclusion: { in: ROLES }

  scope :active, -> { where(active: true) }

  def admin?
    role == "admin"
  end

  def score_editor?
    role == "score_editor"
  end

  def role_label
    ROLE_LABELS.fetch(role)
  end
end
