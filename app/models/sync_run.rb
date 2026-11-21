class SyncRun < ApplicationRecord
  STATUSES = %w[completed unchanged failed].freeze
  STATUS_LABELS = { "completed" => "Completada", "unchanged" => "Sin cambios", "failed" => "Con error" }.freeze

  belongs_to :user, optional: true

  validates :status, inclusion: { in: STATUSES }
  validates :created_count, :updated_count, :deactivated_count, :rejected_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :completed, -> { where(status: "completed") }

  def status_label
    STATUS_LABELS.fetch(status)
  end
end