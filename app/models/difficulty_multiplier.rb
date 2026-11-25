# Multiplicador que cada dificultad aplica a los puntos del tipo de críptico.
class DifficultyMultiplier < ApplicationRecord
  MAXIMUM = 5
  DEFAULTS = { "facil" => 1, "medio" => 2, "avanzado" => 3 }.freeze

  validates :difficulty, inclusion: { in: Cryptic::DIFFICULTIES }, uniqueness: true
  validates :multiplier, numericality: { greater_than: 0, less_than_or_equal_to: MAXIMUM }

  # Un multiplicador por dificultad, de fácil a avanzado. Las dificultades sin
  # valor guardado aparecen con el inicial para poder cargarlas desde el panel.
  def self.for_all_difficulties
    by_difficulty = all.index_by(&:difficulty)
    Cryptic::DIFFICULTIES.map do |difficulty|
      by_difficulty[difficulty] || new(difficulty: difficulty, multiplier: DEFAULTS.fetch(difficulty))
    end
  end

  def self.multiplier_for(difficulty)
    find_by!(difficulty: difficulty).multiplier
  end

  def difficulty_label
    Cryptic::DIFFICULTY_LABELS.fetch(difficulty)
  end
end
