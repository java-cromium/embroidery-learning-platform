class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :subscription_plan

  validates :status, inclusion: { in: ['active', 'canceled', 'past_due'] }
  validates :stripe_subscription_id, uniqueness: true, allow_nil: true

  scope :active, -> { where(status: 'active') }
  scope :canceled, -> { where(status: 'canceled') }
  scope :past_due, -> { where(status: 'past_due') }

  def active?
    status == 'active'
  end

  def canceled?
    status == 'canceled'
  end

  def past_due?
    status == 'past_due'
  end

  def trial?
    current_period_start == created_at
  end

  def days_remaining
    return 0 if current_period_end.nil?
    ((current_period_end - Time.current) / 1.day).ceil
  end

  def cancel
    return false if canceled?
    
    if stripe_subscription_id
      Stripe::Subscription.update(
        stripe_subscription_id,
        { cancel_at_period_end: true }
      )
    end

    update(
      cancel_at_period_end: true,
      canceled_at: Time.current
    )
  end

  def reactivate
    return false unless cancel_at_period_end

    if stripe_subscription_id
      Stripe::Subscription.update(
        stripe_subscription_id,
        { cancel_at_period_end: false }
      )
    end

    update(
      cancel_at_period_end: false,
      canceled_at: nil
    )
  end

  private

  def update_user_premium_status
    user.update(premium: active? && subscription_plan.premium?)
  end
end
