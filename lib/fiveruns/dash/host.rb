module Fiveruns::Dash

  class Host
  
    UNIXES = [:osx, :linux, :solaris]
    
    def initialize
      configure_host
    end
  
    def architecture
      @architecture
    end
  
    def os_name
      @os_name
    end
  
    def os_version
      @os_version
    end
  
    def big_endian?
      @big_endian
    end

    def little_endian?
      !@big_endian
    end

    def ip_addresses
      @ip_addresses
    end
  
    def os_name_match?(name)
      platform == name
    end
  
    def platform
      execute_on_osx { return :osx }
      execute_on_windows { return :windows }
      execute_on_linux { return :linux }
      execute_on_solaris { return :solaris }
      :unknown
    end
  
    def execute_on_unix(&block)
      UNIXES.each do |unix|
        send "execute_on_#{unix}", &block
      end
    end

    def execute_on_osx(&block)
      block.call if RUBY_PLATFORM =~ /darwin/
    end

    def execute_on_linux(&block)
      block.call if RUBY_PLATFORM =~ /linux/
    end

    def execute_on_solaris(&block)
      block.call if RUBY_PLATFORM =~ /solaris/
    end
  
    def execute_on_windows(&block)
      block.call if RUBY_PLATFORM =~ /win32|i386-mingw32/
    end

    def hostname
      @hostname
    end
  
    def ip_address
      address = ip_addresses[0]
      address ? address[1] : "127.0.0.1"
    end
  
    def mac_address
      @mac_address
    end

    def configure_host
      @hostname ||= `hostname`.strip!
      @big_endian = ([123].pack("s") == [123].pack("n"))
      case RUBY_PLATFORM
      when /darwin|linux/
        begin # use Sys::Uname library if present
          require 'sys/uname'
          @os_name = Sys::Uname.sysname
          @architecture = Sys::Uname.machine
          @os_version = Sys::Uname.release 
        rescue LoadError # otherwise shell out and scrape out the information
          @os_name = `uname -s`.strip
          @architecture = `uname -p`.strip
          @os_version = `uname -r`.strip
        end
      when /win32|i386-mingw32/
        require "dl/win32"
        getVersionEx = Win32API.new("kernel32", "GetVersionExA", ['P'], 'L')
    
        lpVersionInfo = [148, 0, 0, 0, 0].pack("LLLLL") + "�0" * 128 
        getVersionEx.Call lpVersionInfo
  
        dwOSVersionInfoSize, dwMajorVersion, dwMinorVersion, dwBuildNumber, dwPlatformId, szCSDVersion = lpVersionInfo.unpack("LLLLLC128")
        @os_name = ['Windows 3.1/3.11', 'Windows 95/98', 'Windows NT/XP'][dwPlatformId]
        @os_version = "#{dwMajorVersion}.#{dwMinorVersion}"
        @architecture = ENV['PROCESSOR_ARCHITECTURE']
      end

      @ip_addresses = []
      begin # use Sys::Host library if present
        require 'sys/host'
        Sys::Host.ip_addr.each do |ip|
          addresses << ip
        end
      rescue LoadError # otherwise shell out and scrape out the information
        execute_on_osx  do
          ifconfig = `ifconfig`
          x = 0
          while true
            if ifconfig =~ /en#{x}:/
              x+=1
            else
              break
            end
          end
          x.times do |dev|
            ifconfig = `ifconfig en#{dev}`
            ifconfig.scan(/ether ([0-9a-f\:]*) /) do |mac_address|
              @mac_address ||= mac_address[0]
            end
            ifconfig.scan(/inet ([0-9\.]*) /) { |ip| @ip_addresses << ["en#{dev}", ip[0]] }
          end
        end
        execute_on_solaris do
          arp = `/usr/sbin/arp -an`.split("\n")
          re = /^(\w+).*?(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}).*((([a-f0-9]{2}):){5}[a-f0-9]{2})/
          arp.find do |line|
            line =~ re
          end
          @ip_addresses << $2
          @mac_address = $3
        end
        execute_on_linux do
          ifconfig = `/sbin/ifconfig`
          x = 0
          while true
            if ifconfig =~ /eth#{x} /
              x+=1
            else
              break
            end
          end
          x.times do |dev|
            ifconfig = `/sbin/ifconfig eth#{dev}`
            ifconfig.scan(/HWaddr ([0-9A-Fa-f\:]*) /) do |mac_address|
              @mac_address ||= mac_address[0]
            end
            ifconfig.scan(/inet addr:([0-9\.]*) /) { |ip| @ip_addresses << ["eth#{dev}", ip[0]] }
          end
          @mac_address ||= "#{@hostname}-UNKNOWN-MAC"
        end
        execute_on_windows do
          addrs = Socket.getaddrinfo(Socket.gethostname, 80)
          addrs.each do |addr|
            @ip_addresses << ['eth0', addr[3]]
          end
        end
      end
    end
  end

end