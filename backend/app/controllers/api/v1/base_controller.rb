module Api
  module V1
    # Every v1 endpoint is authenticated unless it explicitly opts out.
    class BaseController < ApplicationController
      include Authenticatable
      include Paginatable
    end
  end
end
