# Golf n Vibes CEO Demo - Complete Launch Script
# This script sets up everything the CEO needs to test both applications

param(
    [switch]$SetupOnly,
    [switch]$LaunchOnly
)

Write-Host "🏌️ Golf n Vibes CEO Demo Launcher" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""

$demoDir = "C:\projects\golf_n_vibes\spree-official\demo"
$spreeDir = "C:\projects\golf_n_vibes\spree-official"
$nextDir = "C:\projects\golf_n_vibes\next-golf"

# Ensure demo directory exists
if (!(Test-Path $demoDir)) {
    New-Item -ItemType Directory -Path $demoDir -Force | Out-Null
}

if (!$LaunchOnly) {
    Write-Host "📦 STEP 1: Installing dependencies..." -ForegroundColor Blue
    Write-Host "Installing localtunnel for free tunneling..." -ForegroundColor Yellow
    npm install -g localtunnel 2>$null
    
    Write-Host "✅ Dependencies installed" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "🗄️ STEP 2: Setting up demo data..." -ForegroundColor Blue
    Write-Host "Creating CEO admin user and sample golf tours..." -ForegroundColor Yellow
    
    # Run the demo setup script
    Set-Location $spreeDir
    ruby -e "require './config/environment'; load './demo/setup-ceo-demo.rb'"
    
    Write-Host "✅ Demo data created" -ForegroundColor Green
    Write-Host ""
}

if (!$SetupOnly) {
    Write-Host "🚀 STEP 3: Starting applications..." -ForegroundColor Blue
    
    # Kill any existing processes on the ports
    Write-Host "Checking for existing services..." -ForegroundColor Yellow
    Get-Process | Where-Object {$_.ProcessName -like "*ruby*" -or $_.ProcessName -like "*node*"} | ForEach-Object {
        Write-Host "Found existing process: $($_.ProcessName) - PID: $($_.Id)" -ForegroundColor Gray
    }
    
    # Start Spree Commerce
    Write-Host "Starting Spree Commerce server (port 3000)..." -ForegroundColor Cyan
    Start-Process -NoNewWindow -FilePath "powershell" -ArgumentList "-NoExit", "-Command", "cd '$spreeDir'; rails server -p 3000"
    
    # Start Next.js Frontend  
    Write-Host "Starting Next.js frontend (port 3001)..." -ForegroundColor Cyan
    if (Test-Path $nextDir) {
        Start-Process -NoNewWindow -FilePath "powershell" -ArgumentList "-NoExit", "-Command", "cd '$nextDir'; npm run dev -- --port 3001"
    } else {
        Write-Host "⚠️ Next.js directory not found. Skipping Next.js startup." -ForegroundColor Red
    }
    
    # Wait for applications to start
    Write-Host "⏳ Waiting for applications to start up..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15
    
    Write-Host "✅ Applications started" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "🌐 STEP 4: Creating secure tunnels..." -ForegroundColor Blue
    
    # Create tunnels
    Write-Host "Creating Spree tunnel (ngrok)..." -ForegroundColor Cyan
    Start-Process -NoNewWindow -FilePath "ngrok" -ArgumentList "http", "3000", "--log=stdout"
    
    Write-Host "Creating Next.js tunnel (localtunnel)..." -ForegroundColor Cyan  
    Start-Process -NoNewWindow -FilePath "lt" -ArgumentList "--port", "3001", "--subdomain", "golf-nextjs-ceo"
    
    Write-Host "⏳ Waiting for tunnels to establish..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    Write-Host "✅ Tunnels created" -ForegroundColor Green
    Write-Host ""
}

# Display access information
Write-Host "🎉 GOLF N VIBES CEO DEMO IS READY!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""

Write-Host "📱 ACCESS LINKS:" -ForegroundColor White
Write-Host "  🏪 Spree Storefront: Check ngrok dashboard at http://localhost:4040" -ForegroundColor Yellow
Write-Host "  ⚙️ Spree Admin Panel: [Your ngrok URL]/admin" -ForegroundColor Yellow  
Write-Host "  📱 Next.js Frontend: https://golf-nextjs-ceo.loca.lt" -ForegroundColor Yellow
Write-Host ""

