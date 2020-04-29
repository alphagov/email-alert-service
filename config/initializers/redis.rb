module EmailAlertService
  def self.services(name, service = nil)
    @services ||= {}

    if service
      @services[name] = service
      true
    elsif @services[name]
      @services[name]
    else
      raise ServiceNotRegisteredException.new(name)
    end
  end

  class ServiceNotRegisteredException < StandardError; end
end

EmailAlertService.services(
  :redis,
  Redis::Namespace.new(
    EmailAlertService.config.redis_config[:namespace],
    redis: Redis.new(EmailAlertService.config.redis_config),
  ),
)
