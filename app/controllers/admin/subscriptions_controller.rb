module Admin
  class SubscriptionsController < AdminController
    before_action :set_subscription, only: [:show, :edit, :update, :cancel]
    before_action :authorize_action

    def index
      @filters = build_filters
      @subscriptions = apply_filters(Subscription.all)
      @total_revenue = Subscription.active.sum(:amount)
      @active_subscriptions = Subscription.active.count
      @trial_conversions = (Subscription.converted_from_trial.count.to_f / Subscription.total_trials.count * 100).round(1)
    end

    private

    def build_filters
      filters = []

      if can?(:view_sensitive, :subscriptions)
        filters << {
          name: 'status',
          label: 'Status',
          type: :tags,
          options: [
            { value: 'active', label: 'Active' },
            { value: 'cancelled', label: 'Cancelled' },
            { value: 'trial', label: 'Trial' },
            { value: 'expired', label: 'Expired' }
          ]
        }

        filters << {
          name: 'date',
          label: 'Subscription Date',
          type: :date_range
        }

        filters << {
          name: 'amount',
          label: 'Amount',
          type: :range,
          min: 0,
          max: 1000,
          step: 10
        }

        filters << {
          name: 'plan_types',
          label: 'Plan Types',
          type: :multi_select,
          options: [
            { value: 'monthly', label: 'Monthly' },
            { value: 'quarterly', label: 'Quarterly' },
            { value: 'annual', label: 'Annual' },
            { value: 'lifetime', label: 'Lifetime' }
          ]
        }

        filters << {
          name: 'satisfaction',
          label: 'Customer Satisfaction',
          type: :rating
        }
      end

      filters << {
        name: 'search',
        label: 'Search',
        type: :search,
        placeholder: 'Search by email or subscription ID'
      }

      filters << {
        name: 'auto_renew',
        label: 'Auto-renewing Only',
        type: :boolean,
        description: 'Show only subscriptions with auto-renewal enabled'
      }

      filters
    end

    def apply_filters(scope)
      scope = scope.search(params[:search]) if params[:search].present?
      
      if can?(:view_sensitive, :subscriptions)
        if params[:status].present?
          statuses = params[:status].split(',')
          scope = scope.where(status: statuses) unless statuses.empty?
        end
        
        if params[:date_from].present?
          scope = scope.where('created_at >= ?', params[:date_from])
        end
        
        if params[:date_to].present?
          scope = scope.where('created_at <= ?', params[:date_to])
        end

        if params[:amount_min].present?
          scope = scope.where('amount >= ?', params[:amount_min])
        end

        if params[:amount_max].present?
          scope = scope.where('amount <= ?', params[:amount_max])
        end

        if params[:plan_types].present?
          plan_types = params[:plan_types].split(',')
          scope = scope.where(plan_type: plan_types)
        end

        if params[:satisfaction].present?
          scope = scope.where('satisfaction_score >= ?', params[:satisfaction])
        end
      end

      scope = scope.where(auto_renew: true) if params[:auto_renew] == '1'

      scope.order(created_at: :desc)
    end

    def active_filters
      filters = []
      
      if params[:search].present?
        filters << { name: 'search', label: 'Search', value: params[:search] }
      end

      if params[:status].present? && can?(:view_sensitive, :subscriptions)
        statuses = params[:status].split(',').map(&:titleize)
        filters << { 
          name: 'status',
          label: 'Status',
          value: statuses.join(', ')
        }
      end

      if can?(:view_sensitive, :subscriptions)
        if params[:amount_min].present? || params[:amount_max].present?
          filters << {
            name: 'amount',
            label: 'Amount',
            value: "$#{params[:amount_min] || '0'} - $#{params[:amount_max] || '∞'}"
          }
        end

        if params[:plan_types].present?
          plan_types = params[:plan_types].split(',').map(&:titleize)
          filters << {
            name: 'plan_types',
            label: 'Plan Types',
            value: plan_types.join(', ')
          }
        end

        if params[:satisfaction].present?
          filters << {
            name: 'satisfaction',
            label: 'Satisfaction',
            value: "#{params[:satisfaction]}+ stars"
          }
        end
      end

      if params[:auto_renew] == '1'
        filters << { name: 'auto_renew', label: 'Renewal', value: 'Auto-renewing' }
      end

      filters
    end
    helper_method :active_filters

    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    def authorize_action
      case action_name.to_sym
      when :index
        authorize! :view, :subscriptions
      when :show
        authorize! :view, :subscriptions
      when :edit, :update
        authorize! :edit, :subscriptions
      when :cancel
        authorize! :cancel, :subscriptions
      end
    end
  end
end
