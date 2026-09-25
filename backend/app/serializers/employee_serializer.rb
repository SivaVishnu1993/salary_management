class EmployeeSerializer < BaseSerializer
  def as_json
    {
      id: record.id,
      employee_code: record.employee_code,
      first_name: record.first_name,
      last_name: record.last_name,
      full_name: record.full_name,
      email: record.email,
      department: record.department,
      job_title: record.job_title,
      country: record.country,
      country_name: Country.find(record.country)&.name,
      hire_date: record.hire_date.iso8601,
      current_salary: { amount_cents: record.current_salary_cents, currency: record.current_salary_currency },
      current_salary_usd_cents: record.current_salary_usd_cents&.to_i,
      updated_at: record.updated_at.iso8601
    }
  end
end
