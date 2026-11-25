require "test_helper"

class DifficultyMultiplierTest < ActiveSupport::TestCase
  test "multiplier must be greater than 0 and at most 5" do
    rule = difficulty_multipliers(:medio)

    [ 0.01, 1.5, 5 ].each do |multiplier|
      rule.multiplier = multiplier
      assert rule.valid?, "#{multiplier} should be valid"
    end

    [ 0, -1, 5.01, nil ].each do |multiplier|
      rule.multiplier = multiplier
      assert_not rule.valid?, "#{multiplier.inspect} should be invalid"
    end
  end

  test "difficulty must be a known and unique difficulty" do
    assert_not DifficultyMultiplier.new(difficulty: "imposible", multiplier: 1).valid?
    assert_not DifficultyMultiplier.new(difficulty: "facil", multiplier: 1).valid?
  end

  test "database rejects multipliers outside the range" do
    assert_raises(ActiveRecord::StatementInvalid) do
      difficulty_multipliers(:facil).update_column(:multiplier, 0)
    end
  end

  test "for_all_difficulties fills missing ones with the defaults" do
    difficulty_multipliers(:avanzado).destroy!

    rules = DifficultyMultiplier.for_all_difficulties

    assert_equal Cryptic::DIFFICULTIES, rules.map(&:difficulty)
    assert_equal 3, rules.last.multiplier
    assert rules.last.new_record?
  end
end
