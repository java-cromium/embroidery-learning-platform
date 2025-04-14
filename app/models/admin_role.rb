class AdminRole < ActiveRecord::Base
  PERMISSIONS = {
    users: {
      view: 'View users',
      create: 'Create users',
      edit: 'Edit users',
      delete: 'Delete users',
      manage_roles: 'Manage user roles',
      view_sensitive: 'View sensitive user data',
      manage_permissions: 'Manage user permissions',
      impersonate: 'Impersonate users'
    },
    subscriptions: {
      view: 'View subscriptions',
      create: 'Create subscription plans',
      edit: 'Edit subscription plans',
      delete: 'Delete subscription plans',
      manage: 'Manage user subscriptions',
      view_revenue: 'View revenue data',
      issue_refunds: 'Issue refunds',
      apply_discounts: 'Apply discount codes',
      manage_billing: 'Manage billing settings'
    },
    content: {
      view: 'View content',
      create: 'Create content',
      edit: 'Edit content',
      delete: 'Delete content',
      publish: 'Publish content',
      manage_categories: 'Manage content categories',
      manage_tags: 'Manage content tags',
      moderate_comments: 'Moderate user comments',
      feature_content: 'Feature content on homepage'
    },
    history: {
      view: 'View historical content',
      create: 'Create historical content',
      edit: 'Edit historical content',
      delete: 'Delete historical content',
      manage_periods: 'Manage historical periods',
      manage_artifacts: 'Manage historical artifacts',
      curate_collections: 'Curate historical collections',
      manage_metadata: 'Manage historical metadata'
    },
    reports: {
      view: 'View reports',
      export: 'Export reports',
      create_custom: 'Create custom reports',
      schedule: 'Schedule automated reports',
      view_financial: 'View financial reports',
      view_analytics: 'View analytics data',
      manage_dashboards: 'Manage report dashboards'
    },
    settings: {
      view: 'View settings',
      edit: 'Edit settings',
      manage_integrations: 'Manage third-party integrations',
      manage_api: 'Manage API settings',
      manage_security: 'Manage security settings',
      manage_email: 'Manage email templates',
      view_logs: 'View system logs',
      manage_backups: 'Manage system backups'
    },
    courses: {
      view: 'View courses',
      create: 'Create courses',
      edit: 'Edit courses',
      delete: 'Delete courses',
      manage_curriculum: 'Manage course curriculum',
      grade_assignments: 'Grade course assignments',
      manage_enrollments: 'Manage course enrollments',
      view_progress: 'View student progress'
    },
    community: {
      view: 'View community content',
      moderate: 'Moderate community content',
      manage_forums: 'Manage discussion forums',
      pin_topics: 'Pin forum topics',
      manage_events: 'Manage community events',
      send_announcements: 'Send community announcements'
    }
  }

  has_many :admin_role_assignments, dependent: :destroy
  has_many :users, through: :admin_role_assignments

  validates :name, presence: true, uniqueness: true
  validates :permissions, presence: true

  before_destroy :prevent_system_role_deletion

  def self.create_default_roles
    [
      {
        name: 'Super Admin',
        description: 'Full access to all features',
        permissions: generate_full_permissions,
        is_system_role: true
      },
      {
        name: 'Content Manager',
        description: 'Manage content and historical artifacts',
        permissions: {
          content: ['view', 'create', 'edit', 'delete', 'publish', 'manage_categories', 'manage_tags', 'moderate_comments', 'feature_content'],
          history: ['view', 'create', 'edit', 'delete', 'manage_periods', 'manage_artifacts', 'curate_collections', 'manage_metadata'],
          courses: ['view', 'create', 'edit', 'delete', 'manage_curriculum'],
          community: ['view', 'moderate', 'pin_topics']
        },
        is_system_role: true
      },
      {
        name: 'Support Agent',
        description: 'Handle user support and basic management',
        permissions: {
          users: ['view', 'edit', 'view_sensitive'],
          subscriptions: ['view', 'manage', 'issue_refunds', 'apply_discounts'],
          content: ['view'],
          community: ['view', 'moderate'],
          courses: ['view', 'view_progress']
        },
        is_system_role: true
      },
      {
        name: 'Analytics Manager',
        description: 'Access to reports and analytics',
        permissions: {
          reports: ['view', 'export', 'create_custom', 'schedule', 'view_financial', 'view_analytics', 'manage_dashboards'],
          users: ['view'],
          subscriptions: ['view', 'view_revenue'],
          courses: ['view', 'view_progress']
        },
        is_system_role: true
      },
      {
        name: 'Course Instructor',
        description: 'Manage courses and student progress',
        permissions: {
          courses: ['view', 'create', 'edit', 'manage_curriculum', 'grade_assignments', 'manage_enrollments', 'view_progress'],
          content: ['view', 'create', 'edit', 'publish'],
          community: ['view', 'moderate', 'manage_forums', 'pin_topics', 'manage_events'],
          users: ['view']
        },
        is_system_role: true
      },
      {
        name: 'Community Manager',
        description: 'Manage community engagement and moderation',
        permissions: {
          community: ['view', 'moderate', 'manage_forums', 'pin_topics', 'manage_events', 'send_announcements'],
          content: ['view', 'moderate_comments'],
          users: ['view'],
          courses: ['view']
        },
        is_system_role: true
      }
    ].each do |role_attrs|
      AdminRole.find_or_create_by!(name: role_attrs[:name]) do |role|
        role.assign_attributes(role_attrs)
      end
    end
  end

  def self.generate_full_permissions
    PERMISSIONS.transform_values do |actions|
      actions.keys
    end
  end

  def has_permission?(resource, action)
    return true if super_admin?
    permissions.dig(resource.to_s, action.to_s).present?
  end

  def super_admin?
    name == 'Super Admin'
  end

  private

  def prevent_system_role_deletion
    if is_system_role
      errors.add(:base, "Cannot delete system role")
      throw :abort
    end
  end
end
