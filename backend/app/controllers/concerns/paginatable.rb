# Server-side pagination for list endpoints: parses page / per_page and renders
# the shared { data: [...], meta: { page, per_page, total, total_pages } } envelope.
module Paginatable
  extend ActiveSupport::Concern

  private

  def page_request = PageRequest.from(page: params[:page], per_page: params[:per_page])

  def render_page(relation, serializer:)
    page = Paginator.call(relation, page_request)
    render json: { data: serializer.many(page.records), meta: page.meta }
  end
end
