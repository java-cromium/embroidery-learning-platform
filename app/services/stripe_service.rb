class StripeService
  def initialize(user)
    @user = user
    Stripe.api_key = ENV['STRIPE_SECRET_KEY']
  end

  def create_customer
    return @user.stripe_customer_id if @user.stripe_customer_id

    customer = Stripe::Customer.create(
      email: @user.email,
      metadata: {
        user_id: @user.id
      }
    )
    @user.update(stripe_customer_id: customer.id)
    customer.id
  end

  def create_subscription(plan, payment_method_id)
    customer_id = create_customer
    
    # Attach payment method to customer
    payment_method = Stripe::PaymentMethod.attach(
      payment_method_id,
      { customer: customer_id }
    )

    # Set as default payment method
    Stripe::Customer.update(
      customer_id,
      { invoice_settings: { default_payment_method: payment_method.id } }
    )

    # Create subscription
    subscription = Stripe::Subscription.create(
      customer: customer_id,
      items: [{ price: plan.stripe_price_id }],
      payment_behavior: 'default_incomplete',
      expand: ['latest_invoice.payment_intent']
    )

    # Create local subscription record
    @user.subscriptions.create!(
      subscription_plan: plan,
      status: subscription.status,
      current_period_start: Time.at(subscription.current_period_start),
      current_period_end: Time.at(subscription.current_period_end),
      stripe_subscription_id: subscription.id,
      stripe_customer_id: customer_id
    )

    # Create payment method record
    @user.payment_methods.create!(
      stripe_payment_method_id: payment_method.id,
      card_brand: payment_method.card.brand,
      card_last4: payment_method.card.last4,
      card_exp_month: payment_method.card.exp_month,
      card_exp_year: payment_method.card.exp_year,
      default: true
    )

    subscription
  end

  def update_subscription(subscription, new_plan)
    stripe_sub = Stripe::Subscription.update(
      subscription.stripe_subscription_id,
      {
        items: [{
          id: subscription.stripe_subscription_id,
          price: new_plan.stripe_price_id
        }],
        proration_behavior: 'create_prorations'
      }
    )

    subscription.update!(
      subscription_plan: new_plan,
      current_period_end: Time.at(stripe_sub.current_period_end)
    )
  end

  def cancel_subscription(subscription)
    return unless subscription.stripe_subscription_id

    Stripe::Subscription.update(
      subscription.stripe_subscription_id,
      { cancel_at_period_end: true }
    )

    subscription.update!(
      cancel_at_period_end: true,
      canceled_at: Time.current
    )
  end

  def reactivate_subscription(subscription)
    return unless subscription.stripe_subscription_id && subscription.cancel_at_period_end

    Stripe::Subscription.update(
      subscription.stripe_subscription_id,
      { cancel_at_period_end: false }
    )

    subscription.update!(
      cancel_at_period_end: false,
      canceled_at: nil
    )
  end

  def add_payment_method(payment_method_id)
    customer_id = create_customer

    payment_method = Stripe::PaymentMethod.attach(
      payment_method_id,
      { customer: customer_id }
    )

    @user.payment_methods.create!(
      stripe_payment_method_id: payment_method.id,
      card_brand: payment_method.card.brand,
      card_last4: payment_method.card.last4,
      card_exp_month: payment_method.card.exp_month,
      card_exp_year: payment_method.card.exp_year,
      default: @user.payment_methods.none?
    )
  end

  def remove_payment_method(payment_method)
    Stripe::PaymentMethod.detach(payment_method.stripe_payment_method_id)
    payment_method.destroy
  end

  def set_default_payment_method(payment_method)
    Stripe::Customer.update(
      @user.stripe_customer_id,
      { invoice_settings: { default_payment_method: payment_method.stripe_payment_method_id } }
    )
    payment_method.update!(default: true)
  end

  def customer_portal_session
    Stripe::BillingPortal::Session.create(
      customer: @user.stripe_customer_id,
      return_url: ENV['STRIPE_PORTAL_RETURN_URL']
    )
  end
end
