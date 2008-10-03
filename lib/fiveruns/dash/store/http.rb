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
        extra_params = extra_params_for(payload)
        multipart = Multipart.new(payload.io, payload.params.merge(extra_params))
        response = http.post(uri.request_uri, multipart.to_s, "Content-Type" => multipart.content_type)
      end
      check_response_of response
    end

    def safely
      yield
    rescue Exception => e
      Fiveruns::Dash.logger.error "Could not access Dash service: #{e.message}"
      Fiveruns::Dash.logger.error e.backtrace.join("\n\t")
      false
    end
    
    def check_response_of(response)
      unless response
        Fiveruns::Dash.logger.debug "Received no response from Dash service"
        return false
      end
      case response.code.to_i
      when 201        
        if payload.is_a?(Fiveruns::Dash::InfoPayload)
          data = JSON.load(response.body)
          Fiveruns::Dash.process_id = data['process_id']
          data['metric_infos'].each do |mapping|
            info_id = mapping.delete('id')
            metric = ::Fiveruns::Dash.configuration.metrics.detect { |metric| normalize_key(metric.key) ==  normalize_key(mapping) }
            if metric
              metric.info_id = info_id
            else
              Fiveruns::Dash.logger.warn "Did not find local metric for server metric #{key.inspect}"
              return false
            end
          end
          Fiveruns::Dash.trace_contexts = data['traces']
        end
        true
      when 400..499
         Fiveruns::Dash.logger.warn "Could not access Dash service (#{response.code.to_i}, #{response.body.inspect})"
        false
      else
        Fiveruns::Dash.logger.debug "Received unknown response from Dash service (#{response.inspect})"
        Fiveruns::Dash.logger.debug response.body
        false
      end
    end
    
    def add_path_to(uri)
      returning uri.dup do |new_uri|
        path = case payload
        when Fiveruns::Dash::InfoPayload
          ::File.join('/apps', app_token, "processes.json")
        when Fiveruns::Dash::DataPayload
          ::File.join('/apps', app_token, "metrics.json")
        when Fiveruns::Dash::TracePayload
          ::File.join('/apps', app_token, "traces.json")
        when Fiveruns::Dash::ExceptionsPayload
          '/exceptions.json'
        else
          raise ArgumentError, 'Unknown payload type: #{payload.class}'
        end
        new_uri.path = path
      end
    end
    
    def extra_params_for(payload)
      case payload
      when Fiveruns::Dash::ExceptionsPayload
        {:app_id => app_token}
      else
        Hash.new
      end
    end
    
    def normalize_key(key)
      key.to_a.flatten.map(&:to_s).sort
    end
    
    def app_token
      ::Fiveruns::Dash.configuration.options[:app]
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
            %(Content-Disposition: form-data; name="#{name}"; filename="metrics.json.gz"),
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