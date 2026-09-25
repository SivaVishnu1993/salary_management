class SalarySerializer < BaseSerializer
  def as_json
    {
      id: record.id,
      amount_cents: record.amount_cents,
      currency: record.currency,
      effective_date: record.effective_date.iso8601,
      note: record.note,
      recorded_at: record.created_at.iso8601
    }
  end
end
