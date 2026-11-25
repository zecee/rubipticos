module Admin
  module CrypticsHelper
    PUZZLE_TYPE_LABELS = {
      "anagrama" => "Anagrama", "oculta" => "Oculta", "charada" => "Charada",
      "contenedor" => "Contenedor", "inversion" => "Inversión", "supresion" => "Supresión",
      "homofono" => "Homófono", "doble_definicion" => "Doble definición", "iniciales" => "Iniciales",
      "finales" => "Finales", "sustitucion" => "Sustitución", "simbolos" => "Símbolos",
      "combinada" => "Combinada"
    }.freeze
    DIFFICULTY_LABELS = { "facil" => "Fácil", "medio" => "Medio", "avanzado" => "Avanzado" }.freeze

    def puzzle_type_label(cryptic)
      PUZZLE_TYPE_LABELS.fetch(cryptic.puzzle_type, cryptic.puzzle_type)
    end

    def difficulty_label(cryptic)
      DIFFICULTY_LABELS.fetch(cryptic.difficulty, cryptic.difficulty)
    end
  end
end
