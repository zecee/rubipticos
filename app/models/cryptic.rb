class Cryptic < ApplicationRecord
  has_many :games, dependent: :restrict_with_exception

  PUZZLE_TYPES = %w[
    anagrama oculta charada contenedor inversion supresion homofono
    doble_definicion iniciales finales sustitucion simbolos combinada
  ].freeze
  DIFFICULTIES = %w[facil medio avanzado].freeze
  PUZZLE_TYPE_LABELS = {
    "anagrama" => "Anagrama", "oculta" => "Oculta", "charada" => "Charada",
    "contenedor" => "Contenedor", "inversion" => "Inversión", "supresion" => "Supresión",
    "homofono" => "Homófono", "doble_definicion" => "Doble definición", "iniciales" => "Iniciales",
    "finales" => "Finales", "sustitucion" => "Sustitución", "simbolos" => "Símbolos",
    "combinada" => "Combinada"
  }.freeze
  DIFFICULTY_LABELS = { "facil" => "Fácil", "medio" => "Medio", "avanzado" => "Avanzado" }.freeze
  MATERIAL_RULE_TYPES = %w[oculta anagrama iniciales finales].freeze
  CONNECTORS = %w[y e o u de del la el los las un una].freeze
  STATUSES = %w[active inactive].freeze
  STATUS_LABELS = { "active" => "Activo", "inactive" => "Inactivo" }.freeze

  attr_accessor :source_enumeration

  scope :active, -> { where(active: true) }
  scope :with_difficulty, ->(difficulty) { where(difficulty: difficulty) }
  scope :not_played_by, ->(player) { where.not(id: player.games.select(:cryptic_id)) }

  # Filtros del listado del backend. Un valor vacío o desconocido no filtra.
  def self.filter_by(difficulty: nil, puzzle_type: nil, status: nil, source: nil)
    scope = all
    scope = scope.where(difficulty: difficulty) if DIFFICULTIES.include?(difficulty)
    scope = scope.where(puzzle_type: puzzle_type) if PUZZLE_TYPES.include?(puzzle_type)
    scope = scope.where(active: status == "active") if STATUSES.include?(status)
    scope = scope.where(source: source) if source.present?
    scope
  end

  def self.sources
    distinct.order(:source).pluck(:source)
  end

  validates :external_id, :clue, :answer, :source, presence: true
  validates :external_id, uniqueness: true
  validates :puzzle_type, inclusion: { in: PUZZLE_TYPES }
  validates :difficulty, inclusion: { in: DIFFICULTIES }
  validate :source_enumeration_matches_answer, unless: -> { source_enumeration.nil? }
  validate :parts_appear_in_clue
  validate :double_definition_has_two_definitions
  validate :answer_follows_type_rule

  def self.random_available_for(player:, difficulty:)
    active.with_difficulty(difficulty).not_played_by(player)
      .order(Arel.sql("RANDOM()")).first
  end

  # Solo letras en minúscula: sin tildes, espacios ni signos. La Ñ se distingue de la N.
  def self.letters(text)
    text.to_s.downcase
        .tr("ñ", "\u0001")
        .unicode_normalize(:nfd)
        .gsub(/\p{Mn}/, "")
        .tr("\u0001", "ñ")
        .gsub(/[^\p{L}]/, "")
  end

  def puzzle_type_label
    PUZZLE_TYPE_LABELS.fetch(puzzle_type)
  end

  def difficulty_label
    DIFFICULTY_LABELS.fetch(difficulty)
  end

  def enumeration
    return if answer.blank?

    "(#{self.class.letters(answer).length})"
  end

  private

  def source_enumeration_matches_answer
    return if answer.blank?

    if source_enumeration != enumeration
      errors.add(:source_enumeration, "no coincide con el largo de la respuesta")
    end
  end

  def parts_appear_in_clue
    { definitions: definitions, indicators: indicators, material: material }.each do |field, parts|
      Array(parts).each do |part|
        errors.add(field, "\"#{part}\" no aparece en el enunciado") unless clue.to_s.include?(part.to_s)
      end
    end
  end

  def double_definition_has_two_definitions
    return unless puzzle_type == "doble_definicion"

    errors.add(:definitions, "debe tener exactamente 2 elementos") unless Array(definitions).size == 2
  end

  def answer_follows_type_rule
    return unless MATERIAL_RULE_TYPES.include?(puzzle_type) && answer.present?

    if Array(material).empty?
      errors.add(:material, "no puede estar vacío para el tipo #{puzzle_type}")
      return
    end

    unless satisfies_type_rule?(self.class.letters(answer))
      errors.add(:answer, "no cumple la regla del tipo #{puzzle_type}")
    end
  end

  def satisfies_type_rule?(target)
    case puzzle_type
    when "oculta"    then Array(material).any? { |m| self.class.letters(m).include?(target) }
    when "anagrama"  then self.class.letters(Array(material).join).chars.sort == target.chars.sort
    when "iniciales" then edge_letters { |word| word[0] } == target
    when "finales"   then edge_letters { |word| word[-1] } == target
    end
  end

  # Sin el chequeo contra el array de conectores tomaba dichos conectores y rechazaba erroneamente algunos enunciados
  def edge_letters(&edge)
    Array(material).flat_map(&:split)
                  .map { |w| self.class.letters(w) }
                  .reject { |w| w.empty? || CONNECTORS.include?(w) }
                  .map { |w| edge.call(w) }
                  .join
  end
end
