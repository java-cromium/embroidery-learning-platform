require 'money'

# Set the default currency
Money.default_currency = Money::Currency.new('USD')

# Configure the currency to be formatted with the symbol
Money.locale_backend = :i18n

# Configure the default bank
Money.default_bank = Money::Bank::VariableExchange.new(Money::RatesStore::Memory.new)

# Add some exchange rates
Money.add_rate('USD', 'EUR', 0.85)
Money.add_rate('EUR', 'USD', 1.18)
Money.add_rate('USD', 'CAD', 1.25)
Money.add_rate('CAD', 'USD', 0.80)
