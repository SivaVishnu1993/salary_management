# Offset pagination over any relation: one COUNT plus one LIMIT/OFFSET query.
class Paginator < ApplicationService
  Page = Data.define(:records, :meta)

  def initialize(relation, page_request)
    @relation = relation
    @page_request = page_request
  end

  def call
    pagy = Pagy.new(count: relation.count(:all), page: page_request.page, limit: page_request.per_page)
    records = relation.offset(pagy.offset).limit(pagy.limit)

    Page.new(records:, meta: { page: pagy.page, per_page: pagy.limit, total: pagy.count, total_pages: pagy.pages })
  end

  private

  attr_reader :relation, :page_request
end
