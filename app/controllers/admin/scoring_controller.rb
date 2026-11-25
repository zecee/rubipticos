module Admin
  class ScoringController < BaseController
    allow_score_editors

    def show
      @type_scores = PuzzleTypeScore.for_all_types
      @multipliers = DifficultyMultiplier.for_all_difficulties
    end

    def update
      update_rules = Scoring::UpdateRules.new(**scoring_params.to_h.symbolize_keys)
      update_rules.call
      redirect_to admin_scoring_path, status: :see_other, notice: "Puntajes guardados."
    rescue ActiveRecord::RecordInvalid
      @type_scores = update_rules.type_scores
      @multipliers = update_rules.multipliers
      render :show, status: :unprocessable_entity
    end

    private

    def scoring_params
      params.expect(scoring: [ points: Cryptic::PUZZLE_TYPES, multipliers: Cryptic::DIFFICULTIES ])
    end
  end
end
