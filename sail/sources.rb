require 'json'

module Asciidoctor
  module Sail
    class Sources
      @sources = {}

      def self.register key, sourcemap_path
        unless @sources.key?(key) then
          file = File.read(sourcemap_path)
          @sources[key] = JSON.parse(file)
        end
      end

      def self.get key
        @sources[key]
      end
    end
  end
end
