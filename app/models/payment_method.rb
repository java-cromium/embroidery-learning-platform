class PaymentMethod < ActiveRecord::Base
  belongs_to :user

  validates :stripe_payment_method_id, presence: true, uniqueness: true
  validates :card_brand, presence: true
  validates :card_last4, presence: true
  validates :card_exp_month, presence: true, numericality: { only_integer: true, greater_than: 0, less_than: 13 }
  validates :card_exp_year, presence: true, numericality: { only_integer: true }

  before_save :ensure_single_default, if: :default?

  def expired?
    today = Date.today
    exp_date = Date.new(card_exp_year, card_exp_month, 1).end_of_month
    exp_date < today
  end

  def expiring_soon?
    today = Date.today
    exp_date = Date.new(card_exp_year, card_exp_month, 1).end_of_month
    exp_date < today + 1.month
  end

  def card_display
    "#{card_brand} ending in #{card_last4}"
  end

  def expiration_display
    "#{card_exp_month}/#{card_exp_year}"
  end

  private

  def ensure_single_default
    return unless default?
    user.payment_methods.where.not(id: id).update_all(default: false)
  end
end
