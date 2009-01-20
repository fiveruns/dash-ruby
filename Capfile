# =========================
# = CHANGE THESE SETTINGS =
# =========================

set :user, "deploy"

role :gem, "manage-web1.fiveruns.com"
role :gem, "manage-web2.fiveruns.com"
set :gateway, 'dmz.fiveruns.com:28282'


load 'deploy' if respond_to?(:namespace) # cap2 differentiator

require 'lib/fiveruns/dash/version.rb'
namespace :gems do

  desc "Upload the latest Dash gem to production"
  task :push, :roles => :gem do
    filename = "fiveruns_dash-#{Fiveruns::Dash::Version::STRING}.gem"
    FileUtils.cp "pkg/#{filename}", filename
    upload filename, "/var/www/static/gems", :via => :scp
    run 'cd /var/www/static ; gem generate_index -q'
  end
end
