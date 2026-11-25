class CreateScoringRules < ActiveRecord::Migration[8.1]
  PUZZLE_TYPES = %w[
    anagrama oculta charada contenedor inversion supresion homofono
    doble_definicion iniciales finales sustitucion simbolos combinada
  ].freeze
  DIFFICULTIES = %w[facil medio avanzado].freeze

  def change
    create_table :puzzle_type_scores do |t|
      t.string :puzzle_type, null: false
      t.integer :points, null: false
      t.timestamps

      t.index :puzzle_type, unique: true
      t.check_constraint "points BETWEEN 10 AND 1000", name: "puzzle_type_scores_points_range"
      t.check_constraint "puzzle_type IN (#{quoted(PUZZLE_TYPES)})", name: "puzzle_type_scores_type_allowed"
    end

    create_table :difficulty_multipliers do |t|
      t.string :difficulty, null: false
      t.decimal :multiplier, precision: 3, scale: 2, null: false
      t.timestamps

      t.index :difficulty, unique: true
      t.check_constraint "multiplier > 0 AND multiplier <= 5", name: "difficulty_multipliers_range"
      t.check_constraint "difficulty IN (#{quoted(DIFFICULTIES)})", name: "difficulty_multipliers_difficulty_allowed"
    end
  end

  private

  def quoted(values)
    values.map { |value| "'#{value}'" }.join(", ")
  end
end
