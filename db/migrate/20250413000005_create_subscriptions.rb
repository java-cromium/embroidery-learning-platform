class CreateSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :subscription_plans do |t|
      t.string :name, null: false
      t.text :description
      t.integer :price_cents, null: false, default: 0
      t.string :price_currency, null: false, default: 'USD'
      t.string :billing_interval, null: false # monthly, yearly
      t.jsonb :features, default: {}
      t.boolean :active, default: true
      t.string :stripe_price_id
      t.timestamps
    end

    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :subscription_plan, null: false, foreign_key: true
      t.string :status, null: false # active, canceled, past_due
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :canceled_at
      t.boolean :cancel_at_period_end, default: false
      t.string :stripe_subscription_id
      t.string :stripe_customer_id
      t.timestamps
    end

    create_table :payment_methods do |t|
      t.references :user, null: false, foreign_key: true
      t.string :stripe_payment_method_id
      t.string :card_brand
      t.string :card_last4
      t.integer :card_exp_month
      t.integer :card_exp_year
      t.boolean :default, default: false
      t.timestamps
    end

    add_column :users, :stripe_customer_id, :string
    add_column :users, :premium, :boolean, default: false
  end
end
