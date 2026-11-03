# ==============================================================================
# CLOUD MEDIA STUDIO — BUILD & DEPLOY BACKEND CONTAINER TO AWS ECR / FARGATE
# ==============================================================================
$AWS_ACCOUNT_ID = "586643076560"
$AWS_REGION = "ap-southeast-1"
$ECR_REPO = "cloud-media-studio-backend"
$IMAGE_URI = "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "🐳 CLOUD MEDIA STUDIO — BUILD & PUSH CONTAINER TO AMAZON ECR" -ForegroundColor Cyan
Write-Host "================================================================`n" -ForegroundColor Cyan

Write-Host "🔐 [1/4] Đăng nhập Amazon ECR..." -ForegroundColor Yellow
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

Write-Host "`n🔨 [2/4] Đang build Docker Image từ backend/Dockerfile..." -ForegroundColor Yellow
docker build -t "$ECR_REPO`:latest" ./backend

Write-Host "`n🏷️  [3/4] Gắn tag Image cho ECR Repository: $IMAGE_URI`:latest..." -ForegroundColor Yellow
docker tag "$ECR_REPO`:latest" "$IMAGE_URI`:latest"

Write-Host "`n🚀 [4/4] Đẩy Docker Image lên Amazon ECR..." -ForegroundColor Yellow
docker push "$IMAGE_URI`:latest"

Write-Host "`n================================================================" -ForegroundColor Green
Write-Host "🎉 DEPLOY CONTAINER LÊN ECR THÀNH CÔNG!" -ForegroundColor Green
Write-Host "📦 ECR URI: $IMAGE_URI`:latest" -ForegroundColor Green
Write-Host "⚙️  ECS Cluster: cloud-media-studio-cluster" -ForegroundColor Green
Write-Host "📋 Task Definition: cloud-media-studio-backend" -ForegroundColor Green
Write-Host "================================================================`n" -ForegroundColor Green
