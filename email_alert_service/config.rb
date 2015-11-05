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

    def redis_config
      symbolize_keys(YAML.load(File.open(app_root+"config/redis.yml")))
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
