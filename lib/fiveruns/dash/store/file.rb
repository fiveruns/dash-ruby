module Fiveruns::Dash::Store
  
  module File
    
    def store_file(*uris)
      uris.each do |uri|
        directory = uri.path
        write_to filename(directory)
      end
    end
    
    def write_to(path)
      ::File.open(path, 'w') { |f| f.write @payload.to_fjson }
    end
    
    def filename(directory)
      kind = payload.class.name =~ /(\w+)Payload/
      name = kind ? $1 : 'unknown'
      ::File.join(directory, "#{guid}.#{name}.json")
    end
    
  end
  
end