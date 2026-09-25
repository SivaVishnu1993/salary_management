module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate!, only: :login

      # POST /api/v1/auth/login
      def login
        email, password = params.require(%i[email password])
        result = Auth::Login.call(email:, password:)
        return render_unauthorized("Invalid email or password") if result.failure?

        render json: { data: session_json(result.value) }
      end

      # GET /api/v1/auth/me
      def me
        render json: { data: UserSerializer.one(current_user) }
      end

      private

      def session_json(session)
        {
          token: session.token.value,
          token_type: "Bearer",
          expires_at: session.token.expires_at.iso8601,
          user: UserSerializer.one(session.user)
        }
      end
    end
  end
end
