#!/bin/bash
# ================================================
# Oracle Cloud VM 1: API Server Setup Script
# ================================================

set -e

echo "🚀 Setting up PriceDrop API Server..."

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

# Install docker-compose standalone (fallback)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create app directory
mkdir -p ~/pricedrop
cd ~/pricedrop

# Create docker-compose.yml for API
cat > docker-compose.yml << 'DOCKER_EOF'
version: '3.8'

services:
  api:
    image: python:3.11-slim
    container_name: pricedrop_api
    working_dir: /app
    command: >
      bash -c "
        pip install --no-cache-dir -r requirements.txt &&
        playwright install chromium &&
        playwright install-deps &&
        uvicorn app.main:app --host 0.0.0.0 --port 8000
      "
    volumes:
      - ./backend:/app
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
      - SECRET_KEY=${SECRET_KEY}
      - STRIPE_SECRET_KEY=${STRIPE_SECRET_KEY}
      - STRIPE_WEBHOOK_SECRET=${STRIPE_WEBHOOK_SECRET}
      - FIREBASE_CREDENTIALS=${FIREBASE_CREDENTIALS}
    restart: unless-stopped
    networks:
      - pricedrop_net

  celery_worker:
    image: python:3.11-slim
    container_name: pricedrop_worker
    working_dir: /app
    command: >
      bash -c "
        pip install --no-cache-dir -r requirements.txt &&
        playwright install chromium &&
        playwright install-deps &&
        celery -A app.celery_app worker --loglevel=info
      "
    volumes:
      - ./backend:/app
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
      - SECRET_KEY=${SECRET_KEY}
    restart: unless-stopped
    networks:
      - pricedrop_net

  celery_beat:
    image: python:3.11-slim
    container_name: pricedrop_beat
    working_dir: /app
    command: >
      bash -c "
        pip install --no-cache-dir -r requirements.txt &&
        celery -A app.celery_app beat --loglevel=info
      "
    volumes:
      - ./backend:/app
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
    restart: unless-stopped
    networks:
      - pricedrop_net

  nginx:
    image: nginx:alpine
    container_name: pricedrop_nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certbot/conf:/etc/letsencrypt:ro
      - ./certbot/www:/var/www/certbot:ro
    depends_on:
      - api
    restart: unless-stopped
    networks:
      - pricedrop_net

networks:
  pricedrop_net:
    driver: bridge
DOCKER_EOF

# Create nginx.conf
cat > nginx.conf << 'NGINX_EOF'
events {
    worker_connections 1024;
}

http {
    upstream api {
        server api:8000;
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

    server {
        listen 80;
        server_name _;

        # Let's Encrypt challenge
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        # Redirect to HTTPS (enable after SSL setup)
        # return 301 https://$host$request_uri;

        # API proxy (use this before SSL)
        location / {
            limit_req zone=api_limit burst=20 nodelay;
            
            proxy_pass http://api;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            proxy_read_timeout 300s;
        }
    }

    # HTTPS server (uncomment after SSL setup)
    # server {
    #     listen 443 ssl http2;
    #     server_name your-domain.com;
    #
    #     ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    #     ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    #
    #     location / {
    #         proxy_pass http://api;
    #         ...
    #     }
    # }
}
NGINX_EOF

# Create .env template
cat > .env << 'ENV_EOF'
# Database (VM 2 IP)
DATABASE_URL=postgresql+asyncpg://pricedrop:your_password@<VM2_PRIVATE_IP>:5432/pricedrop

# Redis (VM 2 IP)
REDIS_URL=redis://<VM2_PRIVATE_IP>:6379/0

# Security
SECRET_KEY=your-super-secret-key-change-this-in-production

# Stripe (optional)
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# Firebase (optional)
FIREBASE_CREDENTIALS=/app/firebase-credentials.json
ENV_EOF

# Create certbot directories
mkdir -p certbot/conf certbot/www

# Open firewall ports
if command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-port=80/tcp
    sudo firewall-cmd --permanent --add-port=443/tcp
    sudo firewall-cmd --permanent --add-port=8000/tcp
    sudo firewall-cmd --reload
else
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 8000/tcp
fi

echo ""
echo "✅ API Server setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Copy your backend code to ~/pricedrop/backend/"
echo "2. Edit ~/pricedrop/.env with your VM2 IP and credentials"
echo "3. Run: cd ~/pricedrop && docker-compose up -d"
echo ""
echo "🔐 To setup SSL:"
echo "1. Point your domain to this server's IP"
echo "2. Run: docker run --rm -v ./certbot/conf:/etc/letsencrypt -v ./certbot/www:/var/www/certbot certbot/certbot certonly --webroot -w /var/www/certbot -d your-domain.com"
echo "3. Uncomment HTTPS section in nginx.conf"
echo "4. Run: docker-compose restart nginx"
