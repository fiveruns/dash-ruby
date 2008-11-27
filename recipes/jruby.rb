# TODO Error Handling
# TODO cache VM and/or connection
# TODO singleton class around vm instance to avoid passing it all over the place
#      should be able to do vm.connector_avaialble? and vm.load_management_agent
# TODO cache mbeans
# TODO more metprogramming in metrics area, pick up names and descriptions 
#      of attributes direct from mbean and expose all as metrics

if RUBY_PLATFORM[/java/]
  
  require 'java'
  
  import com.sun.tools.attach.VirtualMachine
  import javax.management.remote.JMXServiceURL 
  import javax.management.remote.JMXConnectorFactory
  import java.lang.management.ManagementFactory
  import java.util.HashMap
  
  module Fiveruns
    module Dash
      module JRuby
        
        JMX_ADDRESS_PROPERTY = "com.sun.management.jmxremote.localConnectorAddress"
        
        def self.connector_address_property( vm )
          vm.getAgentProperties().getProperty(JMX_ADDRESS_PROPERTY)
        end
        
        def self.connector_available?( vm )
          !connector_address_property( vm ).nil?
        end
        
        def self.load_management_agent( vm )
          agent = vm.getSystemProperties().getProperty("java.home") + "/" + "lib" + "/" + "management-agent.jar"
          vm.loadAgent( agent ) 
        end
        
        def self.connector_address( vm )
          load_management_agent( vm ) unless connector_available?( vm ) 
          connector_address_property( vm )
        end
        
        def self.connection #cache somehow ?  instance variable?  Not sure we're in a class ?
          vm = VirtualMachine::attach( Process.pid.to_s )
          url = JMXServiceURL.new( connector_address( vm ) )
          connector = JMXConnectorFactory::connect url, HashMap.new
          server_connection = connector.mbean_server_connection
          server_connection
        end
        
        def self.object_name(service_name)
          "org.jruby:type=Runtime,name=#{::JRuby.runtime.hashCode},service=#{service_name}"
        end
        # e.g. mbean( "ClassCache", ClassCacheMBean::java_class)
        # shold be able to DRY further - How to turn "ClassCache" into ClassCacheMBean::java_class
        # not sure the pattern holds for everything, but it hold for everything here so far.
        def self.mbean( service_name, java_class) # cache somehow? map lookup ? only need each bean proxy once.
          ManagementFactory::newPlatformMXBeanProxy(connection, object_name(service_name), java_class)
        end
          
      end
    end
  end

  Fiveruns::Dash.register_recipe :jruby, :url => 'http://dash.fiveruns.com' do |metrics|

    # ############
    # Class Cache MBean
    # ############
  
    import org.jruby.management.ClassCacheMBean
  
    metrics.absolute :live_class_count, "Live Class Count", "Number of active classes" do 
      Integer(Fiveruns::Dash::JRuby.mbean("ClassCache", ClassCacheMBean::java_class).get_live_class_count)
    end
    metrics.absolute :class_load_count, "Class Load Count", "Number of loaded classes" do 
      Integer(Fiveruns::Dash::JRuby.mbean("ClassCache", ClassCacheMBean::java_class).get_class_load_count)
    end
    metrics.absolute :class_reuse_count, "Class Reuse Count", "Number of reused classes" do 
      Integer(Fiveruns::Dash::JRuby.mbean("ClassCache", ClassCacheMBean::java_class).get_class_reuse_count)
    end

    # ############
    # JITCompiler MBean
    # ############
  
    import org.jruby.compiler.JITCompilerMBean
  
    metrics.absolute :average_code_size, "Average Code Size", "Average Code Size" do 
      Integer(Fiveruns::Dash::JRuby.mbean("JITCompiler", JITCompilerMBean::java_class).average_code_size)
    end
    metrics.absolute :compile_count, "Compile Count", "Compile Count" do 
      Integer(Fiveruns::Dash::JRuby.mbean("JITCompiler", JITCompilerMBean::java_class).compile_count)
    end
    metrics.absolute :compile_success_count, "Compile Success Count", "Compile Success Count" do 
      Integer(Fiveruns::Dash::JRuby.mbean("JITCompiler", JITCompilerMBean::java_class).success_count)
    end
    metrics.absolute :compile_fail_count, "Compile Fail Count", "Compile Fail Count" do 
      Integer(Fiveruns::Dash::JRuby.mbean("JITCompiler", JITCompilerMBean::java_class).fail_count)
    end
    metrics.absolute :average_compile_time, "Average Compile Time", "Average Compile Time" do 
      Integer(Fiveruns::Dash::JRuby.mbean("JITCompiler", JITCompilerMBean::java_class).average_compile_time)
    end

  end
  
end