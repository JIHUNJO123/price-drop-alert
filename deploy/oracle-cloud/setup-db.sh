#!/bin/bash
# ================================================
# Oracle Cloud VM 2: Database Server Setup Script
# ================================================

set -e

echo "🚀 Setting up PriceDrop Database Server..."

# Update system
sudo dnf update -y || sudo apt update -y

# Install Docker
echo "📦 Installing Docker..."
if command -v dnf &> /dev/null; then
    # Oracle Linux
    sudo dnf install -y dnf-utils
    sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
else
    # Ubuntu
    curl -fsSL https://get.docker.com | sh
    sudo apt install -y docker-compose-plugin
fi

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Install docker-compose standalone
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create app directory
mkdir -p ~/pricedrop
cd ~/pricedrop

# Create docker-compose.yml for DB
cat > docker-compose.yml << 'DOCKER_EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: pricedrop_db
    environment:
      POSTGRES_USER: pricedrop
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-your_secure_password}
      POSTGRES_DB: pricedrop
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U pricedrop"]
      interval: 10s
      timeout: 5s
      retries: 5
    command: >
      postgres
        -c max_connections=100
        -c shared_buffers=128MB
        -c effective_cache_size=256MB
        -c work_mem=4MB
        -c maintenance_work_mem=64MB

  redis:
    image: redis:7-alpine
    container_name: pricedrop_redis
    command: redis-server --appendonly yes --maxmemory 128mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
  redis_data:
DOCKER_EOF

# Create .env file
cat > .env << 'ENV_EOF'
# PostgreSQL
POSTGRES_PASSWORD=your_secure_password_change_this

# Redis (no password for internal use)
ENV_EOF

# Open firewall ports (internal network only is safer)
if command -v firewall-cmd &> /dev/null; then
    # Oracle Linux
    sudo firewall-cmd --permanent --add-port=5432/tcp
    sudo firewall-cmd --permanent --add-port=6379/tcp
    sudo firewall-cmd --reload
else
    # Ubuntu
    sudo ufw allow 5432/tcp
    sudo ufw allow 6379/tcp
fi

echo ""
echo "✅ Database Server setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Edit ~/pricedrop/.env - set POSTGRES_PASSWORD"
echo "2. Run: cd ~/pricedrop && docker-compose up -d"
echo "3. Note this server's PRIVATE IP for VM1 configuration"
echo ""
echo "🔍 Get private IP with: hostname -I | awk '{print \$1}'"
echo ""
echo "⚠️  Security Note:"
echo "   - Only allow 5432/6379 from VM1's private IP in Security List"
echo "   - Never expose DB ports to public internet"
