setting = AppSetting.instance

begin
  run = Cryptics::Sync.new(source_url: setting.source_url).call
  puts "Catálogo (#{run.status_label}): #{run.created_count} creados, " \
       "#{run.updated_count} actualizados, #{run.deactivated_count} desactivados, " \
       "#{run.rejected_count} rechazados."
  run.rejections.each { |r| puts "  - #{r['id']}: #{r['reason']}" }
rescue Cryptics::Sync::Error => e
  warn "No se pudo cargar el catálogo: #{e.message}"
  warn "Verificá la conexión e intentalo de nuevo."
end
