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

  test "filter_by narrows by status" do
    assert_equal [ cryptics(:inactive) ], Cryptic.filter_by(status: "inactive").to_a
    assert_equal [ cryptics(:easy) ], Cryptic.filter_by(difficulty: "facil", status: "active").to_a
    assert_equal Cryptic.count, Cryptic.filter_by(status: "x").count
  end

  test "filter_by narrows by source and sources lists each origin once" do
    cryptics(:medium).update_columns(source: "propia")

    assert_equal [ cryptics(:medium) ], Cryptic.filter_by(source: "propia").to_a
    assert_equal Cryptic.count, Cryptic.filter_by(source: "").count
    assert_equal %w[propia test], Cryptic.sources
  end

  test "an admin change of activation stops the sync from reactivating it" do
    cryptic = cryptics(:inactive)
    cryptic.update_columns(deactivated_by_sync: true)

    cryptic.change_activation!(true)
    assert_predicate cryptic.reload, :active?
    assert_not cryptic.deactivated_by_sync?

    cryptic.change_activation!(false)
    assert_not cryptic.reload.active?
    assert_not cryptic.deactivated_by_sync?
  end

  test "play stats count started games, solved share and average solve time" do
    cryptic = cryptics(:easy)
    started = Time.zone.parse("2026-11-20 10:00:00")
    insert_game(cryptic, started_at: started, solved_at: started + 40.seconds)
    insert_game(cryptic, started_at: started, solved_at: started + 80.seconds)
    insert_game(cryptic, started_at: started)
    insert_game(cryptic) # asignado pero sin arrancar: no cuenta como jugado

    stats = cryptic.play_stats

    assert_equal 3, stats.played_count
    assert_equal 2, stats.solved_count
    assert_equal 67, stats.solved_percentage
    assert_equal 60, stats.average_solve_seconds
  end

  test "play stats are empty for a cryptic nobody played" do
    stats = cryptics(:medium).play_stats

    assert_not stats.played?
    assert_equal 0, stats.solved_percentage
    assert_nil stats.average_solve_seconds
  end

  private

  # Las partidas resueltas todavía no se pueden crear desde el modelo: se insertan directo.
  def insert_game(cryptic, started_at: nil, solved_at: nil)
    player = Player.create!(name: "Jugador #{Player.count + 1}")
    status = started_at ? "IN_PROGRESS" : "PREPARED"
    Game.insert!({ player_id: player.id, cryptic_id: cryptic.id, status: status,
                   started_at: started_at, solved_at: solved_at })
  end
end
