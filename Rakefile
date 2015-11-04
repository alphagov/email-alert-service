require 'airbrake/tasks'
require_relative "email_alert_service/environment"
require 'rspec/core/rake_task'

# The airbrake tasks rely on the Railsy "environment" task
# which is covered by the above require.
task :environment do; end

namespace :message_queue do
  desc "Run worker to consume messages from rabbitmq"
  task :consumer => [:environment] do
    GovukMessageQueueConsumer::Consumer.new(
      queue_name: "email_alert_service",
      exchange: "published_documents",
      processor: MessageProcessor.new,
      routing_key: "*.major.#"
    ).run
  end
end

RSpec::Core::RakeTask.new(:spec)

task(:default).clear
task :default => [:spec]
