# Startup Migration: Hetzner → AWS EKS

A decision framework and architecture documentation for startups evaluating infrastructure migration from Hetzner Cloud to AWS EKS.

---

## Overview

This guide documents the typical journey of a startup migrating from **Hetzner Cloud** (self-managed Kubernetes) to **AWS EKS** (managed Kubernetes).

### 3-Stage Progression

| Stage | Platform | Monthly Spend | Team Size | Use Case |
|---|---|---|---|---|
| **Stage 1** | Hetzner Only | €20–100 | 1–5 | MVP, EU-focused, Bootstrap |
| **Stage 2** | Hetzner + AWS Hybrid | €100–500 + $500–2K | 5–15 | US + EU mixed customers |
| **Stage 3** | Full AWS EKS | $2K–20K | 15+ | US enterprise, Series B+ |

---

## Migration Journey

```mermaid
flowchart TD
    START([🚀 Startup Founded]) --> FUNDING

    FUNDING{"Funding Stage?"}
    FUNDING -->|Bootstrapped / Pre-Seed| EVAL_HETZNER
    FUNDING -->|Seed / Series A| EVAL_HETZNER

    subgraph STAGE_1["**STAGE 1: Hetzner Foundation**"]
        EVAL_HETZNER{["Is Hetzner sufficient?"]}
        EVAL_HETZNER -->|Yes| DEPLOY_HETZNER
        EVAL_HETZNER -->|No| ESCALATE_EKS

        DEPLOY_HETZNER["Deploy on Hetzner Cloud"]
        DEPLOY_HETZNER --> K8S_HETZNER["Self-managed Kubernetes<br/>(RKE2 / Talos / K3s)"]
        K8S_HETZNER --> GROW_HETZNER["Iterate & Grow on Hetzner"]
        GROW_HETZNER --> MONITOR_TRIGGERS

        MONITOR_TRIGGERS{"Monitoring Triggers..."}
        MONITOR_TRIGGERS -->|"US Enterprise Deals"| ESCALATE_EKS
        MONITOR_TRIGGERS -->|"SOC 2 Required"| ESCALATE_EKS
        MONITOR_TRIGGERS -->|"HIPAA / PCI DSS"| ESCALATE_EKS
        MONITOR_TRIGGERS -->|"$5K+/mo infra spend"| COST_REVIEW
        MONITOR_TRIGGERS -->|"Multi-region SLA needed"| ESCALATE_EKS
        MONITOR_TRIGGERS -->|"No triggers"| STAY_HETZNER["✅ No triggers — stay on Hetzner"]
    end

    subgraph STAGE_2["**STAGE 2: Hetzner + AWS Hybrid**"]
        ESCALATE_EKS["Identify EKS-ready workloads"]
        ESCALATE_EKS --> SEGREGATE["Segregate workloads"]
        
        SEGREGATE --> WHICH_MIGRATE{"Which to migrate first?"}
        WHICH_MIGRATE -->|"Customer-facing APIs"| PRIORITY_1["1. Customer-facing services"]
        WHICH_MIGRATE -->|"US customer workloads"| PRIORITY_2["2. Regulated workloads"]
        WHICH_MIGRATE -->|"Critical path services"| PRIORITY_3["3. High-availability services"]

        PRIORITY_1 --> SETUP_EKS["Provision EKS Cluster"]
        PRIORITY_2 --> SETUP_EKS
        PRIORITY_3 --> SETUP_EKS
        SETUP_EKS --> CI_CD_EKS["Setup CI/CD to EKS"]
        CI_CD_EKS --> MIGRATE_FIRST["Migrate first workload"]
        MIGRATE_FIRST --> VERIFY["Verify in production"]
        VERIFY --> STABLE{["Is it stable?"]}
        STABLE -->|Yes| HETZNER_STAYS["Keep Hetzner for:<br/>- Dev/Staging<br/>- Non-critical workloads<br/>- EU-only services"]
        STABLE -->|No| ROLLBACK["Rollback to Hetzner"]
        ROLLBACK --> FIX(["Fix issues, retry"])
        FIX --> MIGRATE_FIRST
        HETZNER_STAYS --> ITERATE_MIGRATION["Iterate: migrate next workload"]
        ITERATE_MIGRATION --> MORE{"More workloads?"}
        MORE -->|Yes| WHICH_MIGRATE
        MORE -->|No| HYBRID_STABLE["✅ Stable Hybrid State"]
    end

    subgraph STAGE_3["**STAGE 3: Full EKS (or Multi-Cloud)**"]
        HYBRID_STABLE --> DECIDE_FUTURE{"Long-term strategy?"}
        DECIDE_FUTURE -->|"Primary: US Enterprise"| FULL_EKS["Migrate remaining workloads to EKS"]
        DECIDE_FUTURE -->|"Cost optimization"| MULTI["Hetzner + EKS + Spot"]
        DECIDE_FUTURE -->|"EU Sovereignty"| EU_FOCUS["Scale Hetzner, use EKS-EU"]

        FULL_EKS --> FINAL_EKS["✅ Full AWS EKS Platform"]
        MULTI --> FINAL_MULTI["✅ Multi-Cloud Strategy"]
        EU_FOCUS --> FINAL_EU["✅ EU-First with AWS EKS-EU"]
    end
```

