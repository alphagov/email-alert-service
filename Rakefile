require 'airbrake/tasks'
require_relative "email_alert_service/environment"

# The airbrake tasks rely on the Railsy "environment" task
# which is covered by the above require.
task :environment do; end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

task default: [:spec]
