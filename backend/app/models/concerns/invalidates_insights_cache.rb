# Any committed change to the including model invalidates cached insights.
# after_commit (not after_save) so a rolled-back write never bumps the version,
# and readers never cache data from an uncommitted transaction.
module InvalidatesInsightsCache
  extend ActiveSupport::Concern

  included do
    after_commit { Insights::CacheVersion.bump! }
  end
end
