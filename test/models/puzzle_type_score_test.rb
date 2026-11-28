require "test_helper"

class PuzzleTypeScoreTest < ActiveSupport::TestCase
  test "points must be an integer between 10 and 1000" do
    score = puzzle_type_scores(:anagrama)

    [ 10, 1000 ].each do |points|
      score.points = points
      assert score.valid?, "#{points} should be valid"
    end

    [ 9, 1001, 50.5, nil ].each do |points|
      score.points = points
      assert_not score.valid?, "#{points.inspect} should be invalid"
    end
  end

  test "puzzle type must be a known and unique type" do
    assert_not PuzzleTypeScore.new(puzzle_type: "acrostico", points: 100).valid?
    assert_not PuzzleTypeScore.new(puzzle_type: "anagrama", points: 100).valid?
  end

  test "database rejects points outside the range" do
    assert_raises(ActiveRecord::StatementInvalid) do
      puzzle_type_scores(:anagrama).update_column(:points, 5)
    end
  end

  test "for_all_types lists every type and fills missing ones with the default" do
    puzzle_type_scores(:oculta).destroy!

    scores = PuzzleTypeScore.for_all_types

    assert_equal Cryptic::PUZZLE_TYPES, scores.map(&:puzzle_type)
    missing = scores.find { |score| score.puzzle_type == "oculta" }
    assert missing.new_record?
    assert_equal PuzzleTypeScore::DEFAULT_POINTS, missing.points
  end
end
