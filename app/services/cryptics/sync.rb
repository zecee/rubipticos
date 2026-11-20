require "net/http"

module Cryptics
  class Sync
    class Error < StandardError; end
    class FetchError < Error; end
    class InvalidPayloadError < Error; end

    REQUEST_TIMEOUT = 10 # seconds

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
      raise FetchError, "invalid source URL" unless uri.is_a?(URI::HTTP) && uri.host.present?

      response = Net::HTTP.start(
        uri.host, uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: REQUEST_TIMEOUT,
        read_timeout: REQUEST_TIMEOUT
      ) { |http| http.request(Net::HTTP::Get.new(uri)) }

      raise FetchError, "unexpected response: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      payload = JSON.parse(response.body)
      validate_payload!(payload)
      payload
    rescue URI::InvalidURIError
      raise FetchError, "invalid source URL"
    rescue Timeout::Error, SocketError, SystemCallError, IOError, OpenSSL::SSL::SSLError, Net::ProtocolError => e
      raise FetchError, "could not fetch the catalog: #{e.message}"
    rescue JSON::ParserError
      raise InvalidPayloadError, "the catalog is not valid JSON"
    end

    def validate_payload!(payload)
      valid = payload.is_a?(Hash) && payload["version"].present? && payload["cripticos"].is_a?(Array)
      raise InvalidPayloadError, "the catalog has an unexpected structure" unless valid
    end

    def already_synced?(version)
      SyncRun.completed.where(source_url: @source_url).order(:id).last&.version == version
    end

    def record_unchanged(version)
      SyncRun.create!(user: @user, source_url: @source_url, status: "unchanged", version: version)
    end

    def import(payload, version)
      created = updated = 0
      rejections = []
      seen_ids = []

      ActiveRecord::Base.transaction do
        payload["cripticos"].each do |entry|
          seen_ids << entry["id"].to_s if entry.is_a?(Hash) && entry["id"].present?

          outcome, reason = import_entry(entry, payload["fuente"])
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
        return [:rejected, "entry must be an object with an id"]
      end

      cryptic = Cryptic.find_or_initialize_by(external_id: entry["id"].to_s)
      cryptic.assign_attributes(attributes_for(entry, source_name))
      was_new = cryptic.new_record?
      was_changed = cryptic.changed?

      return [:rejected, cryptic.errors.full_messages.to_sentence] unless cryptic.save
      return [:created] if was_new

      [was_changed ? :updated : :unchanged]
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
      return 0 if seen_ids.empty? # never wipe the catalog because of an unusable payload

      Cryptic.where(active: true)
             .where.not(external_id: seen_ids)
             .update_all(active: false, updated_at: Time.current)
    end
  end
end