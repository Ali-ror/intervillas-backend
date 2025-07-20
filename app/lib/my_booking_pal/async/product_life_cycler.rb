module MyBookingPal
  module Async
    # Activates the products with the given IDs.
    class ProductLifeCycler < Base
      Action = Struct.new(:name, :endpoint, :on_success, :on_start, :on_failure, :to_payload, keyword_init: true) do
        def schedule(foreign_id)
          ProductLifeCycler.perform_async(foreign_id, name)
          update_product(foreign_id, status: on_start)
        end

        def run(foreign_id)
          MyBookingPal.post(endpoint, data: to_payload.call(foreign_id))
          update_product(foreign_id, status: on_success)
        rescue APIError => err
          if name == "activate" && err.message.start_with?("Product already activated! Product ID: #{foreign_id}")
            update_product(foreign_id, status: :active)
          else
            update_product(foreign_id, status: on_failure, message: err.message)
          end
        end

        private

        def update_product(foreign_id, status:, message: nil)
          Product.find_by!(foreign_id: foreign_id).update!(
            status:           status,
            status_message:   message,
            skip_remote_save: true,
          )
        end
      end
      private_constant :Action

      ACTIONS = [
        Action.new(
          name:       "validate",
          endpoint:   "/validation",
          on_start:   :queued_validation,
          on_success: :waiting_validation,
          on_failure: :validation_error,
          to_payload: ->(id) { { productIds: [id] } },
        ),

        Action.new(
          name:       "activate",
          endpoint:   "/product/activation",
          on_start:   :queued_activation,
          on_success: :active,
          on_failure: :activation_error,
          to_payload: ->(id) { [id] },
        ),

        Action.new(
          name:       "deactivate",
          endpoint:   "/product/deactivation",
          on_start:   :queued_deactivation,
          on_success: :valid,
          on_failure: :activation_error,
          to_payload: ->(id) { [id] },
        ),
      ].index_by(&:name).freeze

      def perform(foreign_id, action_name)
        ACTIONS.fetch(action_name).run(foreign_id)
      end
    end
  end
end
