module Games
  class Assign < BaseService
    def initialize(player:, difficulty:)
      @player = player
      @difficulty = difficulty
    end

    def call
      return failure("Elegí una dificultad válida.") if invalid_difficulty?

      game = Game.transaction do
        @player.pending_game || assign_game
      end

      if game
        success(game)
      else
        failure(@assignment_error)
      end
    end

    private

    def invalid_difficulty?
      !Cryptic::DIFFICULTIES.include?(@difficulty)
    end

    def assign_game
      cryptic = Cryptic.random_available_for(player: @player, difficulty: @difficulty)
      game = @player.games.build(cryptic: cryptic)
      if game.save
        game
      else
        @assignment_error = game.errors.full_messages.to_sentence
        nil
      end
    end
  end
end
