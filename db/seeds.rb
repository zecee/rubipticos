# Primer administrador del backend (no hay registro público).
# La contraseña se puede cambiar con ADMIN_PASSWORD=... bin/rails db:seed
admin = User.find_or_create_by!(email_address: "admin@rubipticos.test") do |user|
  user.password = ENV.fetch("ADMIN_PASSWORD", "password")
  user.role = "admin"
end
puts "Admin: #{admin.email_address}"

SOURCE_URL = "https://ecorrons.github.io/cryptics-api/v1/cryptics.json"
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
