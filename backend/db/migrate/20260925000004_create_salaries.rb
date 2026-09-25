class CreateSalaries < ActiveRecord::Migration[8.1]
  def change
    # Append-only salary history: the source of truth and audit trail for pay.
    create_table :salaries do |t|
      t.references :employee, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.bigint :amount_cents, null: false
      t.string :currency, null: false, limit: 3
      t.date :effective_date, null: false
      t.string :note, limit: 500
      t.timestamps
    end

    add_check_constraint :salaries, "amount_cents > 0", name: "salaries_amount_positive"
    add_check_constraint :salaries, "currency ~ '^[A-Z]{3}$'", name: "salaries_currency_iso_format"

    # One change per employee per day; also serves "history newest first" and the
    # latest-salary lookup for an employee (employee_id = ? ORDER BY effective_date DESC).
    add_index :salaries, %i[employee_id effective_date], unique: true, order: { effective_date: :desc }
  end
end