---

## Architecture Diagrams

### Stage 1 — Hetzner Only

```mermaid
flowchart TB
    subgraph STAGE1["**STAGE 1: Hetzner Only Architecture**"]
        subgraph ST1_INTERNET["🌐 Internet"]
            USERS1["👥 Users / Clients"]
        end

        subgraph ST1_HETZNER["🇩🇪 Hetzner Cloud (Nuremberg / Finland)"]
            subgraph ST1_NET["Network Layer"]
                LB1["Load Balancer (Cloudflare / OctoLoad)"]
                FW1["Firewall Rules"]
                DDOS1["DDoS Protection (Cloudflare)"]
            end

            subgraph ST1_K8S["Kubernetes Cluster (Self-Managed)"]
                subgraph ST1_NS1["Namespace: production"]
                    ING1["Ingress Controller<br/>(nginx / Traefik)"]
                    subgraph ST1_SVC1["Services"]
                        API1["API Service 🖥️"]
                        WEB1["Web App 🖥️"]
                        WORKER1["Background Workers 🖥️"]
                    end
                    subgraph ST1_DATA1["Data Layer"]
                        DB1["PostgreSQL<br/>(Self-managed)"]
                        CACHE1["Redis<br/>(Self-managed)"]
                        OBJ1["Object Storage<br/>(Hetzner Storage Box)"]
                    end
                end

                subgraph ST1_NS2["Namespace: staging"]
                    ING1B["Ingress"]
                    API1B["API Service"]
                    WEB1B["Web App"]
                end
            end

            subgraph ST1_MGMT["Management"]
                MON1["Monitoring<br/>(Grafana + Prometheus)"]
                LOGS1["Logging<br/>(Loki)"]
                CI1["CI/CD Runner<br/>(GitHub Actions)"]
            end
        end

        USERS1 --> DDOS1
        DDOS1 --> LB1
        LB1 --> FW1
        FW1 --> ING1
        ING1 --> API1
        ING1 --> WEB1
        API1 --> WORKER1
        API1 --> DB1
        API1 --> CACHE1
        API1 --> OBJ1
        CI1 -->|"kubectl apply"| ING1
    end
```

### Stage 2 — Hybrid (Hetzner + EKS)

