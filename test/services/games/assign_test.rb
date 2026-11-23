require "test_helper"

class Games::AssignTest < ActiveSupport::TestCase
  setup do
    @player = Player.create!(name: "Jugador")
  end

  test "assigns only active cryptics of the requested difficulty without starting" do
    result = assign("facil")
    assert_predicate result, :success?
    assert_nil result.error
    game = result.value
    assert_equal cryptics(:easy), game.cryptic
    assert_equal @player, game.player
    assert_predicate game, :prepared?
    assert_nil game.started_at
    other = Player.create!(name: "Otra persona")
    assert_equal cryptics(:medium), Games::Assign.new(player: other, difficulty: "medio").call.value.cryptic
  end

  test "repeated requests reuse the pending game even for another difficulty or exhausted catalog" do
    game = assign("facil").value
    assert_no_difference "Game.count" do
      assert_equal game, assign("medio").value
      assert_equal game, assign("avanzado").value
      game.start!
      assert_equal game, assign("facil").value
    end
  end

  test "invalid difficulty and missing cryptics return errors without creating a game" do
    assert_no_difference "Game.count" do
      [ nil, "", "hard", [ "facil" ] ].each do |difficulty|
        result = assign(difficulty)
        assert_not result.success?
        assert_nil result.value
        assert_equal "Elegí una dificultad válida.", result.error
      end
      result = assign("avanzado")
      assert_not result.success?
      assert_nil result.value
      assert_equal "Críptico debe existir", result.error
      cryptics(:easy).update!(active: false)
      result = assign("facil")
      assert_not result.success?
      assert_nil result.value
      assert_equal "Críptico debe existir", result.error
    end
  end

  test "deactivation does not strand an assignment or reset its start" do
    game = assign("facil").value
    game.cryptic.update!(active: false)
    assert_equal game, assign("facil").value
    game.start!
    assert_predicate game, :in_progress?
    assert_equal game, assign("medio").value
  end

  test "validation failures return an error without persisting a game" do
    invalid_game = @player.games.build(cryptic: cryptics(:easy), status: "INVALID")
    games = @player.games
    games.define_singleton_method(:build) { |**| invalid_game }

    assert_no_difference "Game.count" do
      result = assign("facil")
      assert_not result.success?
      assert_nil result.value
      assert_equal invalid_game.errors.full_messages.to_sentence, result.error
      assert_predicate invalid_game.errors, :any?
    end
  end

  private

  def assign(difficulty)
    Games::Assign.new(player: @player, difficulty: difficulty).call
  end
end
