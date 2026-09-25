require "rails_helper"

RSpec.describe Seeds::People do
  subject(:people) { described_class.new(rng: Random.new(42)) }

  it "builds names from the country's pool" do
    person = people.build("IN")
    pool = YAML.load_file(described_class::NAMES_PATH).fetch("IN")

    expect(pool["first"]).to include(person.first_name)
    expect(pool["last"]).to include(person.last_name)
  end

  it "transliterates accented names into ASCII emails" do
    germans = Array.new(300) { people.build("DE") }
    muller = germans.find { |person| person.last_name == "Müller" }

    expect(germans.map(&:email)).to all(match(/\A[a-z.]+\d*@acme\.test\z/))
    expect(muller.email).to start_with("#{muller.first_name.downcase}.muller")
  end

  it "never repeats an email" do
    emails = Array.new(2_000) { people.build("US").email }

    expect(emails.uniq.size).to eq(emails.size)
  end
end
