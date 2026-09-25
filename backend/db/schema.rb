# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_25_000005) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "employees", force: :cascade do |t|
    t.virtual "employee_code", type: :string, as: "('ACME-'::text || lpad((id)::text, 6, '0'::text))", stored: true
    t.string "first_name", limit: 100, null: false
    t.string "last_name", limit: 100, null: false
    t.string "email", limit: 255, null: false
    t.string "job_title", limit: 100, null: false
    t.string "department", limit: 100, null: false
    t.string "country", limit: 2, null: false
    t.date "hire_date", null: false
    t.bigint "current_salary_cents", null: false
    t.string "current_salary_currency", limit: 3, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((((((((first_name)::text || ' '::text) || (last_name)::text) || ' '::text) || (email)::text) || ' '::text) || (employee_code)::text)) gin_trgm_ops", name: "index_employees_on_search_document", using: :gin
    t.index ["country", "department"], name: "index_employees_on_country_and_department"
    t.index ["country", "job_title", "current_salary_cents"], name: "index_employees_on_country_job_title_salary"
    t.index ["department"], name: "index_employees_on_department"
    t.index ["email"], name: "index_employees_on_email", unique: true
    t.index ["employee_code"], name: "index_employees_on_employee_code", unique: true
    t.index ["hire_date"], name: "index_employees_on_hire_date"
    t.index ["job_title"], name: "index_employees_on_job_title"
    t.index ["last_name", "first_name", "id"], name: "index_employees_on_last_name_and_first_name_and_id"
    t.check_constraint "current_salary_cents > 0", name: "employees_current_salary_positive"
    t.check_constraint "current_salary_currency::text ~ '^[A-Z]{3}$'::text", name: "employees_currency_iso_format"
  end

  create_table "fx_rates", primary_key: "currency", id: { type: :string, limit: 3 }, force: :cascade do |t|
    t.decimal "usd_per_unit", precision: 18, scale: 8, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "currency::text ~ '^[A-Z]{3}$'::text", name: "fx_rates_currency_iso_format"
    t.check_constraint "usd_per_unit > 0::numeric", name: "fx_rates_usd_per_unit_positive"
  end

  create_table "salaries", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.bigint "amount_cents", null: false
    t.string "currency", limit: 3, null: false
    t.date "effective_date", null: false
    t.string "note", limit: 500
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "effective_date"], name: "index_salaries_on_employee_id_and_effective_date", unique: true, order: { effective_date: :desc }
    t.check_constraint "amount_cents > 0", name: "salaries_amount_positive"
    t.check_constraint "currency::text ~ '^[A-Z]{3}$'::text", name: "salaries_currency_iso_format"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.string "email", limit: 255, null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "salaries", "employees", on_delete: :cascade
end
