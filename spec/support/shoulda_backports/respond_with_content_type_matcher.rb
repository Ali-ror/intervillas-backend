# Backport aus https://github.com/thoughtbot/shoulda-matchers/tree/v1.5/lib/shoulda/matchers

# require 'active_support/deprecation'

module Shoulda # :nodoc:
  module Matchers
    module ActionController # :nodoc:
      # Ensures a controller responded with expected 'response' content type.
      #
      # You can pass an explicit content type such as 'application/rss+xml'
      # or its symbolic equivalent :rss
      # or a regular expression such as /rss/
      #
      # Example:
      #
      #   it { should respond_with_content_type(:xml)  }
      #   it { should respond_with_content_type(:csv)  }
      #   it { should respond_with_content_type(:atom) }
      #   it { should respond_with_content_type(:yaml) }
      #   it { should respond_with_content_type(:text) }
      #   it { should respond_with_content_type('application/rss+xml')  }
      #   it { should respond_with_content_type(/json/) }
      def respond_with_content_type(content_type)
        RespondWithContentTypeMatcher.new(content_type)
      end

      class RespondWithContentTypeMatcher # :nodoc:
        def initialize(content_type)
          # ActiveSupport::Deprecation.warn 'The respond_with_content_type matcher is deprecated and will be removed in 2.0'
          @content_type = look_up_content_type(content_type)
        end

        def description
          "respond with content type of #{@content_type}"
        end

        def matches?(controller)
          @controller = controller
          content_type_matches_regexp? || content_type_matches_string?
        end

        def failure_message
          "Expected #{expectation}"
        end

        def failure_message_when_negated
          "Did not expect #{expectation}"
        end

        protected

        def content_type_matches_regexp?
          return false unless @content_type.is_a?(Regexp)

          response_content_type =~ @content_type
        end

        def content_type_matches_string?
          response_content_type == @content_type ||
            response_content_type.split(";").first == @content_type
        end

        def response_content_type
          @controller.response.content_type.to_s
        end

        def look_up_by_extension(extension)
          Mime::Type.lookup_by_extension(extension.to_s).to_s
        end

        def look_up_content_type(content_type)
          if content_type.is_a?(Symbol)
            look_up_by_extension(content_type)
          else
            content_type
          end
        end

        def expectation
          "content type to be #{@content_type}, but was #{response_content_type}"
        end
      end
    end
  end
end
