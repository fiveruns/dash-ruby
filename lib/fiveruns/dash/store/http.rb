require 'net/https'
#require 'resolv'
require 'ostruct'

if defined?(Socket)
  Socket.do_not_reverse_lookup=true
end

module Fiveruns::Dash::Store
  
  module HTTP
    
    # attr_accessor :resolved_uris
    # 
    # def resolved_uris
    #   @resolved_uris ||= {}
    # end
    # 
    # def resolved_uri(uri)
    #   if resolved_uris[uri] && Time.now < resolved_uris[uri].next_update
    #     ip = resolved_uris[uri].ip
    #   else
    #     ip = Resolv.getaddress(uri.host) 
    #     uri_struct = OpenStruct.new(:ip => ip, :next_update => Time.now + 23.hours + rand(60).minutes)
    #     resolved_uris[uri] = uri_struct
    #     # TODO add host header
    #   end
    #   resolved_uris[uri].ip_uri
    # end
    # 
    attr_accessor :resolved_hostnames
    def resolved_hostnames
      @resolved_hostnames ||= {}
    end
    
    def resolved_hostname(hostname)
      if resolved_hostnames[hostname] && Time.now < resolved_hostnames[hostname].next_update
        ip = resolved_hostnames[hostname].ip
      else
        ip = hostname == 'localhost' ? '127.0.0.1' : IPSocket.getaddress(hostname)
        ip_struct = OpenStruct.new(:ip => ip, :next_update => Time.now + 23.hours + rand(60).minutes)
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
        data = JSON.load(response.body)
        set_trace_contexts(data)
        if payload.is_a?(Fiveruns::Dash::InfoPayload)   
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
        end
        true
      when 400..499
        Fiveruns::Dash.logger.warn "Could not access Dash service (#{response.code.to_i}, #{response.body.inspect})"
        false
      else
        Fiveruns::Dash.logger.debug "Received unknown response from Dash service (#{response.inspect})"
        false
      end
    rescue JSON::ParserError => e
      puts response.body
      Fiveruns::Dash.logger.error "Received non-JSON response (#{response.inspect})"
      false
    end
    
    def set_trace_contexts(data)
      trace_contexts = data['traces']
      if trace_contexts.is_a?(Array)
        Fiveruns::Dash.trace_contexts = trace_contexts
      end
    end
    
    def add_path_to(uri)
      returning uri.dup do |new_uri|
        path = case payload
        when Fiveruns::Dash::PingPayload
          ::File.join('/apps', app_token, "ping")
        when Fiveruns::Dash::InfoPayload
          ::File.join('/apps', app_token, "processes.json")
        when Fiveruns::Dash::DataPayload
          ::File.join('/apps', app_token, "metrics.json")
        when Fiveruns::Dash::TracePayload
          ::File.join('/apps', app_token, "traces.json")
        when Fiveruns::Dash::ExceptionsPayload
          ::File.join('/apps', app_token, "exceptions.json")
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