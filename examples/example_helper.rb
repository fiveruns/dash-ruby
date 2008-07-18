require 'fileutils'

directory = File.expand_path(File.dirname(__FILE__) << "/tmp")
FileUtils.mkdir directory rescue nil
ENV['DASH_UPDATE'] = "file://#{directory}"
