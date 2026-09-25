# Exposes a <name>_cents / currency column pair as a Money value object.
#
#   monetize :current_salary                     # current_salary_cents + current_salary_currency
#   monetize :amount, currency_column: :currency # amount_cents + currency
module Monetizable
  extend ActiveSupport::Concern

  class_methods do
    def monetize(name, cents_column: :"#{name}_cents", currency_column: :"#{name}_currency")
      define_method(name) do
        cents = public_send(cents_column)
        Money.new(cents:, currency: public_send(currency_column)) unless cents.nil?
      end
    end
  end
end
