module Api
  module V1
    # Pay analytics. Every endpoint accepts optional `country` / `department`
    # filters and serves results through the Redis-backed Insights::Cached.
    class InsightsController < BaseController
      before_action :validate_filters

      # GET /api/v1/insights/summary
      def summary = render_insight(Insights::Summary, **filters)

      # GET /api/v1/insights/by_country
      def by_country = render_insight(Insights::ByCountry, **filters)

      # GET /api/v1/insights/by_department
      def by_department = render_insight(Insights::ByDepartment, **filters)

      # GET /api/v1/insights/job_titles?country=IN
      def job_titles
        params.require(:country)
        render_insight(Insights::JobTitles, **filters)
      end

      # GET /api/v1/insights/outliers?threshold_pct=20
      def outliers
        result = Insights::Cached.new(Insights::Outliers).call(
          **filters, threshold_pct: Insights::Outliers.threshold_from(params[:threshold_pct]), **page_request.to_h
        )
        render json: { data: result.except(:meta), meta: result[:meta] }
      end

      private

      def filters
        { country: params[:country].presence&.upcase, department: params[:department].presence }
      end

      def render_insight(insight, **params)
        render json: { data: Insights::Cached.new(insight).call(**params) }
      end

      def validate_filters
        if filters[:country] && Country.find(filters[:country]).nil?
          render_invalid_parameter("Unknown country: #{filters[:country]}")
        elsif filters[:department] && Department.find(filters[:department]).nil?
          render_invalid_parameter("Unknown department: #{filters[:department]}")
        end
      end
    end
  end
end
