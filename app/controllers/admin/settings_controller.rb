module Admin
  class SettingsController < BaseController
    def show
      @setting = AppSetting.instance
    end

    def update
      @setting = AppSetting.instance
      if @setting.update(setting_params)
        redirect_to admin_settings_path, status: :see_other, notice: "Configuración guardada."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def setting_params
      params.expect(app_setting: %i[source_url welcome_text])
    end
  end
end
