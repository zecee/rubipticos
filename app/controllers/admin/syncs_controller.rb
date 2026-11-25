module Admin
  class SyncsController < BaseController
    PER_PAGE = 10

    def index
      @source_url = AppSetting.instance.source_url
      @current_version = SyncRun.last_completed&.version
      @total_cryptics = Cryptic.count
      @active_cryptics = Cryptic.active.count
      @latest_run = SyncRun.includes(:user).order(:id).last
      @runs = SyncRun.includes(:user).order(id: :desc).paginate(page: current_page, per_page: PER_PAGE)
    end

    def create
      run = Cryptics::Sync.new(source_url: AppSetting.instance.source_url, user: current_user).call
      redirect_to admin_syncs_path, status: :see_other, notice: "Sincronización #{run.status_label.downcase}."
    rescue Cryptics::Sync::Error => e
      redirect_to admin_syncs_path, status: :see_other, alert: "No se pudo sincronizar: #{e.message}."
    end
  end
end
