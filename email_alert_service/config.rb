require "pathname"
require "yaml"
require "logger"
require "erb"

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
      all_configs = YAML.load(ERB.new(File.read(app_root+"config/rabbitmq.yml")).result)
      environment_config = all_configs.fetch(environment)

      @rabbitmq ||= symbolize_keys(environment_config).freeze
    end

    def redis_config
      symbolize_keys(YAML.load(ERB.new(File.read(app_root+"config/redis.yml")).result))
    end

    def logger
      logfile = File.open(app_root+"log/#{environment}.log", "a")

      logfile.sync = true

      @logger ||= Logger.new(logfile, "daily")
    end

  private

    def symbolize_keys(hash)
      hash.inject({}) do |hash, (key, value)|
        hash.merge(key.to_sym => value)
      end
    end
  end
end
