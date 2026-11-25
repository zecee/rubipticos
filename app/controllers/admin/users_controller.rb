module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[edit update activate deactivate]

    def index
      @users = User.order(:email_address)
    end

    def new
      @user = User.new(role: "score_editor")
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to admin_users_path, status: :see_other, notice: "Usuario #{@user.email_address} creado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to admin_users_path, status: :see_other, notice: "Usuario #{@user.email_address} actualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def activate
      @user.update!(active: true)
      redirect_to admin_users_path, status: :see_other, notice: "Usuario #{@user.email_address} activado."
    end

    def deactivate
      if @user == current_user
        redirect_to admin_users_path, status: :see_other, alert: "No podés desactivar tu propio usuario."
      elsif @user.update(active: false)
        redirect_to admin_users_path, status: :see_other, notice: "Usuario #{@user.email_address} desactivado."
      else
        redirect_to admin_users_path, status: :see_other, alert: @user.errors.full_messages.to_sentence
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    # La contraseña en blanco deja la actual. Un admin no puede cambiarse el rol a sí mismo.
    def user_params
      permitted = params.expect(user: %i[email_address password password_confirmation role])
      permitted.delete(:role) if @user == current_user
      if permitted[:password].blank? && @user&.persisted?
        permitted.delete(:password)
        permitted.delete(:password_confirmation)
      end
      permitted
    end
  end
end
