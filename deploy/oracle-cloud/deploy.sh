#!/bin/bash
# ================================================
# Quick Deploy Script - Run from local machine
# ================================================

set -e

# Configuration
VM1_IP=""  # API Server IP
VM2_IP=""  # DB Server IP
SSH_KEY="~/oracle-key.pem"

echo "🚀 PriceDrop Oracle Cloud Deployment"
echo "====================================="

# Check if IPs are set
if [ -z "$VM1_IP" ] || [ -z "$VM2_IP" ]; then
    echo "❌ Error: Set VM1_IP and VM2_IP in this script first!"
    echo ""
    echo "Edit this file and set:"
    echo "  VM1_IP=\"your-api-server-ip\""
    echo "  VM2_IP=\"your-db-server-ip\""
    exit 1
fi

echo "📦 Step 1: Uploading backend code to VM1..."
rsync -avz --progress \
    -e "ssh -i $SSH_KEY" \
    --exclude '__pycache__' \
    --exclude '*.pyc' \
    --exclude '.git' \
    --exclude 'venv' \
    ./backend/ opc@$VM1_IP:~/pricedrop/backend/

echo ""
echo "🔧 Step 2: Setting up VM2 (Database)..."
ssh -i $SSH_KEY opc@$VM2_IP << 'REMOTE_DB'
cd ~/pricedrop
docker-compose down 2>/dev/null || true
docker-compose up -d
echo "Waiting for DB to be ready..."
sleep 10
docker-compose ps
REMOTE_DB

echo ""
echo "🔧 Step 3: Setting up VM1 (API)..."
ssh -i $SSH_KEY opc@$VM1_IP << 'REMOTE_API'
cd ~/pricedrop
docker-compose down 2>/dev/null || true
docker-compose up -d
echo "Waiting for services to start..."
sleep 15
docker-compose ps
REMOTE_API

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🔍 Check status:"
echo "  ssh -i $SSH_KEY opc@$VM1_IP 'cd ~/pricedrop && docker-compose logs -f'"
echo ""
echo "🌐 API endpoint: http://$VM1_IP:8000"
echo "📖 API docs: http://$VM1_IP:8000/docs"