```mermaid
flowchart TB
    subgraph STAGE2["**STAGE 2: Hybrid Architecture (Hetzner + AWS EKS)**"]

        subgraph INTERNET["🌐 Internet"]
            USERS["👥 Users / Clients"]
            US_USERS["🇺🇸 US Enterprise Users"]
            EU_USERS["🇪🇺 EU Users"]
        end

        subgraph ROUTING["Traffic Routing Layer"]
            CF["Cloudflare"]
            CF_EU["Cloudflare EU"]
            CF_US["Cloudflare US"]
        end

        subgraph HETZNER["🇩🇪 Hetzner Cloud (EU-Only / Non-Critical)"]
            subgraph H_NET["Network"]
                H_LB["Hetzner Load Balancer"]
                H_FW["Firewall"]
            end

            subgraph H_K8S["K3s / Talos Cluster"]
                subgraph H_NS_DEV["Namespace: dev-staging"]
                    H_WEB_DEV["Web App (dev)"]
                    H_API_DEV["API (dev)"]
                end

                subgraph H_NS_EU["Namespace: eu-services"]
                    H_EU_API["EU-Only API Service"]
                    H_EU_DB["PostgreSQL (EU data residency)"]
                    H_CACHE["Redis (EU)"]
                end
            end

            subgraph H_STORAGE["Storage"]
                H_OBJ["Hetzner Object Storage<br/>(Backups, Media)"]
            end
        end

        subgraph AWS["☁️ AWS (US / Regulated / Critical)"]
            subgraph AWS_VPC["VPC"]
                subgraph AWS_EKS["EKS Cluster"]
                    subgraph AWS_NS1["Namespace: us-production"]
                        AWS_ING["AWS Load Balancer Controller"]
                        subgraph AWS_SVC["Services"]
                            AWS_API["API Service"]
                            AWS_WEB["Web Service"]
                            AWS_WORKER["Workers (SQS-triggered)"]
                        end
                    end

                    subgraph AWS_NS2["Namespace: regulated"]
                        AWS_COMPLIANCE["Compliance Workloads"]
                    end
                end

                subgraph AWS_DATA["Managed Data Services"]
                    AWS_RDS["RDS PostgreSQL<br/>(Multi-AZ)"]
                    AWS_ELASTI["ElastiCache Redis"]
                    AWS_S3["S3 Buckets"]
                    AWS_SQS["SQS Queues"]
                    AWS_SECRETS["Secrets Manager"]
                end

                subgraph AWS_MGMT["AWS Management"]
                    AWS_CW["CloudWatch"]
                    AWS_CFN["Terraform / CloudFormation"]
                end
            end

            subgraph CI_CD["CI/CD Pipeline"]
                GH_ACTIONS["GitHub Actions"]
                GH_ACTIONS -->|"ECR"| AWS_EKS
                GH_ACTIONS -->|"kubectl"| H_K8S
            end
        end

        USERS --> CF
        US_USERS --> CF_US
        EU_USERS --> CF_EU

        CF_EU --> H_LB
        CF_US --> AWS_ING

        H_LB --> H_FW
        H_FW --> H_EU_API
        H_EU_API --> H_EU_DB
        H_EU_API --> H_CACHE
        H_EU_API --> H_OBJ

        AWS_ING --> AWS_API
        AWS_API --> AWS_RDS
        AWS_API --> AWS_ELASTI
        AWS_API --> AWS_S3
        AWS_WORKER --> AWS_SQS
        AWS_API --> AWS_SECRETS

        H_EU_API -.->|"VPN / Private Link"| AWS_API
    end
```

### Stage 3 — Full AWS EKS

