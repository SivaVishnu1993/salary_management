module Salaries
  # Records a pay change: appends a salary row and refreshes the employee's
  # current-salary cache, in one transaction.
  #
  # Back-dated entries are allowed; the cache always reflects the latest
  # effective_date, not the most recently inserted row. The employee row is locked
  # so concurrent changes cannot leave the cache pointing at a stale salary.
  class Change < ApplicationService
    def initialize(employee:, amount_cents:, effective_date:, note: nil)
      @employee = employee
      @amount_cents = amount_cents
      @effective_date = effective_date
      @note = note
    end

    def call
      Employee.transaction do
        employee.lock!
        salary = Salary.create!(employee:, amount_cents:, effective_date:, note:,
                                currency: Country.currency_for(employee.country))
        refresh_current_salary!
        Result.success(salary)
      end
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.to_hash.except(:employee))
    end

    private

    attr_reader :employee, :amount_cents, :effective_date, :note

    def refresh_current_salary!
      latest = employee.salaries.latest_first.first
      employee.update!(current_salary_cents: latest.amount_cents, current_salary_currency: latest.currency)
    end
  end
end
