module Admin
  class UsersController < AdminController
    before_action :set_user, only: [:show, :edit, :update, :destroy, :toggle_admin]
    before_action :authorize_action

    def index
      @filters = build_filters
      @users = apply_filters(User.all)
      @total_users = User.count
      @active_users = User.where('last_login_at > ?', 30.days.ago).count
      @premium_users = (User.where(subscription_status: 'active').count.to_f / User.count * 100).round(1)
    end

    private

    def build_filters
      filters = []

      if can?(:view_sensitive, :users)
        filters << {
          name: 'subscription_status',
          label: 'Subscription Status',
          type: :tags,
          options: [
            { value: 'active', label: 'Active' },
            { value: 'cancelled', label: 'Cancelled' },
            { value: 'trial', label: 'Trial' }
          ]
        }

        filters << {
          name: 'registration_date',
          label: 'Registration Date',
          type: :date_range
        }

        filters << {
          name: 'login_count',
          label: 'Login Count',
          type: :range,
          min: 0,
          max: 1000,
          step: 1
        }
      end

      filters << {
        name: 'search',
        label: 'Search',
        type: :search,
        placeholder: 'Search by email or username'
      }

      if can?(:manage_roles, :users)
        filters << {
          name: 'roles',
          label: 'Roles',
          type: :multi_select,
          options: AdminRole.all.map { |role| { value: role.id, label: role.name } }
        }
      end

      if can?(:view_sensitive, :users)
        filters << {
          name: 'engagement',
          label: 'Engagement Level',
          type: :rating
        }
      end

      filters << {
        name: 'active',
        label: 'Active Users Only',
        type: :boolean,
        description: 'Show only users who logged in within the last 30 days'
      }

      filters
    end

    def apply_filters(scope)
      scope = scope.search(params[:search]) if params[:search].present?
      
      if can?(:view_sensitive, :users)
        if params[:subscription_status].present?
          statuses = params[:subscription_status].split(',')
          scope = scope.where(subscription_status: statuses) unless statuses.empty?
        end
        
        if params[:registration_date_from].present?
          scope = scope.where('created_at >= ?', params[:registration_date_from])
        end
        
        if params[:registration_date_to].present?
          scope = scope.where('created_at <= ?', params[:registration_date_to])
        end

        if params[:login_count_min].present?
          scope = scope.where('login_count >= ?', params[:login_count_min])
        end

        if params[:login_count_max].present?
          scope = scope.where('login_count <= ?', params[:login_count_max])
        end

        if params[:engagement].present?
          scope = scope.where('engagement_score >= ?', params[:engagement])
        end
      end

      if can?(:manage_roles, :users) && params[:roles].present?
        role_ids = params[:roles].split(',').map(&:to_i)
        scope = scope.joins(:admin_role_assignments)
                    .where(admin_role_assignments: { admin_role_id: role_ids })
                    .distinct
      end

      scope = scope.where('last_login_at > ?', 30.days.ago) if params[:active] == '1'

      scope.order(created_at: :desc)
    end

    def active_filters
      filters = []
      
      if params[:search].present?
        filters << { name: 'search', label: 'Search', value: params[:search] }
      end

      if params[:subscription_status].present? && can?(:view_sensitive, :users)
        statuses = params[:subscription_status].split(',').map(&:titleize)
        filters << { 
          name: 'subscription_status',
          label: 'Subscription',
          value: statuses.join(', ')
        }
      end

      if params[:roles].present? && can?(:manage_roles, :users)
        role_ids = params[:roles].split(',').map(&:to_i)
        role_names = AdminRole.where(id: role_ids).pluck(:name)
        filters << { name: 'roles', label: 'Roles', value: role_names.join(', ') }
      end

      if can?(:view_sensitive, :users)
        if params[:login_count_min].present? || params[:login_count_max].present?
          filters << {
            name: 'login_count',
            label: 'Login Count',
            value: "#{params[:login_count_min] || '0'} - #{params[:login_count_max] || '∞'}"
          }
        end

        if params[:engagement].present?
          filters << {
            name: 'engagement',
            label: 'Engagement',
            value: "#{params[:engagement]}+ stars"
          }
        end
      end

      if params[:active] == '1'
        filters << { name: 'active', label: 'Status', value: 'Active Only' }
      end

      filters
    end
    helper_method :active_filters

    def set_user
      @user = User.find(params[:id])
    end

    def authorize_action
      case action_name.to_sym
      when :index
        authorize! :view, :users
      when :show
        authorize! :view, :users
      when :edit, :update
        authorize! :edit, :users
      when :destroy
        authorize! :delete, :users
      when :toggle_admin
        authorize! :manage_roles, :users
      end
    end
  end
end
