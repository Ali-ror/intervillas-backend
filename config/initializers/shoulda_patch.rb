if Rails.env.test?

  class Shoulda::Matchers::ActiveModel::ValidateUniquenessOfMatcher

  private

    def validate_after_scope_change?
      if @options[:scopes].blank?
        true
      else
        @options[:scopes].all? do |scope|
          previous_value = existing.send(scope)

          # Assume the scope is a foreign key if the field is nil
          previous_value ||= correct_type_for_column(@subject.class.columns_hash[scope.to_s])

          next_value = if scope.to_s =~ /_type$/ && klass = previous_value.constantize rescue nil && klass.ancestors.include?(ActiveRecord::Base)
            ::ActiveRecord::Base.descendants.find {|model| model.to_s != previous_value }.to_s
          elsif previous_value.respond_to?(:next)
            previous_value.next
          else
            previous_value.to_s.next
          end

          @subject.send("#{scope}=", next_value)

          if allows_value_of(existing_value, @expected_message)
            @subject.send("#{scope}=", previous_value)

            @failure_message_for_should_not <<
              " (with different value of #{scope})"
            true
          else
            @failure_message_for_should << " (with different value of #{scope})"
            false
          end
        end
      end
    end
  end

end