module Employees
  # Hires an employee together with their starting salary, atomically: an
  # employee never exists without a salary record.
  #
  #   Employees::Create.call(attributes: { first_name: ..., country: "IN", ... },
  #                          salary: { amount_cents: 1_800_000_00, effective_date: "2026-01-05" })
  class Create < ApplicationService
    def initialize(attributes:, salary:)
      @attributes = attributes.to_h.symbolize_keys
      @salary_attributes = salary.to_h.symbolize_keys
    end

    def call
      employee = Employee.new(attributes)
      salary = build_salary(employee)
      employee.assign_attributes(current_salary_cents: salary.amount_cents, current_salary_currency: salary.currency)

      errors = validation_errors(employee, salary)
      return Result.failure(errors) if errors.any?

      Employee.transaction { employee.save! }
      Result.success(employee)
    end

    private

    attr_reader :attributes, :salary_attributes

    def build_salary(employee)
      employee.salaries.build(
        amount_cents: salary_attributes[:amount_cents],
        effective_date: salary_attributes[:effective_date].presence || employee.hire_date,
        note: salary_attributes[:note],
        currency: Country.currency_for(employee.country)
      )
    end

    # Employee errors plus salary errors under "salary.<field>". The employee's
    # salary cache mirrors the salary record, so its errors would only duplicate.
    def validation_errors(employee, salary)
      employee.validate
      salary.validate

      employee_errors = employee.errors.to_hash.reject { |field, _| field.to_s.start_with?("current_salary", "salaries") }
      salary_errors = salary.errors.to_hash.except(:employee).transform_keys { |field| :"salary.#{field}" }
      employee_errors.merge(salary_errors)
    end
  end
end
