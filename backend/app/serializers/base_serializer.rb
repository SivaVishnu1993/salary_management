# Plain-Ruby serializers: each subclass maps one record to a JSON-ready hash.
class BaseSerializer
  def self.one(record) = new(record).as_json

  def self.many(records) = records.map { |record| one(record) }

  def initialize(record)
    @record = record
  end

  def as_json = raise(NotImplementedError, "#{self.class} must implement #as_json")

  private

  attr_reader :record
end
