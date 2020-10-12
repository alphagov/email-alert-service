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
      all_configs = YAML.safe_load(ERB.new(File.read(app_root + "config/rabbitmq.yml")).result, [], [], true)
      environment_config = all_configs.fetch(environment)

      @rabbitmq ||= symbolize_keys(environment_config).freeze
    end

    def redis_config
      symbolize_keys(YAML.safe_load(ERB.new(File.read(app_root + "config/redis.yml")).result, [], [], true))
    end

    def logger
      @logger ||= begin
        Logger.new(STDOUT, "daily")
      end
    end

  private

    def symbolize_keys(obj)
      return obj.map { |a| symbolize_keys(a) } if obj.is_a?(Array)

      if obj.is_a?(Hash)
        return obj.inject({}) do |inner_hash, (key, value)|
          inner_hash.merge(key.to_sym => symbolize_keys(value))
        end
      end
      obj
    end
  end

  class MultiIO
    def initialize(*targets)
      @targets = targets
    end

    def write(*args)
      @targets.each { |t| t.write(*args) }
    end

    def close
      @targets.each(&:close)
    end
  end
end
