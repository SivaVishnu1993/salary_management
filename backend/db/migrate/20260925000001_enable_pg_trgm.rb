class EnablePgTrgm < ActiveRecord::Migration[8.1]
  # Trigram GIN index makes the directory's substring search (ILIKE '%term%') indexable.
  def change
    enable_extension "pg_trgm"
  end
end