```mermaid
flowchart TB
    subgraph STAGE3["**STAGE 3: Full AWS EKS Architecture**"]

        subgraph PUBLIC["🌐 Public Internet"]
            USERS3["👥 Users"]
            PARTNERS["🤝 Partners / APIs"]
            CDN["CloudFront CDN"]
        end

        subgraph EDGE["Edge / Security Layer"]
            WAF["AWS WAF<br/>(DDoS + Rate Limiting)"]
            SHIELD["AWS Shield Advanced"]
            ACM["ACM Certificates"]
        end

        subgraph AWS_VPC["AWS VPC"]
            subgraph PUB["Public Subnets"]
                ALB["Application Load Balancer"]
            end

            subgraph PRIV["Private Subnets — EKS Cluster"]
                subgraph EKS_NAMESPACES["Namespaces"]
                    subgraph PROD["namespace: production"]
                        PROD_INGRESS["Ingress (AWS LB Controller)"]
                        subgraph PROD_APP["Application Layer"]
                            PROD_WEB["Web App 🖥️"]
                            PROD_API["API Service 🖥️"]
                            PROD_WORKER["Async Workers 🖥️"]
                        end
                        subgraph PROD_ML["ML / AI Services"]
                            PROD_INFERENCE["Inference Endpoints"]
                            PROD_TRAINING["Training Jobs"]
                        end
                    end

                    subgraph STAGING["namespace: staging"]
                        STAGING_WEB["Web App"]
                        STAGING_API["API"]
                    end

                    subgraph MGMT_NS["namespace: management"]
                        MGMT1["Prometheus + Grafana"]
                        MGMT2["ArgoCD / Flux CD"]
                        MGMT3["External Secrets Operator"]
                    end
                end

                subgraph EKS_ADDONS["EKS Add-ons"]
                    COREDNS["CoreDNS"]
                    VPC_CNI["VPC CNI"]
                    EBS_CSI["EBS CSI"]
                    LB_CONTROLLER["LB Controller"]
                    METRICS["Metrics Server"]
                end
            end

            subgraph DATA_LAYER["Data Services (AWS Managed)"]
                subgraph CACHE["Cache"]
                    ELASTICACHE["ElastiCache Redis"]
                end
                subgraph DATABASES["Databases"]
                    RDS_PRIMARY["RDS PostgreSQL<br/>(Multi-AZ)"]
                    AURORA["Aurora Serverless"]
                end
                subgraph STORAGE["Object & File Storage"]
                    S3_WEB["S3 — Static Assets"]
                    S3_BACKUP["S3 — DB Backups"]
                    EFS["EFS — Shared FS"]
                end
                subgraph MESSAGING["Messaging"]
                    SQS["SQS Queues"]
                    SNS["SNS Pub/Sub"]
                    EVENT["EventBridge"]
                end
            end

            subgraph SECURITY["Security Services"]
                SECRETS["Secrets Manager"]
                KMS["KMS (Encryption)"]
                IAM["IAM Roles / IRSA"]
                GUARD["GuardDuty"]
                SEC_HUB["Security Hub"]
                CTRAIL["CloudTrail"]
            end

            subgraph CI_CD["CI/CD & DevOps"]
                GITHUB["GitHub Actions"]
                ECR["ECR Registry"]
                ARGOCD["ArgoCD GitOps"]
                TERRAFORM["Terraform IaC"]
                PAGER["PagerDuty"]
            end
        end

        USERS3 --> CDN
        PARTNERS --> CDN
        CDN --> WAF
        WAF --> ALB

        ALB --> PROD_INGRESS
        PROD_INGRESS --> PROD_WEB
        PROD_INGRESS --> PROD_API
        PROD_API --> PROD_WORKER

        PROD_API --> RDS_PRIMARY
        PROD_API --> ELASTICACHE
        PROD_API --> S3_WEB
        PROD_API --> SQS
        PROD_API --> SECRETS

        PROD_WORKER --> SQS
        PROD_WORKER --> RDS_PRIMARY

        RDS_PRIMARY --> S3_BACKUP

        GITHUB --> ECR
        ECR --> ARGOCD
        ARGOCD -->|"gitops"| EKS_NAMESPACES
        TERRAFORM -->|"terraform"| AWS_VPC

        GUARD --> SEC_HUB
        SEC_HUB --> PAGER
    end
```

---

## Migration Trigger Decision Flowchart

