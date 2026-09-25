module Seeds
  # Generates plausible, unique employee identities per country.
  class People
    NAMES_PATH = Rails.root.join("lib/seeds/names.yml")
    EMAIL_DOMAIN = "acme.test".freeze

    Person = Data.define(:first_name, :last_name, :email)

    def initialize(rng:)
      @rng = rng
      @names = YAML.load_file(NAMES_PATH)
      @email_counts = Hash.new(0)
    end

    def build(country)
      pool = names.fetch(country)
      first_name = pool.fetch("first").sample(random: rng)
      last_name = pool.fetch("last").sample(random: rng)

      Person.new(first_name:, last_name:, email: unique_email(first_name, last_name))
    end

    private

    attr_reader :rng, :names, :email_counts

    # "José Müller" -> "jose.muller@acme.test"; repeats get a numeric suffix.
    def unique_email(first_name, last_name)
      local = "#{first_name}.#{last_name}".unicode_normalize(:nfkd).downcase.gsub(/[^a-z.]/, "")
      count = email_counts[local] += 1
      "#{local}#{count if count > 1}@#{EMAIL_DOMAIN}"
    end
  end
end
