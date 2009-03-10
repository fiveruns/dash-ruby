require 'net/https'
#require 'resolv'
require 'ostruct'

if defined?(Socket)
  Socket.do_not_reverse_lookup=true
end

module Fiveruns::Dash::Write::Store
  
  module HTTP
    
    def resolved_hostnames
      Thread.current[:resolved_hostnames] ||= {}
      Thread.current[:resolved_hostnames]
    end
    
    def resolved_hostname(hostname)
      if resolved_hostnames[hostname] && Time.now < resolved_hostnames[hostname].next_update
        ip = resolved_hostnames[hostname].ip
      else
        ip = hostname == 'localhost' ? '127.0.0.1' : IPSocket.getaddress(hostname)
        ip_struct = OpenStruct.new(:ip => ip, :next_update => Time.now + (23 * 60 * 60) + (rand(60) * 60))
        resolved_hostnames[hostname] = ip_struct
      end
      ip
    end
      
    
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
        http = Net::HTTP.new(resolved_hostname(uri.host), uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        http.open_timeout = 10
        http.read_timeout = 10
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        extra_params = extra_params_for(payload)
        multipart = Multipart.new(payload.io, payload.params.merge(extra_params))
        response = http.post(uri.request_uri, multipart.to_s, "Content-Type" => multipart.content_type, "Host" => uri.host) 
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
        # data = Fiveruns::JSON.load(response.body)
        true
      when 400..499
        Fiveruns::Dash.logger.warn "Could not access Dash service (#{response.code.to_i}, #{response.body.inspect})"
        false
      else
        Fiveruns::Dash.logger.debug "Received unknown response from Dash service (#{response.inspect})"
        false
      end
    rescue Fiveruns::JSON::ParserError => e
      puts response.body
      Fiveruns::Dash.logger.error "Received non-FiverunsJSON response (#{response.inspect})"
      false
    end
    
    def add_path_to(uri)
      new_uri = uri.dup
      path = case payload
      when Fiveruns::Dash::Write::PingPayload
        ::File.join('/apps', app_token, "ping")
      when Fiveruns::Dash::Write::InfoPayload
        ::File.join('/apps', app_token, "processes.json")
      when Fiveruns::Dash::Write::DataPayload
        ::File.join('/apps', app_token, "metrics.json")
      when Fiveruns::Dash::Write::ExceptionsPayload
        ::File.join('/apps', app_token, "exceptions.json")
      else
        raise ArgumentError, 'Unknown payload type: #{payload.class}'
      end
      new_uri.path = path
      new_uri
    end
    
    def extra_params_for(payload)
      case payload
      when Fiveruns::Dash::Write::ExceptionsPayload
        {:app_id => app_token}
      else
        Hash.new
      end
    end
    
    def normalize_key(key)
      key.to_a.flatten.map { |k| k.to_s }.sort
    end
    
    def app_token
      Fiveruns::Dash.application.token
    end

    class Multipart

      attr_reader :file, :params
      def initialize(file, params={})
        @file = file
        @params = params
        @boundary = 'B0UND'
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
        "#{@boundary}*#{nonce}"
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