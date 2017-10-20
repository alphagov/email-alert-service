require 'govuk_app_config'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

Dir.glob('lib/tasks/*.rake').each { |r| load r }

task default: [:lint, :spec]
