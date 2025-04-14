class Admin::RolesController < AdminController
  before_action :require_admin_permission, :settings, :edit
  before_action :set_role, only: [:edit, :update, :destroy]

  def index
    @roles = AdminRole.all.order(:name)
  end

  def new
    @role = AdminRole.new
  end

  def create
    @role = AdminRole.new(role_params)
    if @role.save
      flash[:success] = "Role was successfully created."
      redirect_to admin_roles_path
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @role.update(role_params)
      flash[:success] = "Role was successfully updated."
      redirect_to admin_roles_path
    else
      render :edit
    end
  end

  def destroy
    if @role.destroy
      flash[:success] = "Role was successfully deleted."
    else
      flash[:error] = @role.errors.full_messages.join(", ")
    end
    redirect_to admin_roles_path
  end

  private

  def set_role
    @role = AdminRole.find(params[:id])
  end

  def role_params
    params.require(:admin_role).permit(:name, :description, permissions: AdminRole::PERMISSIONS.keys)
  end
end
