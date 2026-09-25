module Api
  module V1
    class EmployeesController < BaseController
      PROFILE_FIELDS = %i[first_name last_name email department job_title country hire_date].freeze
      SALARY_FIELDS = %i[amount_cents effective_date note].freeze
      FILTER_PARAMS = %i[q country department job_title sort direction].freeze

      before_action :set_employee, only: %i[update destroy]

      # GET /api/v1/employees
      def index
        render_page(EmployeesQuery.call(params.permit(*FILTER_PARAMS)), serializer: EmployeeSerializer)
      end

      # GET /api/v1/employees/:id
      def show
        render_employee(params[:id])
      end

      # POST /api/v1/employees
      def create
        attributes = params.expect(employee: [ *PROFILE_FIELDS, { salary: SALARY_FIELDS } ])
        result = Employees::Create.call(attributes: attributes.except(:salary), salary: attributes.fetch(:salary, {}))
        return render_validation_errors(result.error) if result.failure?

        render_employee(result.value.id, status: :created)
      end

      # PATCH /api/v1/employees/:id  (profile only; pay changes go through /salaries)
      def update
        return render_validation_errors(@employee.errors) unless @employee.update(params.expect(employee: PROFILE_FIELDS))

        render_employee(@employee.id)
      end

      # DELETE /api/v1/employees/:id
      def destroy
        @employee.destroy!
        head :no_content
      end

      private

      def set_employee
        @employee = Employee.find(params[:id])
      end

      def render_employee(id, status: :ok)
        render json: { data: EmployeeSerializer.one(Employee.with_usd_salary.find(id)) }, status:
      end
    end
  end
end
