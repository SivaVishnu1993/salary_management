# Department and its closed list of job titles (config/org_structure.yml).
Department = Data.define(:name, :job_titles) do
  def self.all = registry.values

  def self.names = registry.keys

  def self.find(name) = registry[name]

  # Job titles are unique across departments (asserted in department_spec).
  def self.for_job_title(title) = all.find { |department| department.job_title?(title) }

  def self.registry
    @registry ||= YAML.load_file(Rails.root.join("config/org_structure.yml")).to_h do |name, ladder|
      titles = ladder.map { |rung| JobTitle.new(name: rung.fetch("title"), level: rung.fetch("level")) }
      [ name, new(name:, job_titles: titles.freeze) ]
    end.freeze
  end
  private_class_method :registry

  def job_title?(title) = job_titles.any? { |job_title| job_title.name == title }

  def job_title(title) = job_titles.find { |job_title| job_title.name == title }
end
