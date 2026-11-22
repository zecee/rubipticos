SOURCE_URL = "https://ecorrons.github.io/cryptics-api/v1/cryptics.json"

begin
  run = Cryptics::Sync.new(source_url: SOURCE_URL).call
  puts "Catálogo (#{run.status_label}): #{run.created_count} creados, " \
       "#{run.updated_count} actualizados, #{run.deactivated_count} desactivados, " \
       "#{run.rejected_count} rechazados."
  run.rejections.each { |r| puts "  - #{r['id']}: #{r['reason']}" }
rescue Cryptics::Sync::Error => e
  warn "No se pudo cargar el catálogo: #{e.message}"
  warn "Verificá la conexión y corré `bin/rails db:seed` de nuevo."
end