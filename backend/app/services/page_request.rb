# A validated page / per_page pair. Anything malformed or out of range falls back
# to safe values, so bad query strings never cause a 500.
PageRequest = Data.define(:page, :per_page) do
  def self.default_per_page = 25

  def self.max_per_page = 100

  def self.from(page:, per_page:)
    new(page: positive_integer(page) || 1,
        per_page: (positive_integer(per_page) || default_per_page).clamp(1, max_per_page))
  end

  def self.positive_integer(value)
    number = Integer(value.to_s, 10, exception: false)
    number if number&.positive?
  end
  private_class_method :positive_integer

  def to_h = { page:, per_page: }
end
