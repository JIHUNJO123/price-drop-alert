# Windows PowerShell Deployment Script for Oracle Cloud
# =====================================================

# Configuration - SET THESE VALUES
$VM1_IP = ""  # API Server Public IP
$VM2_IP = ""  # DB Server Public IP  
$SSH_KEY = "$env:USERPROFILE\oracle-key.pem"

# Colors
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }

Write-Info "🚀 PriceDrop Oracle Cloud Deployment"
Write-Info "====================================="

# Check if IPs are set
if ([string]::IsNullOrEmpty($VM1_IP) -or [string]::IsNullOrEmpty($VM2_IP)) {
    Write-Error "❌ Error: Set VM1_IP and VM2_IP in this script first!"
    Write-Host ""
    Write-Host "Edit this file and set:"
    Write-Host '  $VM1_IP = "your-api-server-ip"'
    Write-Host '  $VM2_IP = "your-db-server-ip"'
    exit 1
}

# Check SSH key
if (-not (Test-Path $SSH_KEY)) {
    Write-Error "❌ SSH key not found: $SSH_KEY"
    Write-Host "Download your Oracle Cloud SSH key and save it to: $SSH_KEY"
    exit 1
}

# Step 1: Upload backend code
Write-Info ""
Write-Info "📦 Step 1: Uploading backend code to VM1..."

# Use SCP to upload backend folder
$backendPath = Join-Path $PSScriptRoot "..\..\backend"
if (-not (Test-Path $backendPath)) {
    $backendPath = ".\backend"
}

scp -i $SSH_KEY -r "$backendPath" "opc@${VM1_IP}:~/pricedrop/"

# Step 2: Setup VM2 (Database)
Write-Info ""
Write-Info "🔧 Step 2: Setting up VM2 (Database)..."

$dbCommands = @"
cd ~/pricedrop
docker-compose down 2>/dev/null || true
docker-compose up -d
echo 'Waiting for DB to be ready...'
sleep 10
docker-compose ps
"@

ssh -i $SSH_KEY "opc@$VM2_IP" $dbCommands

# Step 3: Setup VM1 (API)
Write-Info ""
Write-Info "🔧 Step 3: Setting up VM1 (API)..."

$apiCommands = @"
cd ~/pricedrop
docker-compose down 2>/dev/null || true
docker-compose up -d
echo 'Waiting for services to start...'
sleep 15
docker-compose ps
"@

ssh -i $SSH_KEY "opc@$VM1_IP" $apiCommands

# Done
Write-Success ""
Write-Success "✅ Deployment complete!"
Write-Host ""
Write-Info "🔍 Check status:"
Write-Host "  ssh -i $SSH_KEY opc@$VM1_IP 'cd ~/pricedrop && docker-compose logs -f'"
Write-Host ""
Write-Info "🌐 API endpoint: http://${VM1_IP}:8000"
Write-Info "📖 API docs: http://${VM1_IP}:8000/docs"