```mermaid
flowchart TD
    START(["🔍 Migration Trigger Assessment"]) --> Q1

    subgraph COMPLIANCE["Compliance Triggers"]
        Q1{"Do US enterprise customers<br/>require SOC 2?"}
        Q1 -->|Yes| COMPLY_SOC2["⚠️ SOC 2 Required<br/>Action: Migrate to EKS"]
        Q1 -->|No| Q2

        Q2{"Do you process payment card data?"}
        Q2 -->|Yes| COMPLY_PCI["⚠️ PCI DSS Required<br/>AWS is Level 1 Service Provider"]
        Q2 -->|No| Q3

        Q3{"Do you handle PHI / healthcare data?"}
        Q3 -->|Yes| COMPLY_HIPAA["⚠️ HIPAA Required<br/>Migrate with BAA signed"]
        Q3 -->|No| Q4

        Q4{"Do EU regulations require<br/>BSI C5 / KRITIS?"}
        Q4 -->|Yes| COMPLY_BSI["✅ Hetzner qualifies (BSI C5)"]
        Q4 -->|No| Q5
    end

    subgraph COST["Cost Triggers"]
        Q5{"Monthly infra spend<br/>> $5,000?"}
        Q5 -->|Yes| COST_ANALYSIS["⚠️ Analyze Reserved / Savings Plans"]
        Q5 -->|No| Q6

        Q6{"Need managed services<br/>(RDS, ElastiCache)?"}
        Q6 -->|Yes| COST_MANAGED["⚠️ Hetzner lacks managed services"]
        Q6 -->|No| Q7
    end

    subgraph SCALE["Scale & Reliability Triggers"]
        Q7{"Need multi-region HA<br/>with < 1hr RTO?"}
        Q7 -->|Yes| SCALE_HA["⚠️ Hetzner has no formal SLA"]
        Q7 -->|No| Q8

        Q8{"Experiencing Hetzner<br/>outage impact?"}
        Q8 -->|Yes| SCALE_OUTAGE["⚠️ No redundancy on Hetzner"]
        Q8 -->|No| Q9

        Q9{"Need < 10ms latency<br/>globally?"}
        Q9 -->|Yes| SCALE_GLOBAL["⚠️ Hetzner limited regions"]
        Q9 -->|No| Q10
    end

    subgraph SECURITY["Security Triggers"]
        Q10{"Need customer-facing<br/>pentest reports?"}
        Q10 -->|Yes| SEC_PENTEST["⚠️ AWS Artifact provides audit reports"]
        Q10 -->|No| Q11

        Q11{"Team lacks Kubernetes<br/>ops expertise?"}
        Q11 -->|Yes| SEC_OPS["⚠️ Self-managed K8s risk"]
        Q11 -->|No| Q12
    end

    subgraph DECISION["Decision Matrix"]
        Q12{"None of the above?"}
        Q12 -->|Stay on Hetzner| DECISION_STAY["✅ STAY ON HETZNER<br/>Re-assess quarterly"]
        Q12 -->|Any triggers| DECISION_MIGRATE["🔴 MIGRATE TO HYBRID<br/>→ Stage 2"]
        Q12 -->|Multiple critical| DECISION_FULL["🔴 MIGRATE FULL TO EKS<br/>→ Stage 3"]
    end

    COMPLY_SOC2 -.->|"→ trigger"| DECISION_MIGRATE
    COMPLY_PCI -.->|"→ trigger"| DECISION_MIGRATE
    COMPLY_HIPAA -.->|"→ trigger"| DECISION_MIGRATE
    COMPLY_BSI -.->|"Green only"| DECISION_STAY
    COST_ANALYSIS -.->|"→ trigger"| DECISION_MIGRATE
    COST_MANAGED -.->|"→ trigger"| DECISION_MIGRATE
    SCALE_HA -.->|"→ trigger"| DECISION_MIGRATE
    SCALE_OUTAGE -.->|"→ trigger"| DECISION_MIGRATE
    SCALE_GLOBAL -.->|"→ trigger"| DECISION_MIGRATE
    SEC_PENTEST -.->|"→ trigger"| DECISION_MIGRATE
    SEC_OPS -.->|"→ trigger"| DECISION_MIGRATE
```

---

## Quick Decision Matrix

```mermaid
flowchart LR
    subgraph INPUTS["📥 Inputs"]
        COST["💰 Monthly Spend"]
        COMPLIANCE["📋 Compliance Needs"]
        TEAM["👥 Team Size"]
        WORKLOADS["⚙️ Workload Type"]
    end

    subgraph PROCESS["⚙️ Decision Engine"]
        CHECK1{"SOC 2 / PCI / HIPAA Required?"}
        CHECK2{"US Enterprise Customers?"}
        CHECK3{"Monthly Spend > $5K?"}
        CHECK4{"Need Managed Services?"}
        CHECK5{"Multi-Region HA?"}
    end

    subgraph OUTPUTS["📤 Recommended Stage"]
        R1["**Stage 1: Hetzner Only**<br/>✅ Bootstrap / MVP<br/>✅ EU-focused SaaS<br/>✅ Dev/Staging"]
        R2["**Stage 2: Hetzner + EKS Hybrid**<br/>✅ US + EU mixed<br/>✅ Some regulated workloads<br/>✅ Growing startup"]
        R3["**Stage 3: Full AWS EKS**<br/>✅ US enterprise primary<br/>✅ PCI DSS / HIPAA<br/>✅ Series B+ / IPO path"]
    end

    INPUTS --> PROCESS
    PROCESS --> CHECK1
    CHECK1 -->|Yes| R3
    CHECK1 -->|No| CHECK2
    CHECK2 -->|Yes| R2
    CHECK2 -->|No| CHECK3
    CHECK3 -->|Yes| CHECK4
    CHECK3 -->|No| R1
    CHECK4 -->|Yes| R2
    CHECK4 -->|No| CHECK5
    CHECK5 -->|Yes| R2
    CHECK5 -->|No| R1
```

