# ActiveJob configuration with graceful Redis fallback
Rails.application.configure do
  # Test Redis connection and fallback to async if not available
  begin
    if ENV['REDIS_URL'].present?
      redis_client = Redis.new(url: ENV['REDIS_URL'])
      redis_client.ping
      redis_client.disconnect
      config.active_job.queue_adapter = :sidekiq
      Rails.logger.info "ActiveJob configured to use Sidekiq with Redis"
    else
      config.active_job.queue_adapter = :async
      Rails.logger.info "ActiveJob configured to use async adapter (no Redis URL)"
    end
  rescue StandardError => e
    config.active_job.queue_adapter = :async
    Rails.logger.warn "ActiveJob falling back to async adapter due to Redis connection error: #{e.message}"
  end
end

# Handle job failures gracefully
class ActiveJob::Base
  rescue_from(StandardError) do |exception|
    Rails.logger.error "Job #{self.class.name} failed: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    # Don't re-raise in production to avoid breaking the application
    raise exception unless Rails.env.production?
  end
end