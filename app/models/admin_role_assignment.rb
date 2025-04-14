class AdminRoleAssignment < ActiveRecord::Base
  belongs_to :user
  belongs_to :admin_role

  validates :user_id, uniqueness: { scope: :admin_role_id }
  validate :prevent_last_super_admin_removal, on: :destroy

  private

  def prevent_last_super_admin_removal
    if admin_role.super_admin? && user.admin_roles.where(name: 'Super Admin').count == 1
      errors.add(:base, "Cannot remove the last Super Admin")
      throw :abort
    end
  end
end
