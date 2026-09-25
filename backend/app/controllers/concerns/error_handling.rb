# Renders every error as { error: { code, message, details? } } so the client
# handles failures uniformly.
module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
  end

  private

  def render_error(status:, code:, message:, details: nil)
    render json: { error: { code:, message:, details: }.compact }, status:
  end

  def render_unauthorized(message = "Authentication required")
    render_error(status: :unauthorized, code: "unauthorized", message:)
  end

  # `errors` is ActiveModel::Errors or a { field => [messages] } hash.
  def render_validation_errors(errors)
    render_error(status: :unprocessable_content, code: "validation_failed",
                 message: "Validation failed", details: errors.to_hash)
  end

  def render_invalid_parameter(message)
    render_error(status: :unprocessable_content, code: "invalid_parameter", message:)
  end

  def render_not_found(exception)
    render_error(status: :not_found, code: "not_found", message: "#{exception.model || 'Record'} not found")
  end

  def render_parameter_missing(exception)
    render_error(status: :bad_request, code: "parameter_missing", message: exception.message.lines.first.strip)
  end
end
