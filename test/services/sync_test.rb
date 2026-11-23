require "test_helper"

class Cryptics::SyncTest < ActiveSupport::TestCase
  URL = "http://catalogo.test/v1/cryptics.json".freeze

  def container_entry(overrides = {})
    {
      "id" => "cr-013", "enunciado" => "Mi metido en el hogar da una prenda", "enumeracion" => "(6)",
      "respuesta" => "CAMISA", "definiciones" => [ "una prenda" ], "indicadores" => [ "metido en" ],
      "material" => [ "Mi", "el hogar" ], "tipo" => "contenedor", "dificultad" => "medio",
      "ayuda" => "Partí el hogar al medio.", "explicacion" => "CA + MI + SA = CAMISA.", "autor" => "Cátedra"
    }.merge(overrides)
  end

  def endings_entry(overrides = {})
    {
      "id" => "cr-021", "enunciado" => "Colas de álbum, casa y amor dan agua salada", "enumeracion" => "(3)",
      "respuesta" => "MAR", "definiciones" => [ "agua salada" ], "indicadores" => [ "Colas de" ],
      "material" => [ "álbum, casa y amor" ], "tipo" => "finales", "dificultad" => "medio",
      "ayuda" => "Última letra de cada sustantivo.", "explicacion" => "álbuM, casA, amoR.", "autor" => "Cátedra"
    }.merge(overrides)
  end

  def stub_catalog(entries, version: "v1", source: "Cátedra")
    body = { "version" => version, "fuente" => source, "cripticos" => entries }.to_json
    stub_request(:get, URL).to_return(status: 200, body: body)
  end

  def sync(user: nil)
    Cryptics::Sync.new(source_url: URL, user: user).call
  end

  test "imports a valid catalog" do
    stub_catalog([ container_entry, endings_entry ])

    run = sync(user: users(:one))

    assert_equal "completed", run.status
    assert_equal "v1", run.version
    assert_equal [ 2, 0, 0, 0 ], run.values_at(:created_count, :updated_count, :deactivated_count, :rejected_count)
    assert_equal users(:one), run.user
    assert_equal 2, Cryptic.count
    assert Cryptic.find_by!(external_id: "cr-021").active?
  end

  test "reports unchanged when the version matches the last completed run" do
    stub_catalog([ container_entry ])
    sync

    assert_no_difference "Cryptic.count" do
      run = sync
      assert_equal "unchanged", run.status
      assert_equal "v1", run.version
    end
    assert_equal 2, SyncRun.count
  end

  test "updates a cryptic that changed in the source" do
    stub_catalog([ container_entry ])
    sync
    stub_catalog([ container_entry("ayuda" => "Otra ayuda.") ], version: "v2")

    run = sync

    assert_equal [ 0, 1 ], run.values_at(:created_count, :updated_count)
    assert_equal "Otra ayuda.", Cryptic.find_by!(external_id: "cr-013").hint
  end

  test "skips invalid cryptics and reports id and reason" do
    bad = container_entry("id" => "cr-900", "enumeracion" => "(9)")
    stub_catalog([ container_entry, bad ])

    run = sync

    assert_equal [ 1, 1 ], run.values_at(:created_count, :rejected_count)
    assert_equal "cr-900", run.rejections.first["id"]
    assert_match(/Enumeración/, run.rejections.first["reason"])
    assert_nil Cryptic.find_by(external_id: "cr-900")
  end

  test "rejects an entry without id" do
    stub_catalog([ container_entry, container_entry.except("id") ])

    run = sync

    assert_equal 1, run.rejected_count
    assert_nil run.rejections.first["id"]
  end

  test "rejects a repeated id and keeps the first occurrence" do
    stub_catalog([ container_entry, container_entry("respuesta" => "CASA") ])

    run = sync

    assert_equal [ 1, 0, 1 ], run.values_at(:created_count, :updated_count, :rejected_count)
    assert_equal "el id está repetido en la fuente", run.rejections.first["reason"]
    assert_equal "CAMISA", Cryptic.find_by!(external_id: "cr-013").answer
  end

  test "accepts finales material with a connector (cr-021)" do
    stub_catalog([ endings_entry ])

    assert_equal 0, sync.rejected_count
  end

  test "deactivates cryptics missing from the source without deleting them" do
    stub_catalog([ container_entry, endings_entry ])
    sync
    stub_catalog([ container_entry ], version: "v2")

    run = sync

    assert_equal 1, run.deactivated_count
    missing = Cryptic.find_by!(external_id: "cr-021")
    assert_not missing.active?
    assert missing.deactivated_by_sync?
    assert Cryptic.find_by!(external_id: "cr-013").active?
  end

  test "reactivates cryptics that were deactivated by the sync" do
    stub_catalog([ container_entry, endings_entry ])
    sync
    stub_catalog([ container_entry ], version: "v2")
    sync
    stub_catalog([ container_entry, endings_entry ], version: "v3")

    run = sync

    assert_equal 1, run.updated_count
    reactivated = Cryptic.find_by!(external_id: "cr-021")
    assert reactivated.active?
    assert_not reactivated.deactivated_by_sync?
  end

  test "does not reactivate cryptics deactivated manually" do
    stub_catalog([ container_entry ])
    sync
    Cryptic.find_by!(external_id: "cr-013").update!(active: false)
    stub_catalog([ container_entry ], version: "v2")

    run = sync

    assert_equal 0, run.updated_count
    assert_not Cryptic.find_by!(external_id: "cr-013").active?
  end

  test "uses a default source name when the catalog has none" do
    stub_catalog([ container_entry ], source: nil)

    assert_equal 0, sync.rejected_count
    assert_equal "Fuente desconocida", Cryptic.find_by!(external_id: "cr-013").source
  end

  test "a network failure is recorded as failed and leaves the database untouched" do
    stub_catalog([ container_entry ])
    sync
    stub_request(:get, URL).to_raise(Errno::ECONNREFUSED)

    assert_no_difference "Cryptic.count" do
      error = assert_raises(Cryptics::Sync::FetchError) { sync }
      assert_match(/no se pudo obtener el catálogo/, error.message)
    end
    assert_equal "failed", SyncRun.order(:id).last.status
    assert Cryptic.all.all?(&:active?)
  end

  test "a timeout is recorded as failed" do
    stub_request(:get, URL).to_timeout

    assert_raises(Cryptics::Sync::FetchError) { sync }
    assert_equal "failed", SyncRun.last.status
  end

  test "an unexpected HTTP status is recorded as failed" do
    stub_request(:get, URL).to_return(status: 500)

    error = assert_raises(Cryptics::Sync::FetchError) { sync }
    assert_match(/HTTP 500/, error.message)
  end

  test "an invalid JSON is recorded as failed" do
    stub_request(:get, URL).to_return(status: 200, body: "no es json")

    assert_raises(Cryptics::Sync::InvalidPayloadError) { sync }
    assert_equal "failed", SyncRun.last.status
  end

  test "an invalid URL is recorded as failed" do
    assert_raises(Cryptics::Sync::FetchError) do
      Cryptics::Sync.new(source_url: "no-es-una-url").call
    end
    assert_equal "failed", SyncRun.last.status
  end

  test "an empty catalog is rejected and does not deactivate anything" do
    stub_catalog([ container_entry ])
    sync
    stub_catalog([], version: "v2")

    error = assert_raises(Cryptics::Sync::InvalidPayloadError) { sync }

    assert_equal "el catálogo no contiene crípticos", error.message
    assert_equal "failed", SyncRun.order(:id).last.status
    assert Cryptic.find_by!(external_id: "cr-013").active?
  end

  test "a failed run does not block the next attempt" do
    stub_request(:get, URL).to_raise(Errno::ECONNREFUSED)
    assert_raises(Cryptics::Sync::FetchError) { sync }
    stub_catalog([ container_entry ])

    assert_equal "completed", sync.status
  end
end
