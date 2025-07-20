module MyBookingPal
  # UpdateProgress tracks the Async::ProductUpdater steps in Redis as hash
  # with the following shape:
  #
  #   {
  #     "<step>:todo"         => <number>, # counts total jobs
  #     "<step>:done"         => <number>, # counts completed jobs
  #     "<step>:started_at"   => <unix timestmap>,
  #     "<step>:completed_at" => <unix timestmap> | nil,
  #   }
  #
  # where `<step>` is the name of the (planned) step(s).
  #
  # For each step, we record its progress (i.e. the number of completed and
  # overall executions, plus the timing).
  #
  # In general, async worker will increment the "<step>:todo" value when a step
  # is enqueued, and increment the "<step>:done" value after the step performed.
  # If those counters are equal, "<step>:completed_at" is set to the current
  # timestamp.
  #
  # This behaviour implies that the worker must call #finish! *after* it has
  # enqueued additional steps (via #start!); otherwise, the progress is
  # erroneously/prematurely marked as completed.
  #
  # Beware that calling #start! with "start" resets the whole progress report.
  class UpdateProgress
    NAMESPACE = "mybookingpal:productupdate".freeze

    def self.start!(id, step)
      new(id).start!(step)
    end

    def self.all
      Sidekiq.redis do |conn|
        conn.keys("#{NAMESPACE}:*").to_h { |key|
          id = key.split(":").last.to_i
          [id == "" ? nil : id.to_i, new(id)]
        }
      end
    end

    delegate :[], :each, :started_at, :completed_at, :as_json,
      to: :steps

    # @param [Integer] id Villa ID
    def initialize(id)
      @key       = "#{NAMESPACE}:#{id}"
      @steps     = nil
      @destroyed = false
    end

    def start!(name)
      return if @destroyed && name != "start" # allow restart

      with_current_time do |now|
        Sidekiq.redis do |conn|
          if name == "start"
            conn.del  @key
            conn.hset @key, {
              "#{name}:started_at" => now,
              "#{name}:todo"       => 1,
            }
          else
            conn.hincrby @key, "#{name}:todo", 1
            conn.hsetnx  @key, "#{name}:started_at", now # create-only, no update
          end
        end

        @steps     = nil
        @destroyed = false
      end
    end

    def reset!(name)
      return if @destroyed

      with_current_time { |now|
        Sidekiq.redis do |conn|
          conn.hdel @key, "#{name}:done", "#{name}:completed_at"
          conn.hset @key, {
            "#{name}:started_at" => now,
            "#{name}:todo"       => 1,
          }
        end
      }
    end

    def finish!(name)
      return if @destroyed

      with_current_time { |now|
        Sidekiq.redis do |conn|
          conn.hincrby @key, "#{name}:done", 1
          steps = steps(true)

          if steps.done?(name)
            conn.hset @key, "#{name}:completed_at", now
            steps[name].completed_at = now
          else
            conn.hdel @key, "#{name}:completed_at"
            steps[name].completed_at = nil
          end
        end
      }
    end

    def destroy!
      return if @destroyed

      Sidekiq.redis { _1.del @key }
      @steps     = nil
      @destroyed = true
    end

    def steps(reload = false)
      return {} if @destroyed

      @steps   = nil if reload
      @steps ||= Steps.new raw
    end

    private

    def with_current_time
      yield Time.current.to_i
      true
    end

    def raw
      Sidekiq.redis { _1.hgetall @key }
    end

    # Helper class for #finish! and #values
    class Steps
      attr_reader :steps

      delegate :[],
        to: :steps

      Step = Struct.new(:name, :started_at, :completed_at, :todo, :done, keyword_init: true)
      private_constant :Step

      def initialize(progress)
        @steps = Hash.new do |steps, name|
          steps[name] = Step.new(
            name:         name,
            started_at:   nil,
            completed_at: nil,
            todo:         0,
            done:         0,
          )
        end

        progress.each do |k, v|
          name, suffix = k.split(":")
          suffix       = suffix.to_sym

          case suffix
          when :todo, :done
            @steps[name][suffix] += v.to_i
          when :started_at, :completed_at
            @steps[name][suffix] = to_time v
          else
            raise ArgumentError, "unknown job suffix: #{suffix}"
          end
        end
      end

      def []=(key, count)
        name, type         = key.split(":")
        index              = type == "todo" ? 0 : 1
        steps[name][index] = count
      end

      def done?(name)
        step = steps[name]
        step.todo == step.done
      end

      def as_json(*)
        steps.values
      end

      private

      def to_time(val)
        Time.zone.at(val.to_i) if val.present?
      end
    end
    private_constant :Steps
  end
end
