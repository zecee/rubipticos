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

# Crípticos de ejemplo para probar el backend con casos que el catálogo de la cátedra no trae
# (solo en desarrollo): otro origen, sin autor ni ayudas, respuesta de dos palabras e inactivo.
# Como no vienen en la fuente, la próxima sincronización los desactiva.
if Rails.env.development?
  [
    { external_id: "demo-001", clue: "Felino o herramienta para cambiar la rueda", answer: "GATO",
      definitions: [ "Felino", "herramienta para cambiar la rueda" ], puzzle_type: "doble_definicion",
      difficulty: "facil", source: "Demo local", active: true },
    { external_id: "demo-002", clue: "Pareja ideal o mitad de una fruta", answer: "MEDIA NARANJA",
      definitions: [ "Pareja ideal", "mitad de una fruta" ], puzzle_type: "doble_definicion",
      difficulty: "medio", source: "Demo local", author: "Equipo", hint: "Se dice de la pareja perfecta.",
      active: false }
  ].each do |attributes|
    Cryptic.find_or_create_by!(external_id: attributes[:external_id]) { |cryptic| cryptic.assign_attributes(attributes) }
  end
end

# Partidas de ejemplo para ver las estadísticas de los crípticos en el backend (solo en desarrollo).
# Todavía no existe el flujo para resolver una partida, así que se insertan directo. Cada partida
# usa su propio jugador porque un jugador no puede tener dos partidas abiertas a la vez.
if Rails.env.development? && !Player.exists?(name: "Demo 01")
  # external_id => [segundos hasta resolver, o nil si no lo resolvió (o :prepared si no arrancó)]
  demo_games = {
    "cr-001" => [ 20, 35, 48, 77 ],             # 100 % resuelto, menos de un minuto
    "cr-002" => [ 95, 140, 210, nil, nil ],      # 60 % resuelto, minutos
    "cr-003" => [ nil, nil, nil ],               # jugado y nunca resuelto
    "cr-004" => [ 3_725 ],                       # más de una hora
    "cr-005" => [ :prepared ]                    # asignado pero sin arrancar: no cuenta como jugado
  }
  cryptics = Cryptic.where(external_id: demo_games.keys).index_by(&:external_id)
  started_at = 3.days.ago.change(usec: 0)
  rows = demo_games.flat_map do |external_id, outcomes|
    cryptic = cryptics[external_id] or next []
    outcomes.map { |outcome| [ cryptic, outcome ] }
  end

  rows.each.with_index(1) do |(cryptic, outcome), index|
    player = Player.create!(name: format("Demo %02d", index))
    game = { player_id: player.id, cryptic_id: cryptic.id, created_at: started_at, updated_at: started_at }
    game.merge!(
      if outcome == :prepared
        { status: "PREPARED" }
      else
        { status: "IN_PROGRESS", started_at: started_at, solved_at: outcome && started_at + outcome.seconds }
      end
    )
    Game.insert!(game)
  end
  puts "Partidas de ejemplo: #{rows.size}."
end
