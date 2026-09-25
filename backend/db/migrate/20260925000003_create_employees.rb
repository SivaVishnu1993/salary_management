class CreateEmployees < ActiveRecord::Migration[8.1]
  SEARCH_DOCUMENT = "lower(first_name || ' ' || last_name || ' ' || email || ' ' || employee_code)".freeze

  def change
    create_table :employees do |t|
      # Human-facing ID derived from the primary key: always unique, never typed by hand.
      t.virtual :employee_code, type: :string, as: "'ACME-' || lpad(id::text, 6, '0')", stored: true
      t.string :first_name, null: false, limit: 100
      t.string :last_name, null: false, limit: 100
      t.string :email, null: false, limit: 255
      t.string :job_title, null: false, limit: 100
      t.string :department, null: false, limit: 100
      t.string :country, null: false, limit: 2
      t.date :hire_date, null: false
      # Denormalized copy of the latest salaries row, written only by Salaries::Change.
      # Lets the directory and aggregates avoid a lateral join onto salary history.
      t.bigint :current_salary_cents, null: false
      t.string :current_salary_currency, null: false, limit: 3
      t.timestamps
    end

    add_check_constraint :employees, "current_salary_cents > 0", name: "employees_current_salary_positive"
    add_check_constraint :employees, "current_salary_currency ~ '^[A-Z]{3}$'", name: "employees_currency_iso_format"

    # Uniqueness + direct lookup.
    add_index :employees, :email, unique: true
    add_index :employees, :employee_code, unique: true
    # Directory filter by country (+ department); by-department insight filtered by country.
    add_index :employees, %i[country department]
    # Job-title stats and outlier medians group by (country, job_title) over salary:
    # covering index lets Postgres answer those aggregates from the index alone.
    add_index :employees, %i[country job_title current_salary_cents], name: "index_employees_on_country_job_title_salary"
    # Department / job title filters and GROUP BYs used without a country.
    add_index :employees, :department
    add_index :employees, :job_title
    # Default name sort; id tie-breaker keeps pagination order stable.
    add_index :employees, %i[last_name first_name id]
    # Hire-date sort.
    add_index :employees, :hire_date
    # Substring search across name, email and code (Employee.search).
    # (opclass is part of the expression: Rails' `opclass:` option only applies to named columns.)
    add_index :employees, "(#{SEARCH_DOCUMENT}) gin_trgm_ops", using: :gin, name: "index_employees_on_search_document"
  end
end
