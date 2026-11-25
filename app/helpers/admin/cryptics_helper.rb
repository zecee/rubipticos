module Admin
  module CrypticsHelper
    def cryptic_filter_options(labels, selected)
      options_for_select(labels.map { |value, label| [ label, value ] }, selected)
    end
  end
end
