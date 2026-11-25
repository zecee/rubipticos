require "test_helper"

class CrypticTest < ActiveSupport::TestCase
  test "available selection filters difficulty activity and the players assigned cryptics" do
    player = Player.create!(name: "Jugador")
    other = Player.create!(name: "Otro jugador")
    other.games.create!(cryptic: cryptics(:easy))

    assert_equal cryptics(:easy), Cryptic.random_available_for(player: player, difficulty: "facil")
    assert_equal cryptics(:medium), Cryptic.random_available_for(player: player, difficulty: "medio")
    assert_nil Cryptic.random_available_for(player: player, difficulty: "avanzado")

    player.games.create!(cryptic: cryptics(:easy))
    assert_nil Cryptic.random_available_for(player: player, difficulty: "facil")

    cryptics(:medium).update!(active: false)
    assert_nil Cryptic.random_available_for(player: player, difficulty: "medio")
  end

  test "every puzzle type and difficulty has a Spanish label" do
    assert_equal Cryptic::PUZZLE_TYPES.sort, Cryptic::PUZZLE_TYPE_LABELS.keys.sort
    assert_equal Cryptic::DIFFICULTIES.sort, Cryptic::DIFFICULTY_LABELS.keys.sort
  end

  test "labels follow the puzzle type and difficulty" do
    cryptic = Cryptic.new(puzzle_type: "doble_definicion", difficulty: "facil")

    assert_equal "Doble definición", cryptic.puzzle_type_label
    assert_equal "Fácil", cryptic.difficulty_label
  end

  test "filter_by narrows by difficulty and ignores blank or unknown values" do
    assert_equal [ cryptics(:easy), cryptics(:inactive) ].sort, Cryptic.filter_by(difficulty: "facil").sort
    assert_equal Cryptic.count, Cryptic.filter_by(difficulty: "").count
    assert_equal Cryptic.count, Cryptic.filter_by(difficulty: "imposible").count
  end

  test "filter_by narrows by puzzle type and combines filters" do
    assert_equal [ cryptics(:medium) ], Cryptic.filter_by(puzzle_type: "oculta").to_a
    assert_empty Cryptic.filter_by(puzzle_type: "oculta", difficulty: "facil")
    assert_equal Cryptic.count, Cryptic.filter_by(puzzle_type: "otro").count
  end
end
