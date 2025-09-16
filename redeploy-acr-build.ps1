# Redeploy Golf n Vibes to Azure using ACR Build (no Docker Desktop required)
# This fixes the Cloudflare subdomain connection issue

Write-Host "Redeploying Golf n Vibes with Port 80 using ACR Build..." -ForegroundColor Green

# Set variables
$resourceGroup = "golf-n-vibes-rg"
$acrName = "golfvibesacr2025"
$containerName = "golf-n-vibes-web"
$imageName = "spree-golf:port80"

# Check if logged in to Azure
Write-Host "Checking Azure CLI login..." -ForegroundColor Yellow
$account = az account show 2>$null
if (-not $account) {
    Write-Host "Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

# Build image using ACR Build (no local Docker required)
Write-Host "Building Docker image with port 80 using ACR Build..." -ForegroundColor Yellow
$buildResult = az acr build --registry $acrName --image $imageName --file Dockerfile.azure .
if ($LASTEXITCODE -ne 0) {
    Write-Host "ACR build failed" -ForegroundColor Red
    exit 1
}

# Delete existing container instance
Write-Host "Removing existing container instance..." -ForegroundColor Yellow
az container delete --resource-group $resourceGroup --name $containerName --yes

# Wait for deletion to complete
Write-Host "Waiting for container deletion..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Get ACR credentials
$acrPassword = az acr credential show --name $acrName --query "passwords[0].value" --output tsv

# Create new container instance with port 80
Write-Host "Creating new container instance with port 80..." -ForegroundColor Yellow
$createResult = az container create `
    --resource-group $resourceGroup `
    --name $containerName `
    --image "${acrName}.azurecr.io/${imageName}" `
    --registry-login-server "${acrName}.azurecr.io" `
    --registry-username $acrName `
    --registry-password $acrPassword `
    --dns-name-label "golf-n-vibes-app" `
    --ports 80 `
    --environment-variables `
        RAILS_ENV=production `
        RAILS_SERVE_STATIC_FILES=true `
        RAILS_LOG_TO_STDOUT=true `
        DATABASE_URL="postgresql://golfadmin:GolfVibes2025!@golf-n-vibes-db.postgres.database.azure.com/golf_n_vibes_production?sslmode=require" `
        SECRET_KEY_BASE="golf_n_vibes_secret_key_base_2025_production_final" `
        DISABLE_DATABASE_ENVIRONMENT_CHECK=1 `
        RAILS_FORCE_SSL=false `
        RAILS_ASSUME_SSL=false `
    --location "switzerlandnorth" `
    --memory 2 `
    --cpu 1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Container creation failed" -ForegroundColor Red
    exit 1
}

Write-Host "Container deployed successfully!" -ForegroundColor Green
Write-Host "New URL: http://golf-n-vibes-app.switzerlandnorth.azurecontainer.io" -ForegroundColor Cyan

# Wait for container to be ready
Write-Host "Waiting for container to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 90

# Test the new deployment
Write-Host "Testing container accessibility..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://golf-n-vibes-app.switzerlandnorth.azurecontainer.io" -Method Head -TimeoutSec 30
    Write-Host "Container is accessible! Status: $($response.StatusCode)" -ForegroundColor Green
    
    # Test subdomain after deployment
    Write-Host "Testing subdomain..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    try {
        $subdomainResponse = Invoke-WebRequest -Uri "http://golfnvibes.codedalex.com" -Method Head -TimeoutSec 15
        Write-Host "Subdomain is working! Status: $($subdomainResponse.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "Subdomain still timing out. You may need to update Cloudflare settings." -ForegroundColor Orange
        Write-Host "Check Cloudflare DNS settings for golfnvibes.codedalex.com" -ForegroundColor Orange
    }
} catch {
    Write-Host "Container may still be starting up. Check status in Azure Portal." -ForegroundColor Orange
}

Write-Host "Deployment complete!" -ForegroundColor Green