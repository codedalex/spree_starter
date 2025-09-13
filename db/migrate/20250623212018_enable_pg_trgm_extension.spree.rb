# This migration comes from spree (originally 20250530101236)
class EnablePgTrgmExtension < ActiveRecord::Migration[7.2]
  def up
    # Skip extension creation on Azure PostgreSQL as it's not allowed
    return if ENV['DATABASE_HOST']&.include?('azure.com')
    
    if supports_extensions? && extension_available?('pg_trgm') && !extension_enabled?('pg_trgm')
      begin
        enable_extension 'pg_trgm'
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.warn "Could not enable pg_trgm extension: #{e.message}"
        # Continue migration without the extension
      end
    end
  end

  def down
    return if ENV['DATABASE_HOST']&.include?('azure.com')
    
    if supports_extensions? && extension_available?('pg_trgm') && extension_enabled?('pg_trgm')
      disable_extension 'pg_trgm'
    end
  end
end
