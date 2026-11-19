require "json"

catalog = JSON.parse(Rails.root.join("db/seeds/cryptics.json").read)

Cryptic.transaction do
  catalog.fetch("cripticos").each do |entry|
    cryptic = Cryptic.find_or_initialize_by(external_id: entry.fetch("id"))
    cryptic.assign_attributes(
      clue: entry.fetch("enunciado"),
      source_enumeration: entry.fetch("enumeracion"),
      answer: entry.fetch("respuesta"),
      definitions: entry.fetch("definiciones"),
      indicators: entry.fetch("indicadores"),
      material: entry.fetch("material"),
      puzzle_type: entry.fetch("tipo"),
      difficulty: entry.fetch("dificultad"),
      hint: entry.fetch("ayuda"),
      explanation: entry.fetch("explicacion"),
      author: entry.fetch("autor"),
      source: catalog.fetch("fuente")
    )
    cryptic.save!
  end
end
