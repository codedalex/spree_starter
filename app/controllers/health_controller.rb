class HealthController < ApplicationController
  # Skip authentication for health checks
  skip_before_action :verify_authenticity_token
  
  def show
    # Check database connectivity
    database_ok = check_database
    
    # Check Redis connectivity
    redis_ok = check_redis
    
    # Overall health status
    healthy = database_ok && redis_ok
    
    # Response data
    response_data = {
      status: healthy ? 'OK' : 'ERROR',
      timestamp: Time.current.iso8601,
      version: Rails.application.class.module_parent_name.underscore,
      environment: Rails.env,
      checks: {
        database: database_ok ? 'OK' : 'ERROR',
        redis: redis_ok ? 'OK' : 'ERROR'
      }
    }
    
    # Add additional info in development
    if Rails.env.development?
      response_data[:info] = {
        ruby_version: RUBY_VERSION,
        rails_version: Rails.version,
        products_count: Spree::Product.count,
        uptime: uptime_seconds
      }
    end
    
    status_code = healthy ? 200 : 503
    render json: response_data, status: status_code
  rescue => e
    render json: {
      status: 'ERROR',
      timestamp: Time.current.iso8601,
      error: e.message,
      checks: {
        database: 'UNKNOWN',
        redis: 'UNKNOWN'
      }
    }, status: 503
  end
  
  private
  
  def check_database
    ActiveRecord::Base.connection.execute('SELECT 1')
    true
  rescue
    false
  end
  
  def check_redis
    # Skip Redis check in production if REDIS_URL is not set
    redis_url = ENV['REDIS_URL']
    return true if Rails.env.production? && redis_url.blank?
    
    if defined?(Redis) && redis_url.present?
      redis = Redis.new(url: redis_url)
      redis.ping == 'PONG'
    else
      true # Skip Redis check if not configured
    end
  rescue
    # Don't fail health check if Redis is not available in production
    Rails.env.production? ? true : false
  end
  
  def uptime_seconds
    return unless defined?(@start_time)
    Time.current - @start_time
  end
end
