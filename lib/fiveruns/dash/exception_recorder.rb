module Fiveruns::Dash
  
  class ExceptionRecorder
    
    def initialize(session)
      @session = session
    end
    
    def record(exception)
      exceptions << extract_data_from_exception(exception)
    end
    
    def data
      returning exceptions.dup do
        reset
      end
    end
    
    #######
    private
    #######
    
    def extract_data_from_exception(e)
      {
        :name => e.class.name,
        :message => e.message,
        :backtrace => e.backtrace
      }
    end

    def exceptions
      @exceptions ||= []
    end
    
    def reset
      exceptions.clear
    end
    
  end
  
end