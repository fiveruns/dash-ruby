# = Starting the example
#
# 1. Connect to self; a 'compile check' and should run to completion (no useful metrics)
#
#   jruby jruby_jmx.rb
#                      
# 2. Same as above, but prestarts JMX in self
#
#   jruby --manage jruby_jmx.rb
# 
# 3. Connect to some jruby process (eg, jruby -S jirb) and get more interesting numbers
#    (more interesting than all zeros)
#
#   JRUBY_SELF_PID=<some jruby process> jruby jruby_jmx.rb
#

unless RUBY_PLATFORM[/java/]
  abort "This example requires JRuby"
end

# TODO: Refactor code, remove debugging comments & output

require 'java'
import com.sun.tools.attach.VirtualMachine
import javax.management.remote.JMXServiceURL
import javax.management.remote.JMXConnectorFactory
import java.lang.management.ManagementFactory
import java.util.HashMap

CONNECTOR_ADDRESS = "com.sun.management.jmxremote.localConnectorAddress"
PID = ENV["JRUBY_SELF_PID"] || Process.pid.to_s
puts "PID: #{PID}"
vm = VirtualMachine::attach(PID)
puts "attached to VM(#{PID})"
# get the connector address
connector_address = vm.getAgentProperties().getProperty(CONNECTOR_ADDRESS)

# no connector address, so we start the JMX agent
if connector_address.nil? 
    puts "JMX Agent not running. starting now"
    agent = vm.getSystemProperties().getProperty("java.home") + "/" + "lib" + "/" + "management-agent.jar"
    puts "Loading JMX Agent : #{agent}"
    vm.loadAgent(agent)
    # agent is started, get the connector address
    connector_address = vm.getAgentProperties().getProperty(CONNECTOR_ADDRESS)
end
puts "connector address #{connector_address.to_s[0..50]}"
url = JMXServiceURL.new connector_address

connector = JMXConnectorFactory::connect url, HashMap.new
mbsc = connector.mbean_server_connection
#mbsc.methods.sort.each{ |m| puts m}

#ManagementFactory.methods.sort.each{|m| puts m}
#plat_serv.methods.sort.each{ |m| puts m}
#x = plat_serv.query_mbeans(nil, nil )
#puts "x = #{x.inspect}"
#x.each{ |item| puts item.inspect; puts x.methods.sort; puts "===" }
#    plat_serv.get_domains.inspect


import org.jruby.management.ClassCacheMBean

jruby_cache_mbean = ManagementFactory::newPlatformMXBeanProxy mbsc, "org.jruby:type=Runtime,name=#{JRuby.runtime.hashCode},service=ClassCache", ClassCacheMBean::java_class
puts "load: #{jruby_cache_mbean.get_class_load_count}"
puts "reuse: #{jruby_cache_mbean.get_class_reuse_count}"
puts "live: #{jruby_cache_mbean.get_live_class_count}"

import org.jruby.compiler.JITCompilerMBean

jruby_jit_mbean = ManagementFactory::newPlatformMXBeanProxy mbsc, "org.jruby:type=Runtime,name=#{JRuby.runtime.hashCode},service=JITCompiler", JITCompilerMBean::java_class
puts "average code size: #{jruby_jit_mbean.average_code_size}"
puts "code size: #{jruby_jit_mbean.code_size}"
puts "largest code size: #{jruby_jit_mbean.largest_code_size}"

puts "compile count: #{jruby_jit_mbean.compile_count}"
puts "average compile time: #{jruby_jit_mbean.average_compile_time}"
puts "fail count: #{jruby_jit_mbean.fail_count}"
puts "success count: #{jruby_jit_mbean.success_count}"

#jruby_mbean.methods.sort.each{ |m| puts m}
# memory_mbean = ManagementFactory::newPlatformMXBeanProxy mbsc, "java.lang:type=Memory", MemoryMXBean::java_class
# memory_mbean.verbose = true
# puts "Heap Memory Usage   : #{memory_mbean.heapMemoryUsage}"
# puts "NonHeap Memory Usage: #{memory_mbean.nonHeapMemoryUsage}"
# memory_mbean.gc
# puts "Heap Memory Usage   : #{memory_mbean.heapMemoryUsage}"
# puts "NonHeap Memory Usage: #{memory_mbean.nonHeapMemoryUsage}"
# memory_mbean.methods.sort.each{ |m| puts m }
