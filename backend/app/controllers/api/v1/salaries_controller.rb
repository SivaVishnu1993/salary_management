module Api
  module V1
    # Salary history for one employee (newest first) and recording pay changes.
    class SalariesController < BaseController
      before_action :set_employee

      # GET /api/v1/employees/:employee_id/salaries
      def index
        render_page(@employee.salaries.latest_first, serializer: SalarySerializer)
      end

      # POST /api/v1/employees/:employee_id/salaries
      def create
        attributes = params.expect(salary: %i[amount_cents effective_date note])
        result = Salaries::Change.call(employee: @employee, amount_cents: attributes[:amount_cents],
                                       effective_date: attributes[:effective_date], note: attributes[:note])
        return render_validation_errors(result.error) if result.failure?

        render json: { data: SalarySerializer.one(result.value) }, status: :created
      end

      private

      def set_employee
        @employee = Employee.find(params[:employee_id])
      end
    end
  end
end
