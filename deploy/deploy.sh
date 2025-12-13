#!/bin/bash
# AWS EC2 배포 스크립트

set -e

echo "🚀 Price Drop Alert 배포 시작..."

# 환경 변수 체크
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "❌ AWS_ACCOUNT_ID 환경변수가 설정되지 않았습니다."
    exit 1
fi

# 변수 설정
AWS_REGION=${AWS_REGION:-us-east-1}
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
IMAGE_TAG=${IMAGE_TAG:-latest}

echo "📦 ECR 로그인..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

echo "🔨 Docker 이미지 빌드..."
docker build -t pricedrop-api:$IMAGE_TAG ../backend

echo "🏷️ 이미지 태그..."
docker tag pricedrop-api:$IMAGE_TAG $ECR_REGISTRY/pricedrop-api:$IMAGE_TAG

echo "📤 ECR로 푸시..."
docker push $ECR_REGISTRY/pricedrop-api:$IMAGE_TAG

echo "🖥️ EC2 서버에 배포..."
ssh -i ~/.ssh/pricedrop-key.pem ec2-user@$EC2_HOST << 'ENDSSH'
    cd /home/ec2-user/pricedrop
    
    # 환경 변수 로드
    export $(cat .env | xargs)
    
    # 최신 이미지 풀
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY
    docker-compose -f docker-compose.prod.yml pull
    
    # 서비스 재시작
    docker-compose -f docker-compose.prod.yml up -d
    
    # 헬스 체크
    sleep 10
    curl -f http://localhost:8000/health || exit 1
    
    echo "✅ 배포 완료!"
ENDSSH

echo "🎉 배포 성공!"
