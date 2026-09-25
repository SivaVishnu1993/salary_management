# Ensures a currency is the one used in the record's country.
#
#   validates :currency, currency_matches_country: { country: :employee_country }
#
# `country:` names the method returning the ISO country code to check against.
# Blank or unsupported countries are skipped: the country validation reports those.
class CurrencyMatchesCountryValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    expected = Country.currency_for(record.public_send(options.fetch(:country)))
    return if expected.nil? || value == expected

    record.errors.add(attribute, :currency_mismatch, expected:)
  end
end
