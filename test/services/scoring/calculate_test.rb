require "test_helper"

module Scoring
  class CalculateTest < ActiveSupport::TestCase
    def points(cryptic: cryptics(:medium), elapsed_seconds: 0, hints_used: 0, streak_days: 1)
      Calculate.new(cryptic:, elapsed_seconds:, hints_used:, streak_days:).call
    end

    test "matches the example of the statement" do
      assert_equal 144, points(elapsed_seconds: 240, hints_used: 1, streak_days: 4)
      assert_equal 240, points(elapsed_seconds: 120, streak_days: 4)
    end

    test "base uses the type points and the difficulty multiplier" do
      puzzle_type_scores(:oculta).update!(points: 250)
      difficulty_multipliers(:medio).update!(multiplier: 1.5)

      assert_equal 394, points(streak_days: 1) # 250 × 1.5 × 1.05 = 393.75
    end

    test "time factor never goes below 0.25" do
      assert_equal 53, points(elapsed_seconds: 10_000, streak_days: 1) # 200 × 0.25 × 1.05 = 52.5
    end

    test "each hint takes 0.2 off" do
      assert_equal 42, points(hints_used: 4, streak_days: 1) # 200 × 0.2 × 1.05
    end

    test "streak factor caps at 1.5 from day 10" do
      assert_equal 300, points(streak_days: 10)
      assert_equal 300, points(streak_days: 40)
    end

    test "a solved cryptic gives at least 10 points" do
      puzzle_type_scores(:anagrama).update!(points: 10)

      assert_equal 10, points(cryptic: cryptics(:easy), elapsed_seconds: 10_000, hints_used: 4)
    end

    test "rejects impossible inputs" do
      assert_raises(ArgumentError) { points(hints_used: 5) }
      assert_raises(ArgumentError) { points(streak_days: -1) }
      assert_raises(ArgumentError) { points(elapsed_seconds: -1) }
    end
  end
end
