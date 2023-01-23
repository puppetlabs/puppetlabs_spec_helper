# frozen_string_literal: true

require 'fast_gettext/translation_repository/base'
require 'fast_gettext/translation_repository/mo'
module FastGettext
  module TranslationRepository
    # Responsibility:
    #  - find and store po files
    #  - provide access to translations in po files
    class Po < Mo
      protected

      def find_and_store_files(name, options)
        require 'fast_gettext/po_file'
        find_files_in_locale_folders("#{name}.po", options[:path]) do |_locale, file|
          PoFile.new(file, options)
        end
      end
    end
  end
end
