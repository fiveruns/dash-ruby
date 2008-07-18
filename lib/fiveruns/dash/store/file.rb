module Fiveruns::Dash::Store
  
  module File
    
    def store_file(*uris)
      uris.each do |uri|
        directory = uri.path
        write_to ::File.join(directory, "#{guid}.yml")
      end
    end
    
    def write_to(filename)
      ::File.open(filename, 'w') { |f| f.write payload.to_yaml }
    end
    
  end
  
end