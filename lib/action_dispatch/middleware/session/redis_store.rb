# frozen_string_literal: true

require 'redis-store'
require 'redis-rack'
require 'action_dispatch/middleware/session/abstract_store'

module ActionDispatch
  module Session
    # Session storage in Redis, using +Redis::Rack+ as a basis.
    class RedisStore < Rack::Session::Redis
      include Compatibility
      include StaleSessionCheck
      include SessionObject

      def initialize(app, options = {})
        options = options.dup
        options[:redis_server] ||= options[:servers]

        super
      end

      def generate_sid
        Rack::Session::SessionId.new(super)
      end

      private

      def set_cookie(env, _session_id, cookie)
        10.times { p 'SET COOKIE' }
        p key
        p "SESSION_ID = #{_session_id}"
        pp cookie
        10.times { p '#######################################################' }
        request = wrap_in_request(env)
        pp cookie_jar(request)[key]
        p 'KEY IS AT THE TOP'
        pp cookie_jar(request)

        cookie_jar(request)[key] = cookie.merge(cookie_options)
      end

      def get_cookie(request)
        cookie_jar(request)[key]
      end

      def wrap_in_request(env)
        return env if env.is_a?(ActionDispatch::Request)
        ActionDispatch::Request.new(env)
      end

      def cookie_options
        @default_options.slice(:httponly, :secure)
      end

      def cookie_jar(request)
        p @default_options[:signed]

        if @default_options[:signed]
          request.cookie_jar.signed_or_encrypted
        else
          request.cookie_jar
        end
      end
    end
  end
end
