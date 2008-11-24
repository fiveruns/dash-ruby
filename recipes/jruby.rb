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
        
        def self.address
          "com.sun.management.jmxremote.localConnectorAddress"
        end
        
        def self.connection
          vm = VirtualMachine::attach(Process.pid.to_s)
          connector_address = vm.getAgentProperties().getProperty(address)
          if connector_address.nil? 
             # puts "JMX Agent not running. starting now"
             agent = vm.getSystemProperties().getProperty("java.home") + "/" + "lib" + "/" + "management-agent.jar"
             # puts "Loading JMX Agent : #{agent}"
             vm.loadAgent(agent)
             # agent is started, get the connector address
             connector_address = vm.getAgentProperties().getProperty(CONNECTOR_ADDRESS)
          end
          # puts "connector address #{connector_address.to_s[0..50]}"
          url = JMXServiceURL.new connector_address
          connector = JMXConnectorFactory::connect url, HashMap.new
          connector.mbean_server_connection
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
      mbean =  jruby_mbean = ManagementFactory::newPlatformMXBeanProxy(Fiveruns::Dash::JRuby.connection,
        "org.jruby:type=Runtime,name=#{JRuby.runtime.hashCode},service=ClassCache", 
        ClassCacheMBean::java_class)
      Integer(mbean.get_live_class_count)
    end

    metrics.absolute :class_load_count, "Class Load Count", "Number of loaded classes" do 
      mbean =  jruby_mbean = ManagementFactory::newPlatformMXBeanProxy(Fiveruns::Dash::JRuby.connection,
        "org.jruby:type=Runtime,name=#{JRuby.runtime.hashCode},service=ClassCache", 
        ClassCacheMBean::java_class)
      Integer(mbean.get_class_load_count)
    end

    metrics.absolute :class_reuse_count, "Class Reuse Count", "Number of reused classes" do 
      mbean =  jruby_mbean = ManagementFactory::newPlatformMXBeanProxy(Fiveruns::Dash::JRuby.connection,
        "org.jruby:type=Runtime,name=#{JRuby.runtime.hashCode},service=ClassCache", 
        ClassCacheMBean::java_class)
      Integer(mbean.get_class_reuse_count)
    end

    # ############
    # JITCompiler MBean
    # ############
  
    import org.jruby.compiler.JITCompilerMBean
  
    metrics.absolute :average_code_size, "Average Code Size", "Average Code Size" do 
      mbean =  jruby_mbean = ManagementFactory::newPlatformMXBeanProxy(Fiveruns::Dash::JRuby.connection,
        "org.jruby:type=Runtime,name=#{JRuby.runtime.hashCode},service=JITCompiler", 
        JITCompilerMBean::java_class)
      Integer(mbean.average_code_size)
    end

    metrics.absolute :compile_count, "Compile Count", "Compile Count" do 
      mbean =  jruby_mbean = ManagementFactory::newPlatformMXBeanProxy(Fiveruns::Dash::JRuby.connection,
        "org.jruby:type=Runtime,name=#{JRuby.runtime.hashCode},service=JITCompiler", 
        JITCompilerMBean::java_class)
      Integer(mbean.compile_count)
    end
    metrics.absolute :compile_success_count, "Compile Success Count", "Compile Success Count" do 
      mbean =  jruby_mbean = ManagementFactory::newPlatformMXBeanProxy(Fiveruns::Dash::JRuby.connection,
        "org.jruby:type=Runtime,name=#{JRuby.runtime.hashCode},service=JITCompiler", 
        JITCompilerMBean::java_class)
      Integer(mbean.success_count)
    end
    metrics.absolute :compile_fail_count, "Compile Fail Count", "Compile Fail Count" do 
      mbean =  jruby_mbean = ManagementFactory::newPlatformMXBeanProxy(Fiveruns::Dash::JRuby.connection,
        "org.jruby:type=Runtime,name=#{JRuby.runtime.hashCode},service=JITCompiler", 
        JITCompilerMBean::java_class)
      Integer(mbean.fail_count)
    end

    metrics.absolute :average_compile_time, "Average Compile Time", "Average Compile Time" do 
      mbean =  jruby_mbean = ManagementFactory::newPlatformMXBeanProxy(Fiveruns::Dash::JRuby.connection,
        "org.jruby:type=Runtime,name=#{JRuby.runtime.hashCode},service=JITCompiler", 
        JITCompilerMBean::java_class)
      Integer(mbean.average_compile_time)
    end

  end
  
end