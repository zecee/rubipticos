class PagesController < PublicController
  def home
    @welcome_text = AppSetting.instance.welcome_text
  end
end
