require 'zlib'

require 'dash/write/store/http'
require 'dash/write/store/file'

module Fiveruns::Dash::Write

  class Pinger

    attr_reader :payload
    def initialize(payload)
      @payload = payload
    end

    def ping(*urls)
      try_urls(urls) do |url|
        send_ping(url, payload)
      end
    end

    def send_ping(url, payload)
      begin
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true if url.scheme == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        multipart = Fiveruns::Dash::Write::Store::HTTP::Multipart.new(payload.io, payload.params)
        response = http.post("/apps/#{token}/ping", multipart.to_s, "Content-Type" => multipart.content_type)
        case response.code.to_i
        when 201
          data = Fiveruns::JSON.load(response.body)
          [:success, "Found application '#{data['name']}'"]
        else
          # Error message
          [:failed, response.body.to_s]
        end
      rescue => e
        [:error, e.message]
      end
    end

    def token
      Fiveruns::Dash.configuration.options[:app]
    end

    def try_urls(urls)
      results = urls.map do |u|
        result = yield(URI.parse(u))
        case result[0]
        when :success
          puts "OK: #{result[1]}"
          true
        when :failed
          puts "Failed talking to #{u}: #{result[1]}"
          false
        when :error
          puts "Error contacting #{u}: #{result[1]}"
          false
        end
      end
      results.all?
    end
  end

  class Update

    include Store::HTTP
    include Store::File

    attr_reader :payload, :handler
    def initialize(payload, &handler)
      @payload = payload
      @handler = handler
    end
    
    def store(*urls)
      uris_by_scheme(urls).each do |scheme, uris|
        value = __send__("store_#{storage_method_for(scheme)}", *uris)
        return value if value
      end
      return false
    end
    
    def ping(*urls)
      Pinger.new(payload).ping(*urls)
    end

    def guid
      @guid ||= timestamp << "_#{Process.pid}"
    end
    
    #######
    private
    #######
    
    def timestamp
      Time.now.utc.strftime('%Y%m%d%H%M%S')
    end
    
    def uris_by_scheme(urls)
      safe = urls.map { |url| safe_parse(url) }
      safe.inject({}) do |mapping, url|
        mapping[url.scheme] ||= []
        mapping[url.scheme] << url
        mapping
      end
    end
    
    def storage_method_for(scheme)
      scheme =~ /^http/ ? :http : :file
    end
    
    def safe_parse(url)
      url.respond_to?(:scheme) ? url : URI.parse(url)
    end
    
  end

  class Payload
        
    def initialize(data)
      @version = Fiveruns::Dash::Version::STRING
      @data = data
    end

    def io
      io = StringIO.new
      io.write compressed
      io.rewind
      io
    end
    
    def params
      {}
    end
    
    def to_fjson
      @data.to_fjson
    end
    
    #######
    private
    #######
    
    def timestamp
      Time.now.utc.rfc2822
    end

    def compressed
      Zlib::Deflate.deflate(to_fjson)
    end

  end
  
  class InfoPayload < Payload
    def initialize(data, started_at)
      super(data)
      @started_at = started_at
    end
    def params
      @params ||= begin
        params = {
          :type => 'info',
          :ip => Fiveruns::Dash.host.ip_address,
          :hostname => Fiveruns::Dash.host.hostname,
          :pid => Process.pid,
          :os_name => Fiveruns::Dash.host.os_name,
          :os_version => Fiveruns::Dash.host.os_version,
          :arch => Fiveruns::Dash.host.architecture,
          :dash_version => Fiveruns::Dash::Version::STRING,
          :ruby_version => RUBY_VERSION,
          :started_at => @started_at
        }
        if (scm = Fiveruns::Dash.scm)
          params.update(
            :scm_revision => scm.revision,
            :scm_time => scm.time,
            :scm_type => scm.class.scm_type,
            :scm_url => scm.url
          )
        end
        params
      end
    end
    
  end
  
  class PingPayload < InfoPayload
  end

  class ExceptionsPayload < Payload
    def params
      @params ||= {
        :type => 'exceptions',
        :collected_at => timestamp,
        :hostname => Fiveruns::Dash.host.hostname,
      }
    end
  end
  
  class DataPayload < Payload
    def params
      @params ||= {
        :type => 'data',
        :collected_at => timestamp,
        :hostname => Fiveruns::Dash.host.hostname,
      }
    end
  end

end