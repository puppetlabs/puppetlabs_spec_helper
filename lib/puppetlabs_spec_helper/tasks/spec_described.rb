# frozen_string_literal: true

module PuppetlabsSpecHelper
  module Tasks
    # Helper
    class SpecDescribed
      def hash_diff(first, second)
        first.merge(first) { |ka, va| va.reject { |v| second[ka]&.include?(v) } }
      end

      def coverage_color(percent, required = 100, warn: 0.5)
        if percent >= required.to_f
          :green
        elsif percent < required.to_f * warn.to_f
          :red
        else
          :yellow
        end
      end

      def check
        code = {}
        code_files = {}
        Dir.glob('{functions,manifests,types}/**/*.pp') do |fn|
          res_type = res_title = nil
          File.foreach(fn) do |line|
            if line =~ /^\s*(class|function|define|type|function)\s*([^={\s]+)/
              res_type = Regexp.last_match(1)
              res_title = Regexp.last_match(2)
              res_type = 'type_alias' if res_type == 'type'
              code[res_type] ||= []
              break
            end
          end
          if res_type
            code[res_type] << res_title if res_type
            code_files[res_title] = fn
          end
        end
        Dir.glob('lib/puppet/functions/**/*.rb') do |fn|
          File.foreach(fn) do |line|
            if line =~ /^\s*Puppet::Functions\.create_function\(:?['"]?([^']+)['"]?\)/
              code['function'] ||= []
              code['function'] << Regexp.last_match(1)
              code_files[Regexp.last_match(1)] = fn
            end
          end
        end

        test = {}
        test_files = {}
        Dir.glob('spec/{classes,defines,functions,type_aliases}/**/*rb') do |fn|
          resource_type = fn.split(File::SEPARATOR)[1].match(/(class|function|define|type_alias)/).captures[0]
          test[resource_type] ||= []
          File.foreach(fn) do |line|
            if (m = line.match(/^describe ["']([^'"\s]+)/))
              test[resource_type] << m.captures[0]
              test_files[m.captures[0]] = fn
            end
          end
        end

        results = {
          code: code,
          code_files: code_files,
          test: test,
          test_files: test_files,
          missing: hash_diff(code, test),
          unknown: hash_diff(test, code),
          want: code.values.flatten.size
        }

        results[:have] = results[:want] - results[:missing].values.flatten.size
        results[:percent] = results[:have] / results[:want].to_f * 100

        results
      end
    end
  end
end
