class Employee < ApplicationRecord
  include Monetizable
  include InvalidatesInsightsCache

  NAME_MAX_LENGTH = 100
  EMAIL_MAX_LENGTH = 255
  # Lower-cased text Employee.search matches against. Must stay identical to the
  # expression in index_employees_on_search_document or the trigram index is skipped.
  SEARCH_DOCUMENT_SQL = "lower(first_name || ' ' || last_name || ' ' || email || ' ' || employee_code)".freeze
  # Current salary in USD minor units, computed in SQL. Requires fx_rates to be joined.
  SALARY_USD_CENTS_SQL = "ROUND(employees.current_salary_cents * fx_rates.usd_per_unit)".freeze

  has_many :salaries, dependent: :delete_all, inverse_of: :employee
  # Rate for the employee's pay currency; lets directory queries compute USD in SQL.
  belongs_to :fx_rate, foreign_key: :current_salary_currency, primary_key: :currency,
                       optional: true, inverse_of: false

  monetize :current_salary

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :first_name, :last_name, :job_title, :department, with: ->(value) { value.squish }
  normalizes :country, :current_salary_currency, with: ->(code) { code.strip.upcase }

  validates :first_name, :last_name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :email, presence: true, length: { maximum: EMAIL_MAX_LENGTH },
                    format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
  validates :country, presence: true, inclusion: { in: ->(_) { Country.codes }, allow_blank: true }
  validates :department, presence: true, inclusion: { in: ->(_) { Department.names }, allow_blank: true }
  validates :job_title, presence: true
  validate :job_title_belongs_to_department
  validates :hire_date, presence: true, not_in_future: true
  validates :current_salary_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :current_salary_currency, presence: true, currency_matches_country: { country: :country }

  # Filter scopes return `all` for blank input so callers can chain them unconditionally.
  scope :in_country, ->(code) { where(country: code.to_s.upcase) if code.present? }
  scope :in_department, ->(name) { where(department: name) if name.present? }
  scope :with_job_title, ->(title) { where(job_title: title) if title.present? }
  scope :search, lambda { |term|
    next if term.blank?

    where("#{SEARCH_DOCUMENT_SQL} LIKE ?", "%#{sanitize_sql_like(term.squish.downcase)}%")
  }
  # Adds a current_salary_usd_cents attribute. LEFT JOIN so an employee is never
  # hidden from the directory by a missing rate (their USD value is just nil).
  scope :with_usd_salary, lambda {
    left_joins(:fx_rate).select(arel_table[Arel.star], Arel.sql("#{SALARY_USD_CENTS_SQL} AS current_salary_usd_cents"))
  }

  def full_name = "#{first_name} #{last_name}"

  # Present only on records loaded through .with_usd_salary.
  def current_salary_usd_cents = (self[:current_salary_usd_cents] if has_attribute?(:current_salary_usd_cents))

  private

  def job_title_belongs_to_department
    department_record = Department.find(department)
    return if department_record.nil? || department_record.job_title?(job_title)

    errors.add(:job_title, :not_in_department, department:)
  end
end
