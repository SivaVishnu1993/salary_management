# Supported country (reference data from config/countries.yml).
# A country fixes the pay currency: every employee in DE is paid in EUR.
Country = Data.define(:code, :name, :currency) do
  def self.all = registry.values

  def self.codes = registry.keys

  def self.find(code) = registry[code.to_s.upcase]

  def self.currency_for(code) = find(code)&.currency

  def self.registry
    @registry ||= YAML.load_file(Rails.root.join("config/countries.yml")).to_h do |code, attrs|
      [ code, new(code:, name: attrs.fetch("name"), currency: attrs.fetch("currency")) ]
    end.freeze
  end
  private_class_method :registry
end
