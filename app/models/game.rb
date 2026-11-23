class Game < ApplicationRecord
  STATUSES = %w[PREPARED IN_PROGRESS].freeze

  belongs_to :player
  belongs_to :cryptic

  scope :pending, -> { where(status: %w[PREPARED IN_PROGRESS]) }

  validates :status, inclusion: { in: STATUSES }
  validates :cryptic_id, uniqueness: { scope: :player_id }
  validates :player_id, uniqueness: { conditions: -> { pending } }
  validates :started_at, absence: true, if: :prepared?
  validates :started_at, presence: true, if: :in_progress?
  validates :solved_at, absence: true

  def prepared?
    status == "PREPARED"
  end

  def in_progress?
    status == "IN_PROGRESS"
  end

  def start!
    with_lock do
      update!(status: "IN_PROGRESS", started_at: Time.current) if prepared?
    end
    self
  end

  def elapsed_seconds(at: Time.current)
    started_at ? [ (at - started_at).to_i, 0 ].max : 0
  end
end
