# Only configure Sidekiq if Redis is available
begin
  if ENV['REDIS_URL'].present?
    # Test Redis connection first
    redis_client = Redis.new(url: ENV['REDIS_URL'])
    redis_client.ping
    redis_client.disconnect
    
    Sidekiq.strict_args!(:warn)
    Sidekiq.configure_server do |config|
      config.redis = { url: ENV['REDIS_URL'] }
    end
    
    Sidekiq.configure_client do |config|
      config.redis = { url: ENV['REDIS_URL'] }
    end
    
    Rails.logger.info "Sidekiq configured with Redis at #{ENV['REDIS_URL']}"
  else
    Rails.logger.info "No Redis URL configured, using default ActiveJob adapter"
  end
rescue StandardError => e
  Rails.logger.warn "Could not connect to Redis (#{e.message}), using default ActiveJob adapter"
end
