# Golf n Vibes CEO Demo - Multi-Tunnel Setup
Write-Host "🏌️ Starting Golf n Vibes CEO Demo Environment..." -ForegroundColor Green

# Install localtunnel globally (another free tunnel service)
Write-Host "📦 Installing localtunnel..." -ForegroundColor Yellow
npm install -g localtunnel 2>$null

# Create demo directory if it doesn't exist
$demoDir = "C:\projects\golf_n_vibes\spree-official\demo"
if (!(Test-Path $demoDir)) {
    New-Item -ItemType Directory -Path $demoDir -Force
}

# Start applications in background
Write-Host "🚀 Starting Spree Commerce server..." -ForegroundColor Blue
Start-Process -NoNewWindow -FilePath "cmd" -ArgumentList "/c cd C:\projects\golf_n_vibes\spree-official && rails server -p 3000"

Write-Host "🚀 Starting Next.js frontend..." -ForegroundColor Blue
Start-Process -NoNewWindow -FilePath "cmd" -ArgumentList "/c cd C:\projects\golf_n_vibes\next-golf && npm run dev"

# Wait for servers to start
Write-Host "⏳ Waiting for servers to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Start tunnels
Write-Host "🌐 Creating secure tunnels..." -ForegroundColor Green

# Tunnel 1: Spree Commerce via ngrok
Write-Host "🔗 Starting Spree tunnel (ngrok)..." -ForegroundColor Cyan
Start-Process -NoNewWindow -FilePath "ngrok" -ArgumentList "http 3000 --log=stdout"

# Tunnel 2: Next.js via localtunnel
Write-Host "🔗 Starting Next.js tunnel (localtunnel)..." -ForegroundColor Cyan
Start-Process -NoNewWindow -FilePath "lt" -ArgumentList "--port 3001 --subdomain golf-nextjs-demo"

Write-Host ""
Write-Host "🎉 Demo environment is starting up!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Access Information:" -ForegroundColor White
Write-Host "   Spree Commerce: Check ngrok dashboard at http://localhost:4040" -ForegroundColor Yellow
Write-Host "   Next.js Frontend: https://golf-nextjs-demo.loca.lt" -ForegroundColor Yellow
Write-Host ""
Write-Host "⚠️  Note: It may take 1-2 minutes for all services to be fully ready." -ForegroundColor Red
Write-Host ""

# Keep script running
Write-Host "Press Ctrl+C to stop all demo services..." -ForegroundColor Gray
while ($true) {
    Start-Sleep -Seconds 30
    Write-Host "Demo running... $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor DarkGray
}
