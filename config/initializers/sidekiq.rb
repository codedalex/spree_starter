Sidekiq.strict_args!(:warn) # https://github.com/sidekiq/sidekiq/blob/main/docs/7.0-Upgrade.md#strict-arguments

# Only configure Sidekiq if Redis is available
if ENV['REDIS_URL'].present?
  Sidekiq.configure_server do |config|
    config.redis = { url: ENV['REDIS_URL'] }
  end
  
  Sidekiq.configure_client do |config|
    config.redis = { url: ENV['REDIS_URL'] }
  end
else
  # In production without Redis, we'll use the default ActiveJob adapter
  Rails.logger.info "No Redis URL configured, Sidekiq will not be available"
end
