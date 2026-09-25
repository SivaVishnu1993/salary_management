class CreateFxRates < ActiveRecord::Migration[8.1]
  def change
    # Tiny lookup table (one row per currency) joined by aggregate queries so
    # USD conversion happens in SQL. Natural key: the ISO 4217 code.
    create_table :fx_rates, id: false do |t|
      t.string :currency, limit: 3, null: false, primary_key: true
      t.decimal :usd_per_unit, precision: 18, scale: 8, null: false
      t.timestamps
    end

    add_check_constraint :fx_rates, "usd_per_unit > 0", name: "fx_rates_usd_per_unit_positive"
    add_check_constraint :fx_rates, "currency ~ '^[A-Z]{3}$'", name: "fx_rates_currency_iso_format"
  end
end