---

## Journey Timeline

```mermaid
gantt
    title Startup Infrastructure Journey: Hetzner → AWS EKS
    dateFormat  YYYY-MM
    axisFormat  %m/%Y

    section 🚀 Stage 1
    Self-managed K3s/Talos on Hetzner   :active, t1, 2024-01, 2025-03
    PostgreSQL + Redis on Hetzner        :t1, 2024-01, 2025-03
    GitHub Actions → kubectl apply       :t1, 2024-01, 2025-03
    Scale to 3-node cluster              :t1, 2024-06, 2025-03

    section 🔄 Stage 2
    Provision EKS cluster (us-east-1)    :t2, 2025-03, 2025-07
    Migrate US-facing APIs first         :t2, 2025-04, 2025-07
    Keep EU workloads on Hetzner         :t2, 2025-04, 2025-07
    Setup ArgoCD GitOps on EKS          :t2, 2025-05, 2025-07
    Configure AWS Secrets Manager + IRSA  :t2, 2025-06, 2025-09

    section 🏢 Stage 3
    Migrate remaining workloads          :t3, 2025-09, 2026-03
    Add Aurora Serverless               :t3, 2025-10, 2026-03
    Enable EKS Auto Mode / Fargate       :t3, 2025-11, 2026-03
    Multi-AZ + Multi-Region             :t3, 2025-12, 2026-03
    Full SOC 2 Type II attestation     :t3, 2026-01, 2026-03
```

---

## CI/CD Pipeline Evolution

### Stage 1 — Hetzner Only

```mermaid
sequenceDiagram
    autonumber
    Title: Stage 1 — CI/CD Pipeline (Hetzner Only)

    actor DEV as 👨‍💻 Developer
    participant GH as GitHub
    participant REG as Docker Hub / GHCR
    participant RUNNER as GitHub Actions
    participant K8S as K3s/Talos (Hetzner)
    participant APPS as Applications

    DEV->>GH: git push feature-branch
    GH->>GH: Pull Request opened
    DEV->>GH: Merge to main
    GH->>RUNNER: Trigger workflow

    RUNNER->>RUNNER: Run tests (pytest / jest)
    RUNNER->>RUNNER: lint + security scan
    RUNNER->>REG: docker build + docker push

    RUNNER->>K8S: kubectl set image deployment/api
    RUNNER->>K8S: kubectl rollout status
    RUNNER->>K8S: helm upgrade --install api ./charts/api

    K8S->>APPS: Rolling update pods
    K8S-->>DEV: ✅ Deploy notification
```

### Stage 2 — Hybrid

```mermaid
sequenceDiagram
    autonumber
    Title: Stage 2 — CI/CD Pipeline (Hetzner + AWS EKS Hybrid)

    actor DEV as 👨‍💻 Developer
    participant GH as GitHub Actions
    participant ECR as Amazon ECR
    participant GHCR as GH Container Registry
    participant EKS as AWS EKS (US/Regulated)
    participant HETZNER as K3s/Talos (Hetzner EU)
    participant SM as Secrets Manager (AWS)

    DEV->>GH: git push main
    GH->>GH: Run tests & security scans

    par US workloads → EKS
        GH->>ECR: docker build + push api-us:v3.0.0
        GH->>SM: Fetch DB credentials
        GH->>EKS: kubectl apply -f k8s/us-production/
        EKS->>EKS: Rolling update US services
        EKS-->>DEV: ✅ US workload deployed
    and EU workloads → Hetzner
        GH->>GHCR: docker build + push api-eu:v3.0.0
        GH->>HETZNER: kubectl set image deployment/api-eu
        HETZNER->>HETZNER: Rolling update EU services
        HETZNER-->>DEV: ✅ EU workload deployed
    end

    Note over SM,HETZNER: External Secrets Operator<br/>pulls from AWS SM → injects into Hetzner K8s
```

### Stage 3 — Full EKS

