# Base for service objects: one public entry point, `.call`, forwarding to #call.
class ApplicationService
  def self.call(...) = new(...).call
end
