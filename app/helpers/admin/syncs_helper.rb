module Admin
  module SyncsHelper
    STATUS_PILL_CLASSES = {
      "completed" => "admin-pill admin-pill--ok",
      "unchanged" => "admin-pill",
      "failed" => "admin-pill admin-pill--bad"
    }.freeze

    def sync_status_pill(run)
      tag.span run.status_label, class: STATUS_PILL_CLASSES.fetch(run.status)
    end

    def sync_time(run)
      l(run.created_at, format: "%d/%m/%Y %H:%M")
    end

    def sync_actor(run)
      run.user&.email_address || "Carga inicial (db:seed)"
    end
  end
end
