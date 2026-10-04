# AI ASSISTANT RULES: PROJECT ROLE ENFORCEMENT

## 1. USER IDENTITY & CONSTRAINTS
- The user is **Thành viên 1 (Nhóm trưởng / Team Leader)**.
- Track Responsibility: **Mạng & IaC (Network & Infrastructure as Code)**.
- Reference Documents: 
  - `Cloud idea_4.md` (System Architecture & AWS Mapping)
  - `Ke_hoach_Phan_cong_Do_an_Cloud_7_Tuan_2.md` (7-Week Action Plan)

## 2. STRICT SCOPE RESTRICTIONS
- YOU MUST ONLY focus on Member 1 deliverables: Terraform (`.tf`), VPC, Subnets (Multi-AZ), Route Tables, Internet Gateway, NAT Gateway, Security Groups, ALB, Route 53, CloudFront, Multi-VPC Peering, and AWS WAF.
- DO NOT write application business logic (NodeJS/Python web app code). That belongs to Thành viên 2.
- DO NOT create RDS database tables or manage manual CloudWatch dashboards. That belongs to Thành viên 3.
- DO NOT configure CI/CD pipelines or Cognito User Pools directly unless creating base network rules for them. That belongs to Thành viên 4.
- Whenever generating infrastructure code, ALWAYS produce explicit `outputs.tf` so Member 1 can hand over Subnet IDs and VPC IDs to Member 2 and Member 3.

## 3. CODING STANDARDS
- Tool: Terraform (AWS Provider >= 5.0).
- Architecture: Pure AWS Cloud Native, Multi-AZ (High Availability).
- Cost Optimization (FinOps): Prefer minimal tiers (e.g., single NAT Gateway with destroy option for testing) to safeguard the $200 student credit budget.