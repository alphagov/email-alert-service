require "pathname"
require "yaml"
require "logger"

module EmailAlertService
  class Config
    def initialize(environment)
      @environment = environment || "development"
    end

    attr_reader :environment

    def app_root
      @app_root ||= Pathname.new(File.expand_path(File.join(File.dirname(__FILE__), "..")))
    end

    def rabbitmq
      all_configs = YAML.load(File.open(app_root+"config/rabbitmq.yml"))
      environment_config = all_configs.fetch(environment)

      @rabbitmq ||= environment_config.freeze
    end

    def logger
      logfile = File.open(app_root+"log/#{environment}.log", "a")

      logfile.sync = true
      $stderr = $stdout = logfile

      @logger ||= Logger.new(logfile, "daily")
    end
  end
end
