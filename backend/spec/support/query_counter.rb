# Counts SQL statements executed by a block (ignoring schema/transaction noise),
# so specs can prove a list endpoint's query count doesn't grow with its rows.
module QueryCounter
  IGNORED = %w[SCHEMA TRANSACTION].freeze

  def count_queries(&)
    count = 0
    counter = lambda do |*, payload|
      count += 1 unless IGNORED.include?(payload[:name]) || payload[:cached]
    end
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    count
  end
end

RSpec.configure do |config|
  config.include QueryCounter
end