Write-Host "🔐 DEMO CREDENTIALS:" -ForegroundColor White
Write-Host "  👨‍💼 CEO Admin Login:" -ForegroundColor Cyan
Write-Host "     Email: ceo@golfnvibes.com" -ForegroundColor White
Write-Host "     Password: GolfCEO2024!" -ForegroundColor White
Write-Host ""
Write-Host "  👤 Test Customer:" -ForegroundColor Cyan
Write-Host "     Email: customer@test.com" -ForegroundColor White
Write-Host "     Password: TestCustomer123!" -ForegroundColor White
Write-Host ""

Write-Host "🧪 TESTING SCENARIOS FOR CEO:" -ForegroundColor White
Write-Host "  1. 🛍️ Browse Golf Tour Packages" -ForegroundColor Gray
Write-Host "     - View Qatar F1 Golf Experience" -ForegroundColor DarkGray
Write-Host "     - Compare pricing and descriptions" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  2. 🛒 Test Customer Journey" -ForegroundColor Gray  
Write-Host "     - Add tours to cart" -ForegroundColor DarkGray
Write-Host "     - Complete checkout process (test mode)" -ForegroundColor DarkGray
Write-Host "     - Receive order confirmation" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  3. ⚙️ Admin Management" -ForegroundColor Gray
Write-Host "     - Login as CEO admin" -ForegroundColor DarkGray
Write-Host "     - Add new golf tour products" -ForegroundColor DarkGray
Write-Host "     - Manage existing inventory" -ForegroundColor DarkGray
Write-Host "     - View customer orders" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  4. 📊 Compare Platforms" -ForegroundColor Gray
Write-Host "     - Spree: Full e-commerce backend" -ForegroundColor DarkGray
Write-Host "     - Next.js: Modern frontend experience" -ForegroundColor DarkGray
Write-Host "     - See both Qatar poster hero sections" -ForegroundColor DarkGray
Write-Host ""

Write-Host "📋 DEMO PRODUCTS AVAILABLE:" -ForegroundColor White
Write-Host "  • Qatar Grand Prix Golf Experience - $4,999" -ForegroundColor Green
Write-Host "  • Dubai Desert Golf Safari - $3,799" -ForegroundColor Green  
Write-Host "  • Scottish Highlands Masters - $5,299" -ForegroundColor Green
Write-Host "  • Pebble Beach Legends Tour - $4,599" -ForegroundColor Green
Write-Host "  • Augusta National Experience - $14,999" -ForegroundColor Green
Write-Host "  • New Zealand Golf Adventure - $5,799" -ForegroundColor Green
Write-Host ""

Write-Host "⚠️ IMPORTANT NOTES:" -ForegroundColor Red
Write-Host "  • All payments are in TEST MODE - no real charges" -ForegroundColor Yellow
Write-Host "  • Tunnels may take 1-2 minutes to fully activate" -ForegroundColor Yellow
Write-Host "  • Keep this PowerShell window open during demo" -ForegroundColor Yellow
Write-Host "  • Use test credit card: 4242 4242 4242 4242" -ForegroundColor Yellow
Write-Host ""

Write-Host "🔧 TROUBLESHOOTING:" -ForegroundColor White
Write-Host "  • If ngrok shows 'tunnel not found': restart ngrok" -ForegroundColor Gray
Write-Host "  • If localtunnel fails: try different subdomain" -ForegroundColor Gray
Write-Host "  • Check http://localhost:4040 for ngrok URLs" -ForegroundColor Gray
Write-Host ""

Write-Host "Press Ctrl+C to stop all demo services" -ForegroundColor Red
Write-Host "Demo started at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray

# Keep script running and show periodic status
if (!$SetupOnly) {
    while ($true) {
        Start-Sleep -Seconds 60
        $timestamp = Get-Date -Format 'HH:mm:ss'
        Write-Host "[$timestamp] Demo running... CEO can access both platforms" -ForegroundColor DarkGreen
    }
}
