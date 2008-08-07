require 'zlib'

require 'dash/store/http'
require 'dash/store/file'

module Fiveruns::Dash
    
  class Update
    
    include Store::HTTP
    include Store::File
    
    attr_reader :payload, :configuration
    def initialize(payload, configuration)
      @payload = payload
      @configuration = configuration
    end
    
    def store(*urls)
      if @payload.blank?
        Fiveruns::Dash.logger.debug "Empty payload; skipping"
        return nil
      end
      uris_by_scheme(urls).each do |scheme, uris|
        value = __send__("store_#{storage_method_for(scheme)}", *uris)
        return value if value
      end
      return false
    end
    
    def guid
      @guid ||= timestamp << "_#{Process.pid}"
    end
    
    #######
    private
    #######
    
    def timestamp
      Time.now.strftime('%Y%m%d%H%M%S')
    end
    
    def uris_by_scheme(urls)
      urls.map { |url| safe_parse(url) }.group_by(&:scheme)
    end
    
    def storage_method_for(scheme)
      scheme =~ /^http/ ? :http : :file
    end
    
    def safe_parse(url)
      url.respond_to?(:scheme) ? url : URI.parse(url)
    end
    
  end

  class Payload
    
    delegate :blank?, :to => :@data
    
    def initialize(data)
      @version = Fiveruns::Dash::Version::STRING
      @data = data
    end

    def io
      returning StringIO.new do |io|
        io.write compressed
        io.rewind
      end
    end

    def to_yaml_type
      raise NotImplementedError, "Abstract payload type"
    end
    
    def params
      {}
    end
    
    #######
    private
    #######

    def compressed
      Zlib::Deflate.deflate(to_yaml)
    end

  end
  
  class InfoPayload < Payload
    def initialize(data, started_at)
      super(data)
      @started_at = started_at
    end
    def to_yaml_type
      "!dash.fiveruns.com,2008-07/info"
    end
    def params
      params = { 
        :ip => Fiveruns::Dash.host.ip_address,
        :mac => Fiveruns::Dash.host.mac_address,
        :hostname => Fiveruns::Dash.host.hostname,
        :pid => Process.pid,
        :os_name => Fiveruns::Dash.host.os_name,
        :os_version => Fiveruns::Dash.host.os_version,
        :pwd => Dir.pwd,
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
    
    # InfoPayloads are never blank
    def blank?
      false
    end
    
  end
  
  class DataPayload < Payload
    def to_yaml_type
      "!dash.fiveruns.com,2008-07/data"
    end
    def params
      { 
        :collected_at => Time.now.utc,
        :process_id => Fiveruns::Dash.process_id,
      }
    end
  end
    
          
end