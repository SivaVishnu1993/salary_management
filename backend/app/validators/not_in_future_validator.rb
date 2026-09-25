# Rejects dates after today (validates :hire_date, not_in_future: true).
class NotInFutureValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank? || value <= Date.current

    record.errors.add(attribute, :in_future)
  end
end
