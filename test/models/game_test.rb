require "test_helper"

class GameTest < ActiveSupport::TestCase
  setup do
    @player = Player.create!(name: "Jugador")
    @game = @player.games.create!(cryptic: cryptics(:easy))
  end

  test "prepared games have no start time and starting stale copies preserves the first timestamp" do
    assert_predicate @game, :prepared?
    assert_equal "PREPARED", @game.reload.status
    assert_nil @game.started_at
    assert_nil @game.solved_at
    assert_equal 0, @game.elapsed_seconds
    stale_copy = Game.find(@game.id)

    freeze_time do
      @game.start!
      assert_predicate @game, :in_progress?
      assert_equal "IN_PROGRESS", @game.reload.status
      assert_equal Time.current, @game.started_at
      assert_nil @game.solved_at
      travel 2.hours
      stale_copy.start!
      assert_equal @game.started_at, stale_copy.started_at
      assert_equal 7200, stale_copy.elapsed_seconds
    end
  end

  test "model requires valid state and a timestamp only for in-progress games" do
    assert_not @game.update(started_at: Time.current)
    assert @game.errors[:started_at].any?
    @game.reload
    assert_not @game.update(status: "IN_PROGRESS")
    assert @game.errors[:started_at].any?
    @game.reload
    assert_not @game.update(status: "invented")
    assert @game.errors[:status].any?
  end

  test "status values must be uppercase" do
    %w[prepared in_progress Prepared In_Progress].each do |status|
      @game.status = status
      assert_not @game.valid?
      assert @game.errors[:status].any?
    end
    assert_equal "PREPARED", @game.reload.status
  end

  test "prepared and in-progress games cannot have a resolution timestamp" do
    assert_not @game.update(solved_at: Time.current)
    assert @game.errors[:solved_at].any?
    assert_nil @game.reload.solved_at

    @game.start!
    assert_not @game.update(solved_at: Time.current)
    assert @game.errors[:solved_at].any?
    assert_nil @game.reload.solved_at
  end

  test "database rejects two pending games even when validations are bypassed" do
    duplicate = @player.games.new(cryptic: cryptics(:medium))
    assert_not duplicate.valid?
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
    assert_equal 1, @player.games.count
  end

  test "database has independent unique indexes for pending players and played pairs" do
    indexes = Game.connection.indexes(:games)
    pair = indexes.find { |index| index.columns == %w[player_id cryptic_id] }
    assert pair.unique
    assert_nil pair.where
    pending = indexes.find { |index| index.name == "index_games_on_pending_player" }
    assert pending.unique
    assert_equal [ "player_id" ], pending.columns
    assert_match(/PREPARED.*IN_PROGRESS/, pending.where)

    duplicate = @player.games.new(cryptic: @game.cryptic)
    assert_not duplicate.valid?
    assert duplicate.errors[:cryptic_id].any?
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
  end

  test "database keeps required columns but leaves state and timestamp checks to the model" do
    assert_empty Game.connection.check_constraints(:games)
    [ { status: nil }, { player_id: nil }, { cryptic_id: nil } ].each do |attributes|
      assert_raises(ActiveRecord::StatementInvalid) { @game.update_columns(attributes) }
      @game.reload
    end
  end

  test "associations and foreign keys prevent deleting players or cryptics with games" do
    [ @player, @game.cryptic ].each do |record|
      assert_raises(ActiveRecord::DeleteRestrictionError) { record.destroy! }
      assert_raises(ActiveRecord::InvalidForeignKey) { record.delete }
      assert record.class.exists?(record.id)
    end
    assert_raises(ActiveRecord::InvalidForeignKey) { @game.update_columns(player_id: -1) }
    assert_raises(ActiveRecord::InvalidForeignKey) { @game.update_columns(cryptic_id: -1) }
  end
end
