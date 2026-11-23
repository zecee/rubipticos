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
end
