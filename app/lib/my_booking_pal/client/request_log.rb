module MyBookingPal
  class Client
    class RequestLog
      REDIS_KEY   = "mybookingpal:clientlog".freeze
      PER_PAGE    = 25
      MAX_ENTRIES = 1000

      def self.capture(req, uri, method, path, privileged, **config)
        m = Measure.new(method, path, privileged, req.body&.length)

        parsed = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", **config) { |http|
          res = m.measure_http_request { http.request(req) }
          yield res # block shall return a MyBookingPal::Client::Response or raise an error
        }

        m.success!(message: parsed.message.presence)
        parsed.payload
      rescue StandardError => err
        m.failure!(error: err)
        raise
      end

      def self.fetch(page: 1)
        page      = 1 if page.nil? || page < 1
        start_idx = (page - 1) * PER_PAGE
        stop_idx  = start_idx + PER_PAGE - 1
        total     = 0

        entries = Sidekiq.redis { |conn|
          total = conn.llen REDIS_KEY
          conn.lrange REDIS_KEY, start_idx, stop_idx
        }

        entries.map! { Measure.parse_json(_1) }

        {
          entries:    entries,
          pagination: {
            page:  page,
            total: total,
            per:   PER_PAGE,
          },
        }
      end

      class Measure
        attr_reader :data

        def self.parse_json(json)
          m         = JSON.parse(json)
          m["time"] = Time.zone.at(m["time"]) if m["time"]
          m
        end

        def initialize(method, path, privileged, request_length)
          @data = {
            duration:        nil,
            method:          method,
            path:            path,
            privileged:      privileged,
            request_length:  request_length,
            response_length: -1,
            code:            -1,
          }
        end

        def measure_http_request
          t_start = Time.current
          res     = yield
        ensure
          data.merge!(time: t_start.to_i, duration: Time.current - t_start)
          data.merge!(response_length: res.body&.length, code: res.code.to_i) if res
        end

        def success!(message:)
          store data.merge(message: message)
        end

        def failure!(error:)
          store data.merge(error: describe_error(error))
        end

        private

        def store(payload)
          Sidekiq.redis do |conn|
            conn.lpush REDIS_KEY, payload.to_json

            # keep at most 1000 log entries
            conn.ltrim REDIS_KEY, 0, MAX_ENTRIES - 1
          end
        end

        def describe_error(err)
          case err
          when MyBookingPal::RateLimited then "rate limit reached"
          when MyBookingPal::APIError    then err.message
          else "#{err.class}: #{err.message}"
          end
        end
      end
      private_constant :Measure
    end
  end
end
