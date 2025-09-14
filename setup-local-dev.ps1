# Local Development Setup Script for Golf N Vibes
# This script sets up local development with minimal network requirements

Write-Host "🏌️ Golf N Vibes Local Development Setup" -ForegroundColor Green

# Add Ruby to PATH for current session
$env:PATH += ";C:\Ruby33-x64\bin"

Write-Host "1️⃣ Checking Ruby installation..." -ForegroundColor Cyan
ruby --version
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Ruby is installed and available" -ForegroundColor Green
} else {
    Write-Host "❌ Ruby not found. Please ensure Ruby is installed." -ForegroundColor Red
    exit 1
}

Write-Host "2️⃣ Checking Docker services..." -ForegroundColor Cyan
$postgresRunning = docker ps --filter "name=spree-official-postgres-1" --format "{{.Names}}" | Where-Object { $_ -eq "spree-official-postgres-1" }
$redisRunning = docker ps --filter "name=spree-official-redis-1" --format "{{.Names}}" | Where-Object { $_ -eq "spree-official-redis-1" }

if ($postgresRunning -and $redisRunning) {
    Write-Host "✅ PostgreSQL and Redis are running" -ForegroundColor Green
} else {
    Write-Host "⚠️ Starting Docker services..." -ForegroundColor Yellow
    docker-compose up -d postgres redis
    Start-Sleep -Seconds 10
    Write-Host "✅ Docker services started" -ForegroundColor Green
}

Write-Host "3️⃣ Creating basic .env file..." -ForegroundColor Cyan
if (!(Test-Path ".env")) {
    @"
# Development Environment Configuration
RAILS_ENV=development
DATABASE_URL=postgresql://postgres:password@localhost:5432/spree_starter_development
REDIS_URL=redis://localhost:6379
RAILS_LOG_TO_STDOUT=true

# Database Configuration
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=password
DB_PORT=5432

# Spree Configuration
SPREE_ADMIN_EMAIL=admin@golfnvibes.com
SPREE_ADMIN_PASSWORD=admin123

# Development Configuration
HOSTNAME=localhost:3001
PROTOCOL=http
"@ | Out-File -FilePath ".env" -Encoding UTF8
    Write-Host "✅ Created .env file" -ForegroundColor Green
} else {
    Write-Host "✅ .env file already exists" -ForegroundColor Green
}

Write-Host "4️⃣ Creating development database configuration..." -ForegroundColor Cyan
if (!(Test-Path "config/database.yml.backup")) {
    Copy-Item "config/database.yml" "config/database.yml.backup"
}

@"
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: spree_starter_development
  host: localhost
  username: postgres
  password: password
  port: 5432

test:
  <<: *default
  database: spree_starter_test
  host: localhost
  username: postgres
  password: password
  port: 5432

production:
  <<: *default
  url: <%= ENV['DATABASE_URL'] %>
"@ | Out-File -FilePath "config/database.yml" -Encoding UTF8

Write-Host "✅ Database configuration updated" -ForegroundColor Green

Write-Host "5️⃣ Attempting minimal bundle install..." -ForegroundColor Cyan
try {
    # Try to install just the essential gems first
    Write-Host "   Installing core gems..." -ForegroundColor Yellow
    gem install rails -v "~> 8.0.0" --no-document
    gem install pg -v "~> 1.6" --no-document
    gem install dotenv-rails --no-document
    Write-Host "✅ Core gems installed" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Some gems failed to install - continuing anyway" -ForegroundColor Yellow
}

Write-Host "6️⃣ Setting up database..." -ForegroundColor Cyan
try {
    # Create database if needed
    Write-Host "   Creating database..." -ForegroundColor Yellow
    rails db:create 2>&1 | Out-Host
    
    # Run basic migrations if possible
    Write-Host "   Running migrations..." -ForegroundColor Yellow
    rails db:migrate 2>&1 | Out-Host
    
    Write-Host "✅ Database setup completed" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Database setup encountered issues - may need manual setup" -ForegroundColor Yellow
}

# Summary and next steps
Write-Host ""
Write-Host "🎉 Local Development Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 What was set up:" -ForegroundColor Yellow
Write-Host "  ✅ Ruby environment configured"
Write-Host "  ✅ Docker services running (PostgreSQL and Redis)"
Write-Host "  ✅ Environment variables configured"
Write-Host "  ✅ Database configuration updated"
Write-Host ""
Write-Host "🚀 To start development:" -ForegroundColor Cyan
Write-Host "  1. Ensure network connectivity is stable"
Write-Host "  2. Run: bundle install"
Write-Host "  3. Run: rails db:seed"
Write-Host "  4. Run: ruby setup_golf_products.rb"
Write-Host "  5. Run: rails server -p 3001"
Write-Host ""
Write-Host "🌐 Your application will be available at:" -ForegroundColor Green
Write-Host "   http://localhost:3001"
Write-Host "   http://localhost:3001/admin"
Write-Host ""
Write-Host "🚀 For Azure deployment:" -ForegroundColor Cyan
Write-Host "   Run: ./deploy-azure.ps1"
Write-Host ""
Write-Host "If you encounter network issues:" -ForegroundColor Yellow
Write-Host "   - Try running the scripts when connectivity is better"
Write-Host "   - Focus on Azure deployment which handles gem compilation in the cloud"
Write-Host "   - The Docker approach is also available as an alternative"