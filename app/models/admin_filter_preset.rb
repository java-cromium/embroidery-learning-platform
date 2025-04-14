class AdminFilterPreset < ApplicationRecord
  belongs_to :user
  validates :name, presence: true
  validates :resource_type, presence: true
  validates :filters, presence: true

  # Store filters as JSON
  serialize :filters

  # Resource types that can have filter presets
  RESOURCE_TYPES = %w[users subscriptions courses community_posts reports]

  # Scope for finding presets by resource type
  scope :for_resource, ->(resource_type) { where(resource_type: resource_type) }
  
  # Scope for finding global presets (shared with all users)
  scope :global, -> { where(global: true) }
  
  # Scope for finding user's personal presets
  scope :personal, ->(user) { where(user: user, global: false) }

  # Get all presets available to a user for a resource type
  def self.available_to(user, resource_type)
    where(resource_type: resource_type)
      .where('global = ? OR user_id = ?', true, user.id)
      .order(global: :desc, name: :asc)
  end

  # Check if preset can be modified by user
  def modifiable_by?(user)
    user_id == user.id || (global && user.can?(:manage_presets, resource_type.to_sym))
  end

  # Apply filters to a scope
  def apply_to(scope)
    filters.each do |filter_name, value|
      case filter_name
      when 'search'
        scope = scope.search(value) if value.present?
      when 'status', 'subscription_status'
        scope = scope.where(filter_name => value.split(',')) if value.present?
      when 'roles'
        if value.present?
          role_ids = value.split(',').map(&:to_i)
          scope = scope.joins(:admin_role_assignments)
                      .where(admin_role_assignments: { admin_role_id: role_ids })
                      .distinct
        end
      when 'date', 'registration_date'
        if value['from'].present?
          scope = scope.where('created_at >= ?', value['from'])
        end
        if value['to'].present?
          scope = scope.where('created_at <= ?', value['to'])
        end
      when 'amount', 'login_count'
        if value['min'].present?
          scope = scope.where("#{filter_name} >= ?", value['min'])
        end
        if value['max'].present?
          scope = scope.where("#{filter_name} <= ?", value['max'])
        end
      when 'engagement', 'satisfaction'
        scope = scope.where("#{filter_name}_score >= ?", value) if value.present?
      when 'active'
        scope = scope.where('last_login_at > ?', 30.days.ago) if value == '1'
      when 'auto_renew'
        scope = scope.where(auto_renew: true) if value == '1'
      end
    end
    scope
  end
end
