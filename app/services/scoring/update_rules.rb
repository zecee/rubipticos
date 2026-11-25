module Scoring
  # Guarda juntos los puntos por tipo y los multiplicadores por dificultad:
  # o se aplican todos los cambios o ninguno.
  class UpdateRules
    attr_reader :type_scores, :multipliers

    def initialize(points: {}, multipliers: {})
      @points = points.to_h
      @multiplier_values = multipliers.to_h
      @type_scores = PuzzleTypeScore.for_all_types
      @multipliers = DifficultyMultiplier.for_all_difficulties
    end

    def call
      assign_values
      records = type_scores + multipliers
      invalid = records.reject(&:valid?)
      raise ActiveRecord::RecordInvalid, invalid.first if invalid.any?

      ActiveRecord::Base.transaction { records.each(&:save!) }
      records
    end

    private

    def assign_values
      type_scores.each { |score| score.points = @points.fetch(score.puzzle_type, score.points) }
      multipliers.each do |rule|
        rule.multiplier = @multiplier_values.fetch(rule.difficulty, rule.multiplier)
      end
    end
  end
end
