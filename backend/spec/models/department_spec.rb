require "rails_helper"

RSpec.describe Department do
  describe ".names" do
    it "lists every department from the org structure" do
      expect(described_class.names).to contain_exactly(
        "Engineering", "Product", "Design", "Sales", "Marketing", "Finance", "HR", "Operations"
      )
    end
  end

  describe ".find" do
    it "returns the department with its ordered job ladder" do
      engineering = described_class.find("Engineering")

      expect(engineering.job_titles.first).to eq(JobTitle.new(name: "Software Engineer I", level: 1))
    end

    it "returns nil for an unknown department" do
      expect(described_class.find("Legal")).to be_nil
    end
  end

  describe "#job_title?" do
    subject(:engineering) { described_class.find("Engineering") }

    it "is true for a title on the department's ladder" do
      expect(engineering.job_title?("Staff Software Engineer")).to be(true)
    end

    it "is false for another department's title" do
      expect(engineering.job_title?("Account Executive")).to be(false)
    end
  end

  describe ".for_job_title" do
    it "finds the department owning a title" do
      expect(described_class.for_job_title("Account Executive").name).to eq("Sales")
    end

    it "returns nil for an unknown title" do
      expect(described_class.for_job_title("Astronaut")).to be_nil
    end
  end

  describe "#job_title" do
    it "returns the rung for a title" do
      expect(described_class.find("HR").job_title("HR Manager")).to eq(JobTitle.new(name: "HR Manager", level: 4))
    end
  end

  it "keeps job titles unique across departments so stats group unambiguously" do
    titles = described_class.all.flat_map { |department| department.job_titles.map(&:name) }

    expect(titles).to eq(titles.uniq)
  end
end
