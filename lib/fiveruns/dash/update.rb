require 'zlib'

require 'dash/store/http'
require 'dash/store/file'

module Fiveruns
  
  module Dash
    
    class Update
      
      include Store::HTTP
      include Store::File
      
      def initialize(data, configuration)
        @payload = Payload.new(data, configuration)
      end
      
      def store(*urls)
        uris_by_type(urls).each do |scheme, uris|
          __send__("store_#{scheme}", uris)
        end
      end
      
      def guid
        @guid ||= timestamp << "_#{Process.pid}"
      end
      
      def timestamp
        Time.now.strftime('%Y%m%d%H%M%S')
      end
      
      def uris_by_scheme(urls)
        urls.map { |url| URI.parse(url) }.group_by(&:scheme)
      end
      
    end

    class Payload

      attr_reader :info
      def initialize(data, config)
        @data = data
        @info = Info.new(config)
      end      

      def io
        returning StringIO.new do |io|
          io.write compressed
          io.rewind
        end
      end

      def to_yaml_type
        '!dash.fiveruns.com,2008-07/payload'
      end

      #######
      private
      #######

      def compressed
        Zlib::Deflate.deflate(to_yaml)
      end

    end
        
  end
  
end