# Cloud Resume Challenge - AWS Implementation

Designed and implemented a **AWS Cloud Resume Challenge project** by building a personal resume website with a **live visitor counter**, leveraging a fully **serverless architecture** on AWS. The frontend was hosted on **S3** and delivered globally via **CloudFront** with HTTPS, while the backend used **API Gateway**, **AWS Lambda (Python)**, and **DynamoDB** to securely store and update visitor data. Implemented **Infrastructure as Code (IaC)** with **Terraform** to provision and manage AWS resources, using a remote state backend with S3 and DynamoDB locking. Automated **CI/CD pipelines** with **GitHub Actions**, including OIDC-based secure backend deployments and frontend deployments with CloudFront cache invalidations. Secured the solution with **CloudFront OAC**, private S3 buckets, least-privilege IAM roles, and strict **CORS policies**, ensuring a scalable, globally distributed, and cost-effective application.

---

## 🚀 Features

- **Static frontend** hosted in S3 and distributed via **CloudFront** (HTTPS).
- **Serverless backend**:
  - API Gateway endpoint (`/count`).
  - Lambda function to increment and return visitor count.
  - DynamoDB table storing the count.
- **CI/CD pipelines**:
  - Frontend automatically deployed to S3 on pushes.
  - Backend managed via Terraform and deployed through GitHub Actions with **OIDC** (no long-lived AWS keys).
- **Secure architecture**:
  - CloudFront **Origin Access Control (OAC)** → S3 bucket is **private**.
  - CORS configured to allow only CloudFront domain.
  - Terraform state stored in S3 with DynamoDB state locking.

---

## 🏗 Architecture

### High-level flow:

1. **User opens site:**  
   CloudFront serves static HTML/CSS/JS from private S3.
2. **Visitor counter:**
   - Frontend JS calls `/count` API Gateway endpoint.
   - API Gateway triggers Lambda.
   - Lambda updates visitor count in DynamoDB and returns latest value.
3. **CI/CD:**
   - Push to `main` → GitHub Actions deploys:
     - Frontend → S3 + CloudFront invalidation.
     - Backend → Terraform apply.

---

## 📂 Project Structure

```
Cloud-Resume/
│
├── infra/                     # Terraform IaC for backend
│   ├── backend.tf             # Remote state (S3 + DynamoDB)
│   ├── cloudfront.tf          # CloudFront + OAC config
│   ├── s3-cloudfront-policy.tf# S3 bucket policy for CloudFront
│   ├── main.tf                 # Lambda, API Gateway, DynamoDB
│   ├── variables.tf
│   ├── outputs.tf
│   └── lambda/
│       └── counter.py         # Visitor counter Lambda function
│
├── .github/
│   └── workflows/
│       ├── frontend.yml       # Frontend CI/CD
│       └── terraform.yml      # Backend CI/CD
│
├── index.html                  # Resume site HTML
├── styles.css                  # Resume site CSS
└── README.md
```

---

## ⚙️ Setup & Deployment

### Prerequisites

- AWS Account with programmatic access.
- GitHub repository connected.
- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads).
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

---

### 1. Backend Setup

The backend is fully managed via Terraform through GitHub Actions.

- Terraform state stored in:
  - **S3 bucket** → `cloud-resume-tfstate-<your-unique-id>`
  - **DynamoDB table** → `terraform-locks`

#### Initialize Terraform locally:

```bash
cd infra
terraform init
terraform plan
terraform apply
```

GitHub Actions will take over deployment after the initial run.

---

### 2. Frontend Setup

The frontend site is built using static HTML/CSS and deployed via GitHub Actions.

To deploy manually:

```bash
aws s3 sync . s3://<your-bucket-name> --delete
```

---

### 3. Outputs

After deployment, Terraform will output:

```bash
cloudfront_domain_name = d61lbue2vh6ls.cloudfront.net
api_invoke_url         = https://pql6ord4x7.execute-api.us-east-1.amazonaws.com
get_count_url          = https://pql6ord4x7.execute-api.us-east-1.amazonaws.com/count
```

---

## 🧪 CI/CD Workflows

- **Frontend Workflow:**

  - Deploys static files to S3.
  - Invalidates CloudFront cache after each deployment.

- **Backend Workflow:**
  - Initializes Terraform.
  - Runs `fmt`, `validate`, `plan`, and `apply`.
  - Uses GitHub OIDC to assume AWS role securely.

---

## 🔒 Security Considerations

- **S3 bucket private**: Only CloudFront can access via OAC.
- **CORS**:
  - API Gateway and Lambda only allow CloudFront domain.
- **No long-lived AWS keys**:
  - GitHub Actions uses temporary credentials via OIDC.

---

## 📈 Future Improvements

- Add **custom domain** with Route 53 and ACM SSL.
- Enable **CloudFront logging** for analytics.
- Implement monitoring and alerting with CloudWatch.
- Automate cost tracking and add budget alarms.

---

## 🧹 Cleanup

To avoid AWS charges, destroy resources when finished:

```bash
cd infra
terraform destroy
```

---

## 🌐 Live Site

**Frontend (CloudFront):**  
[https://d61lbue2vh6ls.cloudfront.net]

**Visitor Counter API:**  
`https://pql6ord4x7.execute-api.us-east-1.amazonaws.com/count`
