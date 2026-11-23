require "net/http"

module Cryptics
  class Sync
    class Error < StandardError; end
    class FetchError < Error; end
    class InvalidPayloadError < Error; end

    REQUEST_TIMEOUT = 10 # segundos
    DEFAULT_SOURCE_NAME = "Fuente desconocida"

    def initialize(source_url:, user: nil)
      @source_url = source_url.to_s
      @user = user
    end

    def call
      payload = fetch_payload
      version = payload["version"]

      return record_unchanged(version) if already_synced?(version)

      import(payload, version)
    rescue Error => e
      SyncRun.create!(user: @user, source_url: @source_url, status: "failed", error_message: e.message)
      raise
    end

    private

    def fetch_payload
      uri = URI.parse(@source_url)
      raise FetchError, "la URL de la fuente no es válida" unless uri.is_a?(URI::HTTP) && uri.host.present?

      response = Net::HTTP.start(
        uri.host, uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: REQUEST_TIMEOUT,
        read_timeout: REQUEST_TIMEOUT
      ) { |http| http.request(Net::HTTP::Get.new(uri)) }

      raise FetchError, "respuesta inesperada de la fuente (HTTP #{response.code})" unless response.is_a?(Net::HTTPSuccess)

      payload = JSON.parse(response.body)
      validate_payload!(payload)
      payload
    rescue URI::InvalidURIError
      raise FetchError, "la URL de la fuente no es válida"
    rescue Timeout::Error, SocketError, SystemCallError, IOError, OpenSSL::SSL::SSLError, Net::ProtocolError => e
      raise FetchError, "no se pudo obtener el catálogo (#{e.class})"
    rescue JSON::ParserError
      raise InvalidPayloadError, "el catálogo no es un JSON válido"
    end

    def validate_payload!(payload)
      valid = payload.is_a?(Hash) && payload["version"].present? && payload["cripticos"].is_a?(Array)
      raise InvalidPayloadError, "el catálogo tiene una estructura inesperada" unless valid
      raise InvalidPayloadError, "el catálogo no contiene crípticos" if payload["cripticos"].empty?
    end

    # Compara contra la última sincronización exitosa, sin importar la URL:
    # el estado de la base refleja la última fuente que se importó.
    def already_synced?(version)
      SyncRun.completed.order(:id).last&.version == version
    end

    def record_unchanged(version)
      SyncRun.create!(user: @user, source_url: @source_url, status: "unchanged", version: version)
    end

    def import(payload, version)
      created = updated = 0
      rejections = []
      seen_ids = []
      source_name = payload["fuente"].presence || DEFAULT_SOURCE_NAME

      ActiveRecord::Base.transaction do
        payload["cripticos"].each do |entry|
          entry_id = entry["id"].to_s if entry.is_a?(Hash) && entry["id"].present?

          if entry_id && seen_ids.include?(entry_id)
            rejections << { "id" => entry_id, "reason" => "el id está repetido en la fuente" }
            next
          end
          seen_ids << entry_id if entry_id

          outcome, reason = import_entry(entry, source_name)
          case outcome
          when :created then created += 1
          when :updated then updated += 1
          when :rejected then rejections << { "id" => (entry["id"] if entry.is_a?(Hash)), "reason" => reason }
          end
        end

        SyncRun.create!(
          user: @user, source_url: @source_url, status: "completed", version: version,
          created_count: created, updated_count: updated,
          deactivated_count: deactivate_missing(seen_ids),
          rejected_count: rejections.size, rejections: rejections
        )
      end
    end

    def import_entry(entry, source_name)
      unless entry.is_a?(Hash) && entry["id"].present?
        return [ :rejected, "la entrada debe ser un objeto con id" ]
      end

      cryptic = Cryptic.find_or_initialize_by(external_id: entry["id"].to_s)
      cryptic.assign_attributes(attributes_for(entry, source_name))
      # Solo se reactiva lo que desactivó el sync, no lo que desactive un admin a mano.
      cryptic.assign_attributes(active: true, deactivated_by_sync: false) if cryptic.deactivated_by_sync?
      was_new = cryptic.new_record?
      was_changed = cryptic.changed?

      return [ :rejected, cryptic.errors.full_messages.to_sentence ] unless cryptic.save
      return [ :created ] if was_new

      [ was_changed ? :updated : :unchanged ]
    end

    def attributes_for(entry, source_name)
      {
        clue: entry["enunciado"],
        answer: entry["respuesta"],
        definitions: Array(entry["definiciones"]),
        indicators: Array(entry["indicadores"]),
        material: Array(entry["material"]),
        puzzle_type: entry["tipo"],
        difficulty: entry["dificultad"],
        hint: entry["ayuda"],
        explanation: entry["explicacion"],
        author: entry["autor"],
        source: source_name,
        source_enumeration: entry["enumeracion"].to_s
      }
    end

    def deactivate_missing(seen_ids)
      return 0 if seen_ids.empty? # nunca vaciar el catálogo por un payload inusable

      Cryptic.where(active: true)
             .where.not(external_id: seen_ids)
             .update_all(active: false, deactivated_by_sync: true, updated_at: Time.current)
    end
  end
end
