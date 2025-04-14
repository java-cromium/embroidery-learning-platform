module AdminAuthorizationHelper
  def require_admin_permission(resource, action)
    unless current_user&.has_admin_permission?(resource, action)
      flash[:error] = "You don't have permission to perform this action"
      redirect '/admin'
    end
  end

  def can_access?(resource, action)
    current_user&.has_admin_permission?(resource, action)
  end

  def super_admin?
    current_user&.super_admin?
  end
end
