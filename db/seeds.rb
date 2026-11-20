begin
  Cryptics::Sync.new(
    source_url: "https://ecorrons.github.io/cryptics-api/v1/cryptics.json"
  ).call
rescue Cryptics::Sync::Error => e
  warn "Catalog sync failed: #{e.message}"
end