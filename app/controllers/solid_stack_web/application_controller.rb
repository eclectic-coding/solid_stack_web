module SolidStackWeb
  class ApplicationController < ActionController::Base
    include Pagy::Method

    before_action :authenticate!
    around_action :with_database_connection

    private

    def with_database_connection
      config = SolidStackWeb.connects_to
      return yield unless config

      if config.key?(:reading) && config.key?(:writing)
        role = request.get? ? config[:reading] : config[:writing]
        ActiveRecord::Base.connected_to(role: role) { yield }
      else
        ActiveRecord::Base.connected_to(**config) { yield }
      end
    end

    def authenticate!
      return unless (auth = SolidStackWeb.authenticate)

      instance_exec(&auth) || request_basic_auth
    end

    def request_basic_auth
      request_http_basic_authentication("Solid Stack Dashboard")
    end
  end
end
