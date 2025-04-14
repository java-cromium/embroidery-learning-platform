class App < Sinatra::Base
  # Pricing page
  get '/pricing' do
    @plans = SubscriptionPlan.where(active: true).order(price_cents: :asc)
    erb :'subscriptions/pricing'
  end

  # Subscription management
  get '/account/subscription' do
    require_authentication
    @subscription = current_user.current_subscription
    @payment_methods = current_user.payment_methods
    erb :'subscriptions/show'
  end

  # Subscribe to a plan
  get '/subscribe/:plan_id' do
    require_authentication
    @plan = SubscriptionPlan.find(params[:plan_id])
    erb :'subscriptions/new'
  end

  post '/subscribe/:plan_id' do
    require_authentication
    @plan = SubscriptionPlan.find(params[:plan_id])

    begin
      stripe_service = StripeService.new(current_user)
      subscription = stripe_service.create_subscription(@plan, params[:payment_method_id])

      if subscription.status == 'active'
        flash[:success] = "Successfully subscribed to #{@plan.name}"
        redirect '/account/subscription'
      else
        client_secret = subscription.latest_invoice.payment_intent.client_secret
        erb :'subscriptions/confirm_payment', locals: { client_secret: client_secret }
      end
    rescue Stripe::CardError => e
      flash[:error] = e.message
      redirect "/subscribe/#{@plan.id}"
    end
  end

  # Cancel subscription
  post '/subscription/cancel' do
    require_authentication
    subscription = current_user.current_subscription

    if subscription&.cancel
      flash[:success] = "Your subscription has been canceled"
    else
      flash[:error] = "Unable to cancel subscription"
    end

    redirect '/account/subscription'
  end

  # Reactivate canceled subscription
  post '/subscription/reactivate' do
    require_authentication
    subscription = current_user.current_subscription

    if subscription&.reactivate
      flash[:success] = "Your subscription has been reactivated"
    else
      flash[:error] = "Unable to reactivate subscription"
    end

    redirect '/account/subscription'
  end

  # Change subscription plan
  post '/subscription/change_plan/:plan_id' do
    require_authentication
    new_plan = SubscriptionPlan.find(params[:plan_id])
    subscription = current_user.current_subscription

    begin
      stripe_service = StripeService.new(current_user)
      stripe_service.update_subscription(subscription, new_plan)
      flash[:success] = "Successfully changed to #{new_plan.name} plan"
    rescue => e
      flash[:error] = "Unable to change plan: #{e.message}"
    end

    redirect '/account/subscription'
  end

  # Payment methods
  post '/payment_methods' do
    require_authentication
    begin
      stripe_service = StripeService.new(current_user)
      stripe_service.add_payment_method(params[:payment_method_id])
      flash[:success] = "Payment method added successfully"
    rescue => e
      flash[:error] = "Unable to add payment method: #{e.message}"
    end

    redirect '/account/subscription'
  end

  delete '/payment_methods/:id' do
    require_authentication
    payment_method = current_user.payment_methods.find(params[:id])
    
    begin
      stripe_service = StripeService.new(current_user)
      stripe_service.remove_payment_method(payment_method)
      flash[:success] = "Payment method removed successfully"
    rescue => e
      flash[:error] = "Unable to remove payment method: #{e.message}"
    end

    redirect '/account/subscription'
  end

  post '/payment_methods/:id/default' do
    require_authentication
    payment_method = current_user.payment_methods.find(params[:id])
    
    begin
      stripe_service = StripeService.new(current_user)
      stripe_service.set_default_payment_method(payment_method)
      flash[:success] = "Default payment method updated"
    rescue => e
      flash[:error] = "Unable to update default payment method: #{e.message}"
    end

    redirect '/account/subscription'
  end

  # Stripe webhook
  post '/stripe/webhook' do
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    
    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, ENV['STRIPE_WEBHOOK_SECRET']
      )

      case event.type
      when 'customer.subscription.updated'
        subscription = event.data.object
        local_subscription = Subscription.find_by(stripe_subscription_id: subscription.id)
        
        if local_subscription
          local_subscription.update(
            status: subscription.status,
            current_period_end: Time.at(subscription.current_period_end),
            cancel_at_period_end: subscription.cancel_at_period_end
          )
        end

      when 'customer.subscription.deleted'
        subscription = event.data.object
        local_subscription = Subscription.find_by(stripe_subscription_id: subscription.id)
        
        if local_subscription
          local_subscription.update(status: 'canceled')
        end

      when 'invoice.payment_failed'
        invoice = event.data.object
        subscription = Subscription.find_by(stripe_subscription_id: invoice.subscription)
        
        if subscription
          subscription.update(status: 'past_due')
        end
      end

      status 200
    rescue JSON::ParserError => e
      status 400
      body "Invalid payload"
    rescue Stripe::SignatureVerificationError => e
      status 400
      body "Invalid signature"
    end
  end

  # Stripe customer portal
  get '/billing-portal' do
    require_authentication
    
    begin
      stripe_service = StripeService.new(current_user)
      session = stripe_service.customer_portal_session
      redirect session.url
    rescue => e
      flash[:error] = "Unable to access billing portal"
      redirect '/account/subscription'
    end
  end
end
