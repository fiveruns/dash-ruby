module Fiveruns::Dash::Store
  
  module File
    
    def store_file(*uris)
      uris.each do |uri|
        directory = uri.path
        write_to filename(directory)
      end
    end
    
    def write_to(path)
      ::File.open(path, 'w') { |f| f.write @payload.to_json }
    end
    
    def filename(directory)
      kind = payload.class.to_s =~ /Fiveruns::Dash::(\w+)Payload/
      name = kind ? kind[1] : 'unknown'
      ::File.join(directory, "#{guid}.#{name}.json")
    end
    
  end
  
end