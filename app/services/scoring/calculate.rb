module Scoring
  # Puntos de un críptico resuelto, según el enunciado:
  #   puntos = base × tiempo × pistas × racha
  # La partida guarda el resultado al resolverse; por eso un cambio en las
  # reglas no recalcula partidas viejas.
  class Calculate
    REFERENCE_SECONDS = { "facil" => 60, "medio" => 180, "avanzado" => 300 }.freeze
    MIN_TIME_FACTOR = Rational(1, 4)
    HINT_PENALTY = Rational(1, 5)
    MAX_HINTS = 4
    STREAK_BONUS_PER_DAY = Rational(1, 20)
    MAX_STREAK_FACTOR = Rational(3, 2)
    MINIMUM_POINTS = 10

    def initialize(cryptic:, elapsed_seconds:, hints_used:, streak_days:)
      @cryptic = cryptic
      @elapsed_seconds = elapsed_seconds
      @hints_used = hints_used
      @streak_days = streak_days
    end

    def call
      raise ArgumentError, "hints_used debe estar entre 0 y #{MAX_HINTS}" unless (0..MAX_HINTS).cover?(@hints_used)
      raise ArgumentError, "streak_days no puede ser negativo" if @streak_days.negative?
      raise ArgumentError, "elapsed_seconds no puede ser negativo" if @elapsed_seconds.negative?

      points = base * time_factor * hints_factor * streak_factor
      [ points.round, MINIMUM_POINTS ].max
    end

    private

    def base
      PuzzleTypeScore.points_for(@cryptic.puzzle_type) *
        DifficultyMultiplier.multiplier_for(@cryptic.difficulty).to_r
    end

    def time_factor
      reference = REFERENCE_SECONDS.fetch(@cryptic.difficulty)
      return 1 if @elapsed_seconds <= reference

      [ Rational(reference) / @elapsed_seconds.to_r, MIN_TIME_FACTOR ].max
    end

    def hints_factor
      1 - (HINT_PENALTY * @hints_used)
    end

    # La racha cuenta el día de hoy, así que quien resuelve tiene al menos 1.
    def streak_factor
      [ 1 + (STREAK_BONUS_PER_DAY * @streak_days), MAX_STREAK_FACTOR ].min
    end
  end
end
