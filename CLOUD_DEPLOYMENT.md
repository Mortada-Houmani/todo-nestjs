# Cloud Deployment Documentation

This document provides a detailed technical guide for the **Todo App's** AWS infrastructure and CI/CD pipeline.

---

## Architecture Overview

The application follows a modern cloud-native architecture.

### Networking (VPC)
- **VPC:** A dedicated virtual network isolated from other AWS accounts.
- **Public Subnets:** Host the Application Load Balancer (ALB) and NAT Gateways.
- **Private Subnets:** Host the ECS Fargate tasks and RDS Database. This ensures that the application logic and data are never directly exposed to the open internet.

### Backend (ECS Fargate)
- **Service:** Managed by **Amazon ECS** using the **Fargate** launch type (serverless).
- **Cluster:** A logical grouping of services.
- **Task Definition:** Defines the Docker container image, CPU/Memory limits, and environment variables.
- **Auto-scaling:** Configured to handle varying traffic loads.

### Frontend (S3 + CloudFront)
- **Storage:** Static assets (HTML/JS/CSS) are stored in a private **Amazon S3** bucket.
- **CDN:** **Amazon CloudFront** serves the assets globally with low latency.
- **Security:** CloudFront uses **Origin Access Control (OAC)** to fetch files from S3.

### Load Balancing & Proxying
- **ALB:** Receives traffic from CloudFront and routes it to healthy ECS containers.
- **API Proxying:** CloudFront is configured with an `ordered_cache_behavior` for `/api/*`. It forwards these requests to the ALB over HTTP.

---

## Deployment Steps (Manual/Initial)

If you need to redeploy the stack from scratch:

### 1. Terraform Initialization
Ensure you have an AWS user with `AdministratorAccess` and run:
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply
```

### 2. GitHub Secrets Setup
To enable the **GitHub Actions** pipeline, add the following secrets to your repository:

| Secret Name | Description |
| :--- | :--- |
| `AWS_ACCESS_KEY_ID` | Your AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key |
| `VITE_API_URL` | Set to `/api` |
| `S3_BUCKET` | The name of your frontend S3 bucket |
| `CLOUDFRONT_DIST_ID` | Your CloudFront Distribution ID |

---

## 🔄 CI/CD Pipeline Logic

The `.github/workflows/deploy.yml` handles the automation:

1.  **Checkout Code:** Pulls the latest from the branch.
2.  **Backend Build:** 
    - Builds the Docker image.
    - Logs into **Amazon ECR**.
    - Pushes the image tagged with the commit SHA.
3.  **Backend Deploy:** Updates the ECS service with the new image.
4.  **Frontend Build:** 
    - Installs dependencies and builds the Vite app.
    - Uses the `VITE_API_URL` secret.
5.  **Frontend Deploy:** 
    - Syncs `dist/` to S3.
    - **Invalidates CloudFront Cache** (`/*`) to ensure the new version is served immediately.

---

## 🔍 Monitoring & Troubleshooting

### 1. Health Checks
- **Path:** `/api/health`
- **Logic:** The ALB checks this endpoint every 30 seconds. If it returns anything other than `200 OK`, ECS will automatically kill the container and start a new one.

### 2. Viewing Logs
You can view production logs directly via the AWS CLI:
```bash
aws logs tail /ecs/todo-production-backend --follow
```

### 3. Database Access
The database is in a private subnet. To access it, you must use a **VPN** or a **Bastion Host** within the VPC, or update the Security Groups temporarily (not recommended for production).

---

## 🔐 Security Best Practices Implemented
- **Least Privilege:** Security groups only allow necessary traffic (e.g., RDS only accepts traffic from ECS).
- **HTTPS Enforcement:** CloudFront is configured to redirect all HTTP traffic to HTTPS.
