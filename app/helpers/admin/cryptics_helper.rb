module Admin
  module CrypticsHelper
    # Roles de las partes de un críptico, en el orden en que se resaltan.
    PART_ROLES = {
      definition: { field: :definitions, label: "Definición" },
      indicator: { field: :indicators, label: "Indicador" },
      material: { field: :material, label: "Material" }
    }.freeze

    # 42 -> "42 s"; 75 -> "1 min 15 s"; 3725 -> "1 h 02 min".
    def solve_time(seconds)
      return "—" if seconds.nil?

      hours, rest = seconds.divmod(3600)
      minutes, seconds = rest.divmod(60)
      return "#{hours} h #{minutes.to_s.rjust(2, "0")} min" if hours.positive?
      return "#{minutes} min #{seconds.to_s.rjust(2, "0")} s" if minutes.positive?

      "#{seconds} s"
    end

    def cryptic_filter_options(labels, selected)
      options_for_select(labels.map { |value, label| [ label, value ] }, selected)
    end

    # El enunciado con cada definición, indicador y material envuelto en un <mark> de su color.
    def highlighted_clue(cryptic)
      clue = cryptic.clue.to_s
      roles = Array.new(clue.length)

      PART_ROLES.each do |role, config|
        Array(cryptic.public_send(config[:field])).each do |part|
          range = part_range(clue, part.to_s, roles)
          range&.each { |i| roles[i] = role }
        end
      end

      segments = clue.each_char.with_index.chunk_while { |(_, a), (_, b)| roles[a] == roles[b] }
      safe_join(segments.map do |chars|
        text = chars.map(&:first).join
        role = roles[chars.first.last]
        role ? clue_mark(text, role) : text
      end)
    end

    def part_label(role)
      PART_ROLES.fetch(role)[:label]
    end

    # Las letras de la respuesta, una por casilla; los espacios separan palabras.
    def answer_words(cryptic)
      cryptic.answer.to_s.upcase.split(/\s+/).map(&:chars)
    end

    private

    # Primera aparición libre como palabra completa; si no hay, cualquier aparición libre.
    def part_range(clue, part, roles)
      return if part.empty?

      whole_word = /(?<!\p{L})#{Regexp.escape(part)}(?!\p{L})/
      [ whole_word, /#{Regexp.escape(part)}/ ].each do |pattern|
        clue.to_enum(:scan, pattern).each do
          start = Regexp.last_match.begin(0)
          range = start...(start + part.length)
          return range if range.none? { |i| roles[i] }
        end
      end
      nil
    end

    def clue_mark(text, role)
      tag.mark(class: "admin-part admin-part--#{role}") do
        safe_join([ text, tag.span(" (#{part_label(role).downcase})", class: "visually-hidden") ])
      end
    end
  end
end
