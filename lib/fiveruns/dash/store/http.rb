module Fiveruns::Dash::Store
  
  module HTTP
    
    def store_http(*uris)
      if (uri = uris.detect { |u| transmit_to u })
        Fiveruns::Dash.logger.info "Sent to #{uri}"
        uri
      else
        Fiveruns::Dash.logger.warn "Could not send data for this interval"
        false
      end
    end

    def transmit_to(uri)
      safely do
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        resp = nil
        multipart = Multipart.new(payload.io, params)
        check_response_of http.post(uri.request_uri, multipart.to_s, "Content-Type" => multipart.content_type)
      end
    end

    def safely
      yield
    rescue Exception => e
      Fiveruns::Dash.logger.error "Could not access service: #{e.message} (#{e.backtrace[0,4].join(' | ')})"
      false
    end
    
    def check_response_of(response)
      case response.code.to_i
      when 201
        true
      when 403
        Fiveruns::Dash.logger.warn "Not authorized to access the FiveRuns Dash service"
        false
      else
        Fiveruns::Dash.logger.debug "Received bad response from service (#{resp.inspect})"
        false
      end
    end
    
    # TODO: Hostname, MAC, etc
    def params
      {
        :token => configuration.options[:app]
      }
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