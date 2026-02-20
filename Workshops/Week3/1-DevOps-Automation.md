# CI/CD and DevOps Automation with GitHub Copilot

**Duration:** 30-45 minutes  
**Format:** Presentation with interactive demonstrations  
**Objective:** Learn to leverage GitHub Copilot — in the IDE and the CLI — for automating CI/CD pipelines, generating Infrastructure as Code, and validating deployments.

---

## Session Overview

DevOps automation is one of Copilot's strongest use cases. The repetitive nature of pipeline configurations, infrastructure definitions, and validation scripts makes them ideal for AI-assisted generation. In this session you will use both the **VS Code Chat** experience and the standalone **Copilot CLI** side by side — learning when each tool fits best.

**What you'll learn:**
- Generate CI/CD pipelines for various platforms — from the IDE and the CLI
- Create Infrastructure as Code (IaC) configurations (Docker, Kubernetes, Terraform)
- Build pre-deployment validation scripts
- Use headless mode to embed Copilot in scripts and pipelines
- Delegate generated work to pull requests with `/delegate`

---

## Copilot CLI Quick Start

The standalone Copilot CLI brings agentic AI to your terminal — where DevOps work already happens. Instead of covering the CLI in isolation, we use it throughout every topic below alongside the VS Code Chat experience.

