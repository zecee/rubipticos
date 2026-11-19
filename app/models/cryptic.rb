class Cryptic < ApplicationRecord
  PUZZLE_TYPES = %w[
    anagrama oculta charada contenedor inversion supresion homofono
    doble_definicion iniciales finales sustitucion simbolos combinada
  ].freeze
  DIFFICULTIES = %w[facil medio avanzado].freeze

  attr_accessor :source_enumeration

  validates :external_id, :clue, :answer, :source, presence: true
  validates :external_id, uniqueness: true
  validates :puzzle_type, inclusion: { in: PUZZLE_TYPES }
  validates :difficulty, inclusion: { in: DIFFICULTIES }
  validate :source_enumeration_matches_answer, unless: -> { source_enumeration.nil? }

  def enumeration
    return if answer.blank?

    "(#{answer.unicode_normalize(:nfc).gsub(/\p{Space}/, "").length})"
  end

  private

  def source_enumeration_matches_answer
    if source_enumeration != enumeration
      errors.add(:source_enumeration, "must match the answer length")
    end
  end
end
