# Puntos que vale cada tipo de críptico. Junto con el multiplicador de la
# dificultad forman la base del puntaje de una partida.
class PuzzleTypeScore < ApplicationRecord
  POINTS_RANGE = 10..1000
  DEFAULT_POINTS = 100

  validates :puzzle_type, inclusion: { in: Cryptic::PUZZLE_TYPES }, uniqueness: true
  validates :points, numericality: {
    only_integer: true, greater_than_or_equal_to: POINTS_RANGE.min, less_than_or_equal_to: POINTS_RANGE.max
  }

  # Una regla por tipo, en el orden del catálogo. Los tipos sin regla guardada
  # aparecen con el valor inicial para poder cargarlos desde el panel.
  def self.for_all_types
    by_type = all.index_by(&:puzzle_type)
    Cryptic::PUZZLE_TYPES.map { |type| by_type[type] || new(puzzle_type: type, points: DEFAULT_POINTS) }
  end

  def self.points_for(puzzle_type)
    find_by!(puzzle_type: puzzle_type).points
  end

  def puzzle_type_label
    Cryptic::PUZZLE_TYPE_LABELS.fetch(puzzle_type)
  end
end
