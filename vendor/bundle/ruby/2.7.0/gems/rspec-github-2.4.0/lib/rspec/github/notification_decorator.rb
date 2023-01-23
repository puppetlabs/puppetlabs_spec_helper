# frozen_string_literal: true

module RSpec
  module Github
    class NotificationDecorator
      # See https://github.community/t/set-output-truncates-multiline-strings/16852/3.
      ESCAPE_MAP = {
        '%' => '%25',
        "\n" => '%0A',
        "\r" => '%0D'
      }.freeze

      def initialize(notification)
        @notification = notification
      end

      def line
        example.location.split(':')[1]
      end

      def annotation
        "#{example.full_description}\n\n#{message}"
          .gsub(Regexp.union(ESCAPE_MAP.keys), ESCAPE_MAP)
      end

      def path
        # TODO: use `delete_prefix` when dropping ruby 2.4 support
        File.realpath(raw_path).sub(/\A#{workspace}#{File::SEPARATOR}/, '')
      end

      private

      def example
        @notification.example
      end

      def message
        if @notification.respond_to?(:message_lines)
          @notification.message_lines.join("\n")
        else
          "#{example.skip ? 'Skipped' : 'Pending'}: #{example.execution_result.pending_message}"
        end
      end

      def raw_path
        example.location.split(':')[0]
      end

      def workspace
        File.realpath(ENV.fetch('GITHUB_WORKSPACE', '.'))
      end
    end
  end
end
