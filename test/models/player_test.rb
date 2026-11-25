require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  test "pending game returns the players prepared or in-progress game" do
    player = Player.create!(name: "Jugador")
    other = Player.create!(name: "Otro jugador")
    other.games.create!(cryptic: cryptics(:easy))
    assert_nil player.pending_game

    game = player.games.create!(cryptic: cryptics(:easy))
    assert_equal game, player.pending_game
    game.start!
    assert_equal game, player.pending_game
  end

  test "trims exterior whitespace without restricting characters or interior spaces" do
    player = Player.create!(name: " \tÁna María-猫!\u00a0")

    assert_equal "Ána María-猫!", player.name
    assert_equal "ána maría-猫!", player.name_key
  end

  test "requires a name between three and twenty characters after trimming" do
    [ nil, "   ", " ab ", "a" * 21 ].each do |name|
      player = Player.new(name: name)
      assert_not player.valid?, "Expected #{name.inspect} to be invalid"
      assert player.errors[:name].any?
    end

    [ "abc", "á" * 20 ].each do |name|
      assert Player.new(name: name).valid?
    end
  end

  test "names are unique regardless of case including accented letters" do
    Player.create!(name: "ÁLVARO")
    player = Player.new(name: " álvaro ")

    assert_not player.valid?
    assert player.errors.of_kind?(:name_key, :taken)
  end

  test "suggestion is available and fits the limit even with existing suffixes" do
    name = "Á" * 20
    Player.create!(name: name)
    Player.create!(name: "#{'á' * 18}_2")
    player = Player.new(name: name.downcase)
    player.valid?

    assert_equal "#{'á' * 18}_3", player.name_suggestion
    assert Player.new(name: player.name_suggestion).valid?
    assert_equal name.downcase, player.name
  end

  test "only a digest is stored and raw tokens authenticate after reload" do
    player = Player.create!(name: "Pedrito")
    token = player.identity_token

    assert_match(/\A[A-Za-z0-9_-]{43}\z/, token)
    assert_equal Digest::SHA256.hexdigest(token), player.token_digest
    assert_equal player, Player.from_identity_token(token)
    assert_nil Player.find(player.id).identity_token
    assert_nil Player.from_identity_token("not-a-token")
    assert_nil Player.from_identity_token(SecureRandom.urlsafe_base64(32))
    assert_nil Player.from_identity_token(nil)
  end

  test "renaming preserves the player and token" do
    player = Player.create!(name: "Pedrito")
    token = player.identity_token
    id = player.id

    player.update!(name: "Pedro")

    assert_equal id, Player.from_identity_token(token).id
    assert_equal "Pedro", player.reload.name
  end

  test "database rejects duplicate normalized names even without validation" do
    Player.create!(name: "Pedrito")
    duplicate = Player.new(name: "PEDRITO")
    duplicate.valid?

    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
  end

  test "rejects missing or invalid token digests through model validation" do
    player = Player.create!(name: "Pedrito")

    [ nil, "", "short", "a" * 65 ].each do |digest|
      assert_not player.update(token_digest: digest)
      assert player.errors[:token_digest].any?
    end
  end

  test "database rejects duplicate token digests" do
    player = Player.create!(name: "Pedrito")
    other = Player.create!(name: "María")

    assert_raises(ActiveRecord::RecordNotUnique) { other.update_columns(token_digest: player.token_digest) }
  end

  test "creation collision after validation becomes a friendly name error" do
    player = Player.new(name: "PEDRITO")
    assert player.valid?
    Player.create!(name: "Pedrito")
    # Simulate validation having completed before the competing write.
    player.define_singleton_method(:valid?) { |*| true }

    assert_no_difference "Player.count" do
      assert_not player.save_with_name_conflict
    end
    assert player.errors.of_kind?(:name_key, :taken)
    assert_equal "PEDRITO_2", player.name_suggestion
  end

  test "rename collision after validation leaves the original name and identity intact" do
    player = Player.create!(name: "María")
    token = player.identity_token
    player.name = "PEDRITO"
    assert player.valid?
    Player.create!(name: "Pedrito")
    player.define_singleton_method(:valid?) { |*| true }

    assert_not player.save_with_name_conflict
    assert player.errors.of_kind?(:name_key, :taken)
    assert_equal "María", player.reload.name
    assert_equal player, Player.from_identity_token(token)
  end

  test "block hides the player from the unblocked scope until unblocked" do
    player = Player.create!(name: "Ofensivo")

    player.block!

    assert player.blocked?
    assert_includes Player.blocked, player
    assert_not_includes Player.unblocked, player

    player.unblock!

    assert_not player.blocked?
    assert_includes Player.unblocked, player
  end

  test "blocking twice keeps the original block time" do
    player = Player.create!(name: "Ofensivo")
    player.block!
    blocked_at = player.blocked_at

    travel 1.hour do
      player.block!
    end

    assert_equal blocked_at, player.reload.blocked_at
  end

  test "current streak counts consecutive solved days ending today" do
    player = player_with_solved_days(0, 1, 2, 4)

    assert_equal 3, player.current_streak(today: today)
  end

  test "current streak stays alive when the last solve was yesterday" do
    player = player_with_solved_days(1, 2)

    assert_equal 2, player.current_streak(today: today)
  end

  test "current streak is lost after a day without solving" do
    player = player_with_solved_days(2, 3)

    assert_equal 0, player.current_streak(today: today)
  end

  test "several solves on the same day count once" do
    player = player_with_solved_days(0, 0, 1)

    assert_equal 2, player.current_streak(today: today)
  end

  test "unsolved games do not count for the streak" do
    player = Player.create!(name: "Jugador")
    player.games.create!(cryptic: cryptics(:easy)).start!

    assert_equal 0, player.current_streak(today: today)
  end

  private

  def today
    Date.new(2026, 11, 25)
  end

  # Resolver partidas todavía no existe: se marca solved_at directo en la base.
  def player_with_solved_days(*days_ago)
    player = Player.create!(name: "Racha")
    days_ago.each_with_index do |days, index|
      cryptic = cryptics(:easy).dup.tap { |copy| copy.update!(external_id: "streak-#{index}") }
      game = player.games.create!(cryptic: cryptic)
      game.update_columns(status: "SOLVED", solved_at: (today - days).in_time_zone.change(hour: 12))
    end
    player
  end
end
