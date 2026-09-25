# Measures API latency and query plans against the seeded dataset and prints a
# Markdown report (used for docs/PERFORMANCE.md).
#
#   bin/rails db:seed && bin/rails runner script/perf_report.rb
ITERATIONS = 20

# Plans are collected before any HTTP request: in development, integration
# requests reset the runner's execution context that query log tags rely on.
conn = ActiveRecord::Base.connection
plan_queries = {
  "Directory: filtered + searched + sorted" =>
    EmployeesQuery.call({ country: "US", department: "Engineering", q: "smi", sort: "salary_usd", direction: "desc" }).limit(25),
  "Directory: default sort, page 1" => EmployeesQuery.call({}).limit(25),
  "Search only" => Employee.search("kumar").limit(25),
  "Job titles in one country" =>
    Employee.in_country("IN").group(:job_title).select(:job_title, Arel.sql(Insights::Base::MEDIAN_LOCAL_SQL)),
  "Salary history for one employee" => Salary.where(employee_id: Employee.maximum(:id)).latest_first.limit(25)
}
plans = plan_queries.transform_values do |relation|
  conn.select_rows("EXPLAIN (ANALYZE, COSTS OFF) #{relation.to_sql}").flatten
end
dataset = "#{Employee.count} employees, #{Salary.count} salary rows"
last_employee_id = Employee.maximum(:id)

session = ActionDispatch::Integration::Session.new(Rails.application)
session.host = "localhost"
user = User.first || abort("Seed the database first (bin/rails db:seed)")
headers = { "Authorization" => "Bearer #{Auth::JsonWebToken.new.encode(subject: user.id).value}" }

def median_ms(samples) = (samples.sort[samples.size / 2] * 1000).round(1)

def time_request(session, path, headers)
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  session.get(path, headers:)
  raise "#{path} -> #{session.response.status}" unless session.response.successful?

  Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
end

endpoints = {
  "Directory, page 1 (default sort)" => [ "/api/v1/employees", false ],
  "Directory, filtered + searched + sorted by USD" =>
    [ "/api/v1/employees?country=US&department=Engineering&q=smi&sort=salary_usd&direction=desc&page=2", false ],
  "Directory, deep page (page 300)" => [ "/api/v1/employees?page=300", false ],
  "Employee detail" => [ "/api/v1/employees/#{last_employee_id}", false ],
  "Insights summary" => [ "/api/v1/insights/summary", true ],
  "Insights by country" => [ "/api/v1/insights/by_country", true ],
  "Insights by department" => [ "/api/v1/insights/by_department", true ],
  "Insights job titles (IN)" => [ "/api/v1/insights/job_titles?country=IN", true ],
  "Outliers (20%)" => [ "/api/v1/insights/outliers?threshold_pct=20", true ]
}

puts "Dataset: #{dataset}. Median of #{ITERATIONS} requests, in-process (no network)."
puts
puts "| Endpoint | Uncached (ms) | Cached (ms) |"
puts "|---|---:|---:|"
endpoints.each do |label, (path, cacheable)|
  time_request(session, path, headers) # warm-up
  uncached = Array.new(ITERATIONS) do
    Insights::CacheVersion.bump!
    time_request(session, path, headers)
  end
  cached = cacheable ? Array.new(ITERATIONS) { time_request(session, path, headers) } : nil
  puts "| #{label} | #{median_ms(uncached)} | #{cached ? median_ms(cached) : 'not cached'} |"
end

plans.each do |label, plan|
  puts
  puts "### #{label}"
  puts
  puts "```"
  puts plan
  puts "```"
end