> **Note:** The standalone GitHub Copilot CLI replaces the retired `gh copilot` extension. It is a separate application, not a GitHub CLI extension. See [GitHub Copilot CLI documentation](https://docs.github.com/en/copilot/github-copilot-in-the-cli) for details.

**Prerequisites:** Node.js 22+ and an active GitHub Copilot subscription (Pro, Pro+, Business, or Enterprise).

```bash
# Install globally via npm
npm install -g @githubnext/github-copilot-cli

# Verify installation
copilot --version

# Authenticate with GitHub
copilot /login
```

**Key Slash Commands**

| Command | Purpose |
|---------|---------|
| `/delegate` | Create a PR with generated changes |
| `/agent` | Use custom agents (e.g. DevOps reviewer) |
| `/mcp` | Manage MCP servers (GitHub repos, issues, PRs) |
| `/share` | Export session as Markdown |
| `/cwd` | Change working directory |
| `/add-dir` | Add directory to context |
| `/model` | Switch AI model |
| `/terminal-setup` | Configure terminal integration |

> **Headless mode:** Run `copilot --allow-all-tools -p "your prompt"` to use Copilot non-interactively in shell scripts, Makefiles, pre-commit hooks, and CI pipeline steps.

---

## 1. CI/CD Pipeline Generation

### Why Use Copilot for CI/CD?

| Challenge | How Copilot Helps |
|-----------|-------------------|
| Syntax complexity | Generates valid YAML/JSON with correct indentation and structure |
| Platform variations | Knows conventions for GitHub Actions, Azure DevOps, GitLab CI, Jenkins |
| Boilerplate code | Quickly scaffolds common patterns (build, test, deploy) |
| Best practices | Suggests caching, parallelisation, and optimisation techniques |

### Pipeline Generation Strategy

Build pipelines incrementally using progressive prompts:

```
Step 1: Basic Build → Step 2: Add Tests → Step 3: Add Deploy → Step 4: Add Notifications
```

This approach allows you to:
- Verify each step works before adding complexity
- Understand what Copilot generates
- Customise each section for your needs

---

### GitHub Actions Pipeline Examples

#### Step 1: Create a Basic Build Pipeline

**Prompt:**
```text
Write a GitHub Actions workflow YAML file for a Node.js project that includes build and test steps.
```

**Expected Output:**
```yaml
name: Node.js CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [18.x, 20.x]

    steps:
      - uses: actions/checkout@v4

      - name: Use Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run tests
        run: npm test

      - name: Build
        run: npm run build
```

#### Step 2: Add Deployment Stage

**Prompt:**
```text
Extend this pipeline to include a deployment step for staging that only runs on the main branch.
```

**Expected Addition:**
```yaml
  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: staging
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy to staging
        run: |
          echo "Deploying to staging environment"
          # Add your deployment commands here
        env:
          DEPLOY_TOKEN: ${{ secrets.STAGING_DEPLOY_TOKEN }}
```

#### Step 3: Add Notifications

**Prompt:**
```text
Add a step to notify the team on Slack when the build succeeds or fails.
```

**Expected Addition:**
```yaml
  notify:
    needs: [build, deploy-staging]
    runs-on: ubuntu-latest
    if: always()
    
    steps:
      - name: Notify Slack
        uses: slackapi/slack-github-action@v1.25.0
        with:
          payload: |
            {
              "text": "Build ${{ needs.build.result }}: ${{ github.repository }}",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*Build Result:* ${{ needs.build.result }}\n*Staging Deploy Result:* ${{ needs['deploy-staging'].result }}\n*Repository:* ${{ github.repository }}\n*Branch:* ${{ github.ref_name }}\n*Commit:* ${{ github.sha }}"
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

---

### Platform-Specific Pipeline Prompts

#### Terminal (Copilot CLI)

Generate pipelines directly from the terminal — no IDE required:

**Interactive mode:**
```bash
copilot
> Create a GitHub Actions workflow for a Node.js 20 app that builds, tests with coverage, lints, and deploys to Azure App Service on main branch. Include caching and matrix strategy for Node 18 and 20.
```

**Headless mode (scriptable):**
```bash
# Generate and save directly
copilot --allow-all-tools -p "Create a GitHub Actions workflow for a Node.js app with build, test, linting, and deployment to staging on main" > .github/workflows/ci.yml

# Generate and create a PR in one flow
copilot
> Create a GitHub Actions CI/CD pipeline for this repo with build, test, and deploy stages
> /delegate
```

The `/delegate` command is particularly powerful for DevOps — it creates a pull request with all the generated files, adds a description, and submits it for review.

#### Azure DevOps

```text
Create an Azure DevOps YAML pipeline for a .NET 8 application with:
- Build and test stages
- Code coverage reporting
- Artifact publishing
- Deployment to Azure App Service
```

#### GitLab CI

```text
Generate a .gitlab-ci.yml file for a Python Django application with:
- Linting with flake8
- Unit tests with pytest
- Docker image build and push to registry
- Deployment to Kubernetes
```

#### Jenkins

```text
Create a Jenkinsfile for a Java Maven project with:
- Parallel test execution
- SonarQube code analysis
- Artifact deployment to Nexus
- Slack notifications
```

---

### CI/CD Best Practices Prompts

| Goal | Prompt |
|------|--------|
| **Caching** | "Add dependency caching to speed up the Node.js CI workflow" |
| **Parallelisation** | "Modify the pipeline to run linting and tests in parallel" |
| **Security scanning** | "Add a security vulnerability scan step using npm audit" |
| **Conditional execution** | "Only run deployment when changes are in the src/ directory" |
| **Environment variables** | "Add environment-specific configuration using GitHub secrets" |

---

## 2. Infrastructure as Code (IaC)

### IaC Generation with Copilot

Copilot understands major IaC tools and cloud provider APIs:

| Tool | Use Case |
|------|----------|
| **Docker** | Containerisation, local development |
| **Docker Compose** | Multi-container applications |
| **Kubernetes** | Container orchestration |
| **Terraform** | Multi-cloud infrastructure provisioning |
| **Helm** | Kubernetes package management |
| **Bicep/ARM** | Azure-specific infrastructure |
| **CloudFormation** | AWS-specific infrastructure |

---

### Docker Examples

#### Basic Dockerfile

**Prompt:**
```text
Create a Dockerfile for a Node.js application running on port 3000.
```

**Expected Output:**
```dockerfile
# Use official Node.js runtime as base image
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./

# Install dependencies
RUN npm ci --omit=dev

# Copy application source
COPY . .

# Expose port
EXPOSE 3000

# Set non-root user for security
USER node

# Start the application
CMD ["node", "src/index.js"]
```

#### Multi-Stage Dockerfile

**Prompt:**
```text
Create a multi-stage Dockerfile for a React application with nginx serving the production build.
```

**Expected Output:**
```dockerfile
# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built assets from builder stage
COPY --from=builder /app/build /usr/share/nginx/html

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
```

---

### Docker Compose Examples

**Prompt:**
```text
Create a docker-compose.yml file for a Node.js app with MongoDB and Redis for development.
```

**Expected Output:**
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - MONGODB_URI=mongodb://mongo:27017/myapp
      - REDIS_URL=redis://redis:6379
    volumes:
      - .:/app
      - /app/node_modules
    depends_on:
      - mongo
      - redis
    restart: unless-stopped

  mongo:
    image: mongo:7
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db
    environment:
      - MONGO_INITDB_DATABASE=myapp

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  mongo_data:
  redis_data:
```

---

### Kubernetes Examples

#### Basic Deployment

**Prompt:**
```text
Generate a Kubernetes deployment YAML file for a Node.js app with 3 replicas, resource limits, and health checks.
```

**Expected Output:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-app
  labels:
    app: nodejs-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nodejs-app
  template:
    metadata:
      labels:
        app: nodejs-app
    spec:
      containers:
        - name: nodejs-app
          image: myregistry/nodejs-app:latest
          ports:
            - containerPort: 3000
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ready
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 5
          env:
            - name: NODE_ENV
              value: "production"
            - name: PORT
              value: "3000"
---
apiVersion: v1
kind: Service
metadata:
  name: nodejs-app-service
spec:
  selector:
    app: nodejs-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
  type: ClusterIP
```

---

### Terraform Examples

**Prompt:**
```text
Generate a Terraform configuration to provision an AWS EC2 instance with a security group allowing HTTP and SSH access.
```

**Expected Output:**
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  default     = "eu-west-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
}

# Security Group
resource "aws_security_group" "app_sg" {
  name        = "app-security-group"
  description = "Allow HTTP and SSH traffic"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-security-group"
  }
}

# EC2 Instance
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name = "app-server"
  }
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

output "instance_public_ip" {
  value = aws_instance.app_server.public_ip
}
```

---

### Generating IaC from the CLI

The CLI excels at IaC because you can work directly in the directory where configs live:

```bash
# Navigate to your infrastructure directory
copilot
> /cwd ./infrastructure

# Generate Docker, K8s, and Terraform in context
> Create a production Dockerfile for the Node.js app in the parent directory. Use multi-stage build, non-root user, and health checks.

# Add multiple directories for cross-referencing
> /add-dir ./k8s
> /add-dir ./terraform
> Review all infrastructure configs and ensure consistency between Docker, Kubernetes, and Terraform resource definitions.
```

**Headless IaC generation:**
```bash
# Generate a Dockerfile
copilot --allow-all-tools -p "Create a production multi-stage Dockerfile for a Node.js Express app on port 3000 with security best practices" > Dockerfile

# Generate Kubernetes manifests
copilot --allow-all-tools -p "Create K8s deployment, service, and HPA for a Node.js app with 3 replicas, health checks, and resource limits" > k8s/deployment.yml

# Generate and submit as a PR
copilot
> Generate Terraform configuration for an AWS VPC with public/private subnets, ALB, and ECS Fargate cluster
> /delegate
```

---

## 3. Pre-Review Validation for Deployment

### Why Validation Matters

Pre-deployment validation catches issues early:
- **Syntax errors** in configuration files
- **Missing environment variables** or secrets
- **Security vulnerabilities** in dependencies
- **Configuration drift** between environments

### Validation Script Generation

#### YAML Validation

**Prompt:**
```text
Write a shell script to validate all YAML files in a directory and report any syntax errors.
```

**Expected Output:**
```bash
#!/bin/bash

# YAML Validation Script
# Validates all YAML files in the specified directory

set -e

DIRECTORY="${1:-.}"
ERRORS=0

echo "Validating YAML files in: $DIRECTORY"
echo "=================================="

# Find all YAML files
for file in $(find "$DIRECTORY" -name "*.yaml" -o -name "*.yml"); do
    echo -n "Checking $file... "
    
    if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
        echo "✓ Valid"
    else
        echo "✗ Invalid"
        python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>&1 || true
        ERRORS=$((ERRORS + 1))
    fi
done

echo "=================================="
echo "Validation complete. Errors found: $ERRORS"

exit $ERRORS
```

#### Environment Variable Check

**Prompt:**
```text
Create a script that verifies all required environment variables are set before deployment.
```

**Expected Output:**
```bash
#!/bin/bash

# Environment Variable Validation Script

REQUIRED_VARS=(
    "DATABASE_URL"
    "API_KEY"
    "NODE_ENV"
    "PORT"
)

MISSING=0

echo "Checking required environment variables..."
echo "=========================================="

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "✗ Missing: $var"
        MISSING=$((MISSING + 1))
    else
        echo "✓ Set: $var"
    fi
done

echo "=========================================="

if [ $MISSING -gt 0 ]; then
    echo "Error: $MISSING required variable(s) not set"
    exit 1
else
    echo "All required variables are set"
    exit 0
fi
```

---

### CI Pipeline Validation Steps

**Prompt:**
```text
Add validation steps to a GitHub Actions workflow that check YAML syntax, Dockerfile best practices, and security vulnerabilities.
```

**Expected Output:**
```yaml
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validate YAML files
        run: |
          python3 -m pip install yamllint
          yamllint -d relaxed .

      - name: Lint Dockerfile
        uses: hadolint/hadolint-action@v3.1.0
        with:
          dockerfile: Dockerfile

      - name: Check for secrets in code
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          extra_args: --only-verified

      - name: Security audit - npm
        run: npm audit --audit-level=high

      - name: Validate Kubernetes manifests
        run: |
          curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
          chmod +x kubectl
          ./kubectl apply --dry-run=client -f k8s/ -R
```

---

### Validating from the CLI

Validate configurations from the terminal before committing:

```bash
# Interactive validation review
copilot
> /add-dir .github/workflows
> /add-dir k8s
> /add-dir .
> Validate all YAML files in these directories. Check for syntax errors, security issues, and missing best practices. Report findings as a checklist.

# Headless validation in a pre-commit hook or CI step
copilot --allow-all-tools -p "Check all Dockerfiles in this repo for security issues: hardcoded secrets, running as root, using latest tags, missing health checks"
```

**Using CLI in a CI Pipeline (GitHub Actions):**
```yaml
jobs:
  ai-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Copilot CLI
        run: npm install -g @githubnext/github-copilot-cli
      
      - name: AI-Powered Config Review
        run: |
          copilot --allow-all-tools -p "Review the Kubernetes manifests in k8s/ for security best practices and report any issues"
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## Effective DevOps Prompting Patterns

### The Specification Pattern

```text
Create a [resource type] for [application type]:
- Running on [port/environment]
- With [dependencies/services]
- Including [features like health checks, logging]
- Following [security/compliance requirements]
```

### The Incremental Build Pattern

```text
1. "Create a basic CI workflow with build step"
2. "Add test step with coverage reporting"
3. "Add deployment to staging environment"
4. "Add production deployment with approval gate"
5. "Add rollback capability on failure"
```

### The Security-First Pattern

```text
Generate [resource] with security best practices:
- Non-root user execution
- Minimal base image
- No hardcoded secrets
- Resource limits defined
- Network policies applied
```

### The Delegate Pattern

Use `/delegate` to go from idea to pull request in one session:

```bash
copilot
> Create a complete CI/CD pipeline for this Node.js project:
> 1. GitHub Actions workflow with build, test, security scan, and deploy stages
> 2. Production Dockerfile with multi-stage build
> 3. Kubernetes deployment with health checks and HPA
> Review all the files you've created and ensure they are consistent.
> /delegate
```

This creates a PR with all generated files, a descriptive title, and a summary body — ready for team review.

### The Monorepo Context Pattern

Use `/add-dir` and `/cwd` to work across services in a monorepo:

```bash
copilot
> /add-dir ./services/api
> /add-dir ./services/web
> /add-dir ./infrastructure
> Create a GitHub Actions workflow that builds and tests both the api and web services in parallel, then deploys them together
```

---

## Key Takeaways

1. **Build incrementally** - Start with basic pipelines and add complexity step by step
2. **Be specific** - Include ports, versions, and environment details in prompts
3. **Include security** - Always ask for security best practices
4. **Validate early** - Add validation steps to catch issues before deployment
5. **Use platform conventions** - Let Copilot leverage its knowledge of CI/CD best practices
6. **Review generated code** - Always verify configurations before applying them
7. **Use CLI for terminal workflows** - Copilot CLI brings AI directly to where DevOps work happens
8. **Automate with headless mode** - Embed `copilot --allow-all-tools -p` in scripts and CI steps
9. **Delegate to PRs** - Use `/delegate` to go from generation to pull request in one flow
10. **Leverage custom agents** - Create `.github/agents/` for repeatable compliance and review workflows

---

## Next Steps

- Proceed to [Testing and Quality Assurance](2-Testing-and-Quality-Assurance.md) for test automation techniques
- Complete the [Week 3 Lab](3-Week3-Lab.md) for hands-on practice
- Review [Week 3 Prompts](4-Week3-Prompts.md) for additional DevOps prompt examples

---

