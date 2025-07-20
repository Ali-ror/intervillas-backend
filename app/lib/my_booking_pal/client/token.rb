module MyBookingPal
  class Client
    # An access token (called "jwt" in their documentation) is valid for about
    # an hour. There are two access levels: the system level for authoring
    # settings related to the integration + user (PM) management, and PM level
    # for authoring changes related to properties. For each access level, you'll
    # need a separate token.
    #
    # The token is stored for its lifetime in Redis. This alleviates the need
    # for multiple, parallel logins in different processes/threads, and reduces
    # the risk of running into rate-limits.
    class Token
      attr_reader :name, :refresh
      private :name, :refresh

      EXPIRES_AFTER = 58.minutes

      # @param [#to_s] name A unique name for this token.
      # @param [#call] refresh Code to get a new token. Usually, this is #login!
      #   in the Client class, but depending on the exact use case, this might
      #   not be enough (think: side-effects).
      def initialize(name, &refresh)
        @name    = "mybookingpal:token:#{name}"
        @refresh = refresh
      end

      def token
        fetch_token || update_token
      end

      def fetch_token
        Sidekiq.redis { _1.get name }
      end

      def update_token
        refresh.call.tap { |value|
          Sidekiq.redis { _1.set name, value, ex: EXPIRES_AFTER.to_i }
        }
      end
    end
  end
end
