# frozen_string_literal: true

require 'json'

module Asciidoctor
  module Sail
    class Sources
      @sources = {}

      def self.register(key, sourcemap_path)
        return if @sources.key?(key)

        if not File.exist?(sourcemap_path)
          raise "Sail Asciidoc plugin: File #{sourcemap_path} does not exist"
        end

        file = File.read(sourcemap_path)
        @sources[key] = JSON.parse(file)
      end

      def self.get(key)
        @sources[key]
      end
    end
  end
end
