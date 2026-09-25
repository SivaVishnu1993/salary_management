module Insights
  # Employees paid more than `threshold_pct` above or below the median for their
  # peer group: same country AND same job title. Peers share a currency, so the
  # comparison needs no FX conversion. Groups smaller than MIN_PEERS are skipped
  # because a median of two or three people is not a meaningful benchmark.
  class Outliers < Base
    DEFAULT_THRESHOLD_PCT = 20
    THRESHOLD_RANGE = (1..200)
    MIN_PEERS = 5

    DEVIATION_SQL = "(employees.current_salary_cents - peers.median_cents) / peers.median_cents * 100".freeze
    PEERS_JOIN = "INNER JOIN peers ON peers.country = employees.country AND peers.job_title = employees.job_title".freeze

    def self.threshold_from(value)
      number = Float(value.to_s, exception: false)
      number ? number.clamp(THRESHOLD_RANGE.min, THRESHOLD_RANGE.max) : DEFAULT_THRESHOLD_PCT
    end

    def initialize(threshold_pct: DEFAULT_THRESHOLD_PCT, page: 1, per_page: PageRequest.default_per_page, **filters)
      super(**filters)
      @threshold_pct = threshold_pct
      @page_request = PageRequest.from(page:, per_page:)
    end

    def call
      page = Paginator.call(outliers, page_request)
      { threshold_pct:, min_peers: MIN_PEERS, rows: page.records.map { |row| present(row) }, meta: page.meta }
    end

    private

    attr_reader :threshold_pct, :page_request

    def peers
      employees.group(:country, :job_title).having("COUNT(*) >= ?", MIN_PEERS).select(
        :country, :job_title, "COUNT(*) AS peer_count",
        "percentile_cont(0.5) WITHIN GROUP (ORDER BY current_salary_cents) AS median_cents"
      )
    end

    def outliers
      employees.with(peers:).joins(PEERS_JOIN)
        .where("ABS(#{DEVIATION_SQL}) > ?", threshold_pct)
        .select(:id, :employee_code, :first_name, :last_name, :department, :job_title, :country,
                :current_salary_cents, :current_salary_currency,
                "peers.median_cents", "peers.peer_count", "#{DEVIATION_SQL} AS deviation_pct")
        .order(Arel.sql("ABS(#{DEVIATION_SQL}) DESC"), :id)
    end

    def present(row)
      {
        employee_id: row.id, employee_code: row.employee_code, full_name: row.full_name,
        department: row.department, job_title: row.job_title, country: row.country,
        salary_cents: row.current_salary_cents, currency: row.current_salary_currency,
        peer_median_cents: cents(row[:median_cents]), peer_count: row[:peer_count],
        deviation_pct: row[:deviation_pct].to_f.round(1)
      }
    end
  end
end
