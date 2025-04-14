class User < ActiveRecord::Base
  has_secure_password

  has_many :admin_role_assignments, dependent: :destroy
  has_many :admin_roles, through: :admin_role_assignments

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 30 }
  validates :subscription_tier, inclusion: { in: %w[free premium] }

  after_save :ensure_super_admin_role, if: :admin_changed?

  # Social media profile methods
  def update_social_profile(provider, data)
    current_profiles = social_profiles || {}
    current_profiles[provider] = data
    update(social_profiles: current_profiles)
  end

  def social_profile(provider)
    (social_profiles || {})[provider]
  end

  # Subscription methods
  def premium?
    subscription_tier == 'premium'
  end

  def has_admin_permission?(resource, action)
    return false unless admin?
    admin_roles.any? { |role| role.has_permission?(resource, action) }
  end

  def super_admin?
    admin? && admin_roles.any?(&:super_admin?)
  end

  def assign_role(role_name)
    role = AdminRole.find_by(name: role_name)
    return false unless role
    admin_role_assignments.create(admin_role: role)
  end

  def remove_role(role_name)
    role = AdminRole.find_by(name: role_name)
    return false unless role
    admin_role_assignments.find_by(admin_role: role)&.destroy
  end

  private

  def ensure_super_admin_role
    if admin? && admin_roles.empty?
      super_admin_role = AdminRole.find_by(name: 'Super Admin')
      admin_role_assignments.create(admin_role: super_admin_role) if super_admin_role
    end
  end
end
