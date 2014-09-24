require 'pathname'
require 'yaml'

module EmailAlertService
  class Config
    def initialize(environment)
      @environment = environment || 'development'
    end

    attr_reader :environment

    def app_root
      @app_root ||= Pathname.new(File.expand_path(File.join(File.dirname(__FILE__), '..')))
    end

    def rabbitmq
      @rabbitmq ||= YAML.load(File.open(app_root+'config/rabbitmq.yml')).fetch(environment).freeze
    end
  end
end
