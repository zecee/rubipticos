module Admin
  # Formato común para mostrar datos en el backend: números con separador de miles,
  # porcentajes y valores vacíos siempre iguales en todas las secciones.
  module DisplayHelper
    EMPTY_VALUE = "—".freeze

    # 12345 → "12.345"; 1234.567 con precision: 1 → "1.234,6". Sin dato → "—".
    def admin_number(value, precision: 0)
      return EMPTY_VALUE if value.nil?

      number_with_precision(value, precision: precision, delimiter: t("number.format.delimiter"),
                                   strip_insignificant_zeros: precision.positive?)
    end

    # admin_percentage(3, 8) → "38 %". Con total cero no hay porcentaje que mostrar.
    def admin_percentage(part, total, precision: 0)
      return EMPTY_VALUE if total.to_i.zero?

      number_to_percentage(part * 100.0 / total, precision: precision,
                                                 strip_insignificant_zeros: precision.positive?)
    end

    # Texto, lista o nada: las listas se unen ("a, b y c") y lo vacío se muestra como "—".
    def admin_value(value)
      text = value.is_a?(Array) ? value.compact_blank.to_sentence : value
      text.presence || EMPTY_VALUE
    end
  end
end
