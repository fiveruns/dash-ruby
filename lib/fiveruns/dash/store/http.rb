require 'net/https'

module Fiveruns::Dash::Store
  
  module HTTP
    
    def store_http(*uris)
      Fiveruns::Dash.logger.info "Attempting to send #{payload.class}"
      if (uri = uris.detect { |u| transmit_to(add_path_to(u)) })
        Fiveruns::Dash.logger.info "Sent #{payload.class} to #{uri}"
        uri
      else
        Fiveruns::Dash.logger.warn "Could not send #{payload.class}"
        false
      end
    end

    def transmit_to(uri)
      response = nil
      safely do
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        multipart = Multipart.new(payload.io, payload.params)
        response = http.post(uri.request_uri, multipart.to_s, "Content-Type" => multipart.content_type)
      end
      check_response_of response
    end

    def safely
      yield
    rescue Exception => e
      Fiveruns::Dash.logger.error "Could not access service: #{e.message}"
      false
    end
    
    def check_response_of(response)
      unless response
        Fiveruns::Dash.logger.debug "Received no response from service"
        return false
      end
      case response.code.to_i
      when 201
        if payload.is_a?(Fiveruns::Dash::InfoPayload)
          data = YAML.load(response.body)
          p data
          Fiveruns::Dash.process_id = data['process_id']
          data['metric_infos'].each do |name, info_id|
            configuration.metrics[name].info_id = info_id
          end
        end
        true
      when 403
        Fiveruns::Dash.logger.warn "Not authorized to access the FiveRuns Dash service"
        false
      else
        Fiveruns::Dash.logger.debug "Received bad response from service (#{response.inspect})"
        Fiveruns::Dash.logger.debug response.body
        false
      end
    end
    
    def add_path_to(uri)
      returning uri.dup do |new_uri|
        component = case payload
        when Fiveruns::Dash::InfoPayload
          :processes
        when Fiveruns::Dash::DataPayload
          :metrics
        else
          raise ArgumentError, 'Unknown payload type: #{payload.class}'
        end
        new_uri.path = ::File.join('/apps', app_token, "#{component}.yml")
      end
    end
    
    def app_token
      configuration.options[:app]
    end

    class Multipart

      BOUNDARY_ROOT = 'B0UND~F0R~UPL0AD'

      attr_reader :file, :params
      def initialize(file, params={})
        @file = file
        @params = params
      end

      def content_type
        %(multipart/form-data, boundary="#{boundary}")
      end

      def to_s
        %(#{parts}\r\n#{separator}--)
      end

      #######
      private
      #######

      def boundary
        "#{BOUNDARY_ROOT}*#{nonce}"
      end

      def parts
        params.merge(:file => file).map do |name, value|
          [
            separator,
            headers_for(name, value)
          ].flatten.join(crlf) + crlf + crlf + content_of(value)
        end.flatten.join(crlf)
      end

      def separator
        %(--#{boundary})
      end

      def crlf
        @crlf ||= "\r\n"
      end

      def headers_for(name, value)
        if value.respond_to?(:read)
          [
            %(Content-Disposition: form-data; name="#{name}"; filename="metrics.yml.gz"),
            %(Content-Transfer-Encoding: binary),
            %(Content-Type: application/octet-stream)
          ]
        else
          [ %(Content-Disposition: form-data; name="#{name}") ]
        end
      end

      def nonce
        @nonce ||= (Time.now.utc.to_f * 1000).to_i
      end

      def content_of(value)
        value.respond_to?(:read) ? value.read : value.to_s
      end

    end

  end

end