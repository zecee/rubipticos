require "test_helper"

module Admin
  class ScoringControllerTest < ActionDispatch::IntegrationTest
    def valid_params
      {
        scoring: {
          points: Cryptic::PUZZLE_TYPES.index_with { "100" }.merge("anagrama" => "150"),
          multipliers: { "facil" => "1", "medio" => "2.5", "avanzado" => "3" }
        }
      }
    end

    test "shows every type and difficulty" do
      sign_in_as users(:two)

      get admin_scoring_path

      assert_response :success
      assert_select "input[name^='scoring[points]']", count: Cryptic::PUZZLE_TYPES.size
      assert_select "input[name^='scoring[multipliers]']", count: Cryptic::DIFFICULTIES.size
    end

    test "score editor saves the rules" do
      sign_in_as users(:two)

      patch admin_scoring_path, params: valid_params

      assert_redirected_to admin_scoring_path
      assert_equal 150, puzzle_type_scores(:anagrama).reload.points
      assert_equal BigDecimal("2.5"), difficulty_multipliers(:medio).reload.multiplier
    end

    test "invalid values save nothing and show the errors" do
      sign_in_as users(:one)
      params = valid_params
      params[:scoring][:multipliers]["avanzado"] = "6"

      patch admin_scoring_path, params: params

      assert_response :unprocessable_entity
      assert_select ".admin-flash--alert li", text: /Avanzado/
      assert_equal 100, puzzle_type_scores(:anagrama).reload.points
    end

    test "creates rules that were missing" do
      sign_in_as users(:one)
      DifficultyMultiplier.delete_all

      patch admin_scoring_path, params: valid_params

      assert_equal Cryptic::DIFFICULTIES.size, DifficultyMultiplier.count
    end

    test "requires a session to update" do
      patch admin_scoring_path, params: valid_params

      assert_redirected_to new_session_path
    end
  end
end
