module Api
  module V1
    # Reference data for filters and forms. Served from config (no DB queries),
    # so it needs no caching beyond the client's.
    class MetaController < BaseController
      # GET /api/v1/meta/filters
      def filters
        fx = FxRates::Config.current
        render json: {
          data: {
            countries: Country.all.map(&:to_h),
            departments: Department.all.map { |d| { name: d.name, job_titles: d.job_titles.map(&:to_h) } },
            fx: { version: fx.version, as_of: fx.as_of.iso8601 }
          }
        }
      end
    end
  end
end
