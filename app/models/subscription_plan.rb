class SubscriptionPlan < ActiveRecord::Base
  has_many :subscriptions
  has_many :users, through: :subscriptions

  validates :name, presence: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :billing_interval, inclusion: { in: ['monthly', 'yearly'] }

  def price
    Money.new(price_cents, 'USD')
  end

  def price=(amount)
    self.price_cents = amount.to_money.cents
  end

  def self.default_plan
    find_by(name: 'Basic')
  end

  def premium?
    price_cents > 0
  end

  def monthly_price
    return price if billing_interval == 'monthly'
    price / 12
  end

  def yearly_price
    return price * 12 if billing_interval == 'monthly'
    price
  end

  def feature_list
    features.fetch('included', [])
  end

  def has_feature?(feature_name)
    feature_list.include?(feature_name)
  end
end
