module Admin
  module CrypticsHelper
    # 75 -> "1 min 15 s"; 42 -> "42 s".
    def solve_time(seconds)
      return "—" if seconds.nil?

      minutes, rest = seconds.divmod(60)
      minutes.zero? ? "#{rest} s" : "#{minutes} min #{rest.to_s.rjust(2, "0")} s"
    end

    def cryptic_filter_options(labels, selected)
      options_for_select(labels.map { |value, label| [ label, value ] }, selected)
    end
  end
end