```mermaid
sequenceDiagram
    autonumber
    Title: Stage 3 — CI/CD Pipeline (Full AWS EKS)

    actor DEV as 👨‍💻 Developer
    participant GH as GitHub Actions
    participant SONAR as SonarCloud
    participant TRIVY as Trivy
    participant ECR as Amazon ECR
    participant SM as Secrets Manager
    participant TERRAFORM as Terraform Cloud
    participant EKS as AWS EKS
    participant ARGOCD as ArgoCD (GitOps)
    participant CW as CloudWatch

    DEV->>GH: git push main

    rect rgba(0, 50, 100, 0.1)
        Note over GH,TRIVY: Pre-deploy checks
        GH->>GH: Unit tests
        GH->>SONAR: Static code analysis
        GH->>TRIVY: Container image scan
        TRIVY-->>GH: ✅ No critical CVEs
    end

    par Container Build & Push
        GH->>ECR: docker build + push api:v4.0.0
        GH->>SM: Fetch secrets via OIDC role
    end

    par Infrastructure as Code
        GH->>TERRAFORM: terraform plan
        TERRAFORM-->>GH: ✅ Plan approved
        GH->>TERRAFORM: terraform apply
        TERRAFORM->>EKS: Update EKS add-ons / IRSA
    end

    par GitOps Sync
        ARGOCD->>ECR: Pull new image tag
        ARGOCD->>EKS: kubectl apply (auto-sync)
        ARGOCD-->>DEV: ✅ GitOps sync complete
    end

    rect rgba(0, 100, 0, 0.1)
        Note over EKS,CW: Post-deploy verification
        EKS->>CW: Emit metrics & logs
        CW->>DEV: Slack alert: ✅ Deployed
    end

    Note over GH,DEV: Full audit trail:<br/>CloudTrail logs every API call<br/>Shift-left security baked in
```

---

## Cost Comparison

### Hetzner vs AWS EKS

| Configuration | Hetzner | AWS EKS | Delta |
|---|---|---|---|
| 2 vCPU / 4GB RAM | €5.99/mo | ~$48 (€44) | **7x** |
| 4 vCPU / 8GB RAM | €11.99/mo | ~$96 (€88) | **7x** |
| 8 vCPU / 16GB RAM | €22.99/mo | ~$192 (€176) | **7.5x** |
| 16 vCPU / 32GB RAM | €43.99/mo | ~$384 (€352) | **8x** |
| 32 vCPU / 64GB RAM | €83.99/mo | ~$768 (€704) | **8.5x** |

### Annual Savings (Hetzner vs EKS at ~$800/mo AWS)

- **Monthly Delta**: ~€640
- **Annual Savings**: ~€7,680

### Hidden Cost Comparison

| Factor | Hetzner | AWS EKS |
|---|---|---|
| Server cost | ✅ Fixed | ❌ + EKS cluster (~$73/mo fixed) |
| DDoS protection | ✅ Free | ❌ Shield Advanced ($3K+/mo) |
| Egress costs | ✅ 20TB included (EU) | ❌ ~$90/TB |
| Managed K8s | ❌ Self-managed | ✅ Managed control plane |
| Managed DB/Cache | ❌ None | ✅ RDS, ElastiCache |
| Compliance certs | ❌ ISO 27001, BSI C5 only | ✅ SOC 2, PCI DSS, HIPAA, FedRAMP |
| Engineer ops time | ❌ Higher | ✅ Lower |

### When does EKS ROI make sense?

- 💰 Enterprise contract value **> €10K/mo**
- 💰 Time saved on ops **> 20hrs/mo**
- 💰 Compliance blocks **> €50K revenue**
- 💰 Managed DB replaces **1 engineer**

---

## Compliance Comparison

| Certification | Hetzner | AWS EKS |
|---|---|---|
| ISO 27001:2022 | ✅ | ✅ |
| BSI C5 Type 2 | ✅ | ✅ |
| SOC 2 | ❌ | ✅ |
| PCI DSS Level 1 | ❌ | ✅ |
| HIPAA BAA | ❌ | ✅ |
| FedRAMP | ❌ | ✅ |
| GDPR / EU Data Residency | ✅ | ✅ (Sovereign Cloud) |

---

## License

MIT
