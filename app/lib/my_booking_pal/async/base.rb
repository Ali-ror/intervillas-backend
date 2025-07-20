module MyBookingPal
  module Async
    class Base
      # Creates a background job.
      #
      # If `SomeThing` is a subclass of `Base`, the following is equivalent:
      #
      #   SomeThing.perform_async(42)
      #   ThrottledWorker.perform_async("SomeThing", 42)
      #
      # both of which will call #perform on `SomeThing` in the background.
      #
      # If `bulk` is truthy, the job is scheduled a few minutes into the
      # future. Any futher bulk calls (with the same arguments) will cancel
      # the previous job and replace it with a new timer.
      def self.perform_async(*args, bulk: false, wait: 2.minutes)
        if bulk
          BulkheadWorker.perform_in(wait, to_s, *args)
        else
          ThrottledWorker.perform_async(to_s, *args)
        end
      end

      # Instantiates class with the given arguments, and calls #perform on
      # the instance.
      def self.perform(*args)
        new.perform(*args)
      end

      def track_progress(id, name, reset: false)
        progress = UpdateProgress.new(id)
        progress.reset!(name) if reset

        result = yield
        progress.finish!(name)

        result
      end
    end
  end
end
