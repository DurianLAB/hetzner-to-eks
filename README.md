# Startup Migration: Hetzner to AWS EKS

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
    START([Startup Founded]) --> FUNDING
    FUNDING{Funding Stage?}
    FUNDING -->|Bootstrapped| EVAL
    FUNDING -->|Seed / Series A| EVAL

    EVAL{Hetzner sufficient?}
    EVAL -->|Yes| DEPLOY
    EVAL -->|No| ESCALATE

    DEPLOY["Deploy on Hetzner Cloud"] --> K8S
    K8S["Self-managed K8s (RKE2 / Talos / K3s)"] --> GROW
    GROW["Iterate & Grow on Hetzner"] --> TRIGGERS

    TRIGGERS{Migration triggers?}
    TRIGGERS -->|US Enterprise Deals| ESCALATE
    TRIGGERS -->|SOC 2 Required| ESCALATE
    TRIGGERS -->|HIPAA / PCI DSS| ESCALATE
    TRIGGERS -->|$5K+/mo spend| ESCALATE
    TRIGGERS -->|Multi-region SLA needed| ESCALATE
    TRIGGERS -->|No triggers| STAY["Stay on Hetzner"]

    ESCALATE["Identify EKS-ready workloads"] --> SEGREGATE
    SEGREGATE["Segregate workloads"] --> WHICH{Which to migrate first?}
    WHICH -->|Customer-facing APIs| P1["1. Customer-facing services"]
    WHICH -->|US customer workloads| P2["2. Regulated workloads"]
    WHICH -->|Critical path services| P3["3. High-availability services"]

    P1 --> SETUP["Provision EKS Cluster"]
    P2 --> SETUP
    P3 --> SETUP
    SETUP --> CI["Setup CI/CD to EKS"]
    CI --> FIRST["Migrate first workload"]
    FIRST --> VERIFY["Verify in production"]
    VERIFY --> STABLE{Is it stable?}
    STABLE -->|Yes| KEEP["Keep Hetzner for dev/staging and EU-only services"]
    STABLE -->|No| ROLLBACK["Rollback to Hetzner"]
    ROLLBACK --> FIX(["Fix issues and retry"])
    FIX --> FIRST
    KEEP --> ITERATE["Iterate: migrate next workload"]
    ITERATE --> MORE{More workloads?}
    MORE -->|Yes| WHICH
    MORE -->|No| HYBRID["Stable Hybrid State"]

    HYBRID --> FUTURE{Long-term strategy?}
    FUTURE -->|US Enterprise Primary| FULL["Migrate remaining to EKS"]
    FUTURE -->|Cost Optimization| MULTI["Hetzner + EKS + Spot"]
    FUTURE -->|EU Sovereignty| EU["Scale Hetzner + use EKS-EU"]

    FULL --> FINAL1["Full AWS EKS Platform"]
    MULTI --> FINAL2["Multi-Cloud Strategy"]
    EU --> FINAL3["EU-First with AWS EKS-EU"]
```

---

## Architecture Diagrams

### Stage 1 — Hetzner Only

```mermaid
flowchart TB
    subgraph STAGE1["STAGE 1: Hetzner Only"]
        USERS1["Users / Clients"] --> DDOS1
        DDOS1["DDoS Protection (Cloudflare)"] --> LB1
        LB1["Load Balancer (Cloudflare)"] --> FW1
        FW1["Firewall Rules"] --> ING1

        ING1["Ingress Controller (nginx / Traefik)"] --> API1
        ING1 --> WEB1["Web App"]

        API1["API Service"] --> WORKER1["Background Workers"]
        API1 --> DB1["PostgreSQL (Self-managed)"]
        API1 --> CACHE1["Redis (Self-managed)"]
        API1 --> OBJ1["Object Storage (Hetzner)"]

        subgraph K8S["Kubernetes Cluster (Self-Managed)"]
            subgraph NS1["Namespace: production"]
                ING1
                API1
                WEB1
                WORKER1
                DB1
                CACHE1
                OBJ1
            end
            subgraph NS2["Namespace: staging"]
                ING1B["Ingress"]
                API1B["API Service"]
                WEB1B["Web App"]
            end
        end

        CI1["CI/CD Runner (GitHub Actions)"] --> ING1
        MON1["Monitoring (Grafana + Prometheus)"]
        LOGS1["Logging (Loki)"]
    end
```

### Stage 2 — Hybrid (Hetzner + EKS)

```mermaid
flowchart TB
    subgraph STAGE2["STAGE 2: Hybrid Architecture"]

        subgraph INTERNET["Internet"]
            US["Users / Clients"]
            US_US["US Enterprise Users"]
            EU_US["EU Users"]
        end

        US --> CF["Cloudflare"]
        US_US --> CF_US["Cloudflare US"]
        EU_US --> CF_EU["Cloudflare EU"]

        subgraph HETZNER["Hetzner Cloud (EU-Only / Non-Critical)"]
            CF_EU --> H_LB["Hetzner Load Balancer"]
            H_LB --> H_FW["Firewall"]
            H_FW --> H_API["EU-Only API Service"]
            H_API --> H_DB["PostgreSQL (EU data residency)"]
            H_API --> H_CACHE["Redis (EU)"]
            H_API --> H_OBJ["Hetzner Object Storage"]

            subgraph H_K8S["K3s / Talos Cluster"]
                subgraph H_NS1["Namespace: dev-staging"]
                    H_WEB_DEV["Web App (dev)"]
                    H_API_DEV["API (dev)"]
                end
                subgraph H_NS2["Namespace: eu-services"]
                    H_API
                    H_DB
                    H_CACHE
                end
            end
        end

        subgraph AWS["AWS (US / Regulated / Critical)"]
            CF_US --> AWS_ING["AWS Load Balancer Controller"]
            AWS_ING --> AWS_API["API Service"]
            AWS_ING --> AWS_WEB["Web Service"]
            AWS_API --> AWS_WORKER["Workers (SQS-triggered)"]
            AWS_API --> AWS_RDS["RDS PostgreSQL (Multi-AZ)"]
            AWS_API --> AWS_ELASTI["ElastiCache Redis"]
            AWS_API --> AWS_S3["S3 Buckets"]
            AWS_WORKER --> AWS_SQS["SQS Queues"]
            AWS_API --> AWS_SECRETS["Secrets Manager"]

            subgraph AWS_EKS["EKS Cluster"]
                subgraph AWS_NS1["Namespace: us-production"]
                    AWS_ING
                    AWS_API
                    AWS_WEB
                    AWS_WORKER
                end
                subgraph AWS_NS2["Namespace: regulated"]
                    AWS_COMP["Compliance Workloads"]
                end
            end
        end

        H_API -.-> AWS_API
        GH["GitHub Actions"] --> AWS_EKS
        GH --> H_K8S
    end
```

### Stage 3 — Full AWS EKS

```mermaid
flowchart TB
    subgraph STAGE3["STAGE 3: Full AWS EKS"]

        subgraph PUBLIC["Internet"]
            USERS["Users"]
            PARTNERS["Partners / APIs"]
            CDN["CloudFront CDN"]
        end

        USERS --> CDN
        PARTNERS --> CDN
        CDN --> WAF["AWS WAF (DDoS + Rate Limiting)"]
        WAF --> ALB["Application Load Balancer"]
        ALB --> PROD_INGRESS["Ingress (AWS LB Controller)"]
        PROD_INGRESS --> PROD_WEB["Web App"]
        PROD_INGRESS --> PROD_API["API Service"]
        PROD_INGRESS --> PROD_WORKER["Async Workers"]
        PROD_API --> PROD_INFERENCE["Inference Endpoints"]
        PROD_API --> RDS["RDS PostgreSQL (Multi-AZ)"]
        PROD_API --> ELASTI["ElastiCache Redis"]
        PROD_API --> S3_WEB["S3 - Static Assets"]
        PROD_API --> SQS["SQS Queues"]
        PROD_API --> SECRETS["Secrets Manager"]
        PROD_WORKER --> SQS
        PROD_WORKER --> RDS

        subgraph EKS["EKS Cluster"]
            subgraph NS_PROD["namespace: production"]
                PROD_INGRESS
                PROD_WEB
                PROD_API
                PROD_WORKER
                PROD_INFERENCE
            end
            subgraph NS_STAGING["namespace: staging"]
                STAGING_WEB["Web App"]
                STAGING_API["API"]
            end
            subgraph NS_MGMT["namespace: management"]
                GRAFANA["Prometheus + Grafana"]
                ARGOCD["ArgoCD / Flux CD"]
                ESO["External Secrets Operator"]
            end
        end

        subgraph DATA["Data Services (AWS Managed)"]
            RDS
            ELASTI
            S3_WEB
            S3_BACKUP["S3 - DB Backups"]
            EFS["EFS - Shared FS"]
            SQS
            SNS["SNS Pub/Sub"]
            EVENT["EventBridge"]
            AURORA["Aurora Serverless"]
        end

        subgraph SEC["Security Services"]
            SECRETS
            KMS["KMS (Encryption)"]
            IAM["IAM Roles / IRSA"]
            GUARD["GuardDuty"]
            SEC_HUB["Security Hub"]
            CTRAIL["CloudTrail"]
        end

        subgraph CI["CI/CD & DevOps"]
            GITHUB["GitHub Actions"]
            ECR["ECR Registry"]
            ARGOCD
            TERRAFORM["Terraform IaC"]
            PAGER["PagerDuty"]
        end

        GITHUB --> ECR
        ECR --> ARGOCD
        ARGOCD --> EKS
        GUARD --> SEC_HUB
        SEC_HUB --> PAGER
    end
```

---

## Migration Trigger Decision Flowchart

```mermaid
flowchart TD
    START(["Migration Trigger Assessment"]) --> Q1

    subgraph COMPLIANCE["Compliance Triggers"]
        Q1{US enterprise customers require SOC 2?}
        Q1 -->|Yes| C1["SOC 2 Required - migrate to EKS"]
        Q1 -->|No| Q2

        Q2{Process payment card data?}
        Q2 -->|Yes| C2["PCI DSS Required - AWS is Level 1 SP"]
        Q2 -->|No| Q3

        Q3{Handle PHI or healthcare data?}
        Q3 -->|Yes| C3["HIPAA Required - migrate with BAA"]
        Q3 -->|No| Q4

        Q4{EU regulations require BSI C5 or KRITIS?}
        Q4 -->|Yes| C4["Hetzner qualifies (BSI C5)"]
        Q4 -->|No| Q5
    end

    subgraph COST["Cost Triggers"]
        Q5{Monthly infra spend over $5000?}
        Q5 -->|Yes| C5["Analyze Reserved / Savings Plans"]
        Q5 -->|No| Q6

        Q6{Need managed services like RDS?}
        Q6 -->|Yes| C6["Hetzner lacks managed services"]
        Q6 -->|No| Q7
    end

    subgraph SCALE["Scale & Reliability Triggers"]
        Q7{Need multi-region HA with under 1hr RTO?}
        Q7 -->|Yes| C7["Hetzner has no formal SLA"]
        Q7 -->|No| Q8

        Q8{Experiencing Hetzner outage impact?}
        Q8 -->|Yes| C8["No redundancy on Hetzner"]
        Q8 -->|No| Q9

        Q9{Need under 10ms latency globally?}
        Q9 -->|Yes| C9["Hetzner limited regions"]
        Q9 -->|No| Q10
    end

    subgraph SECURITY["Security Triggers"]
        Q10{Need customer-facing pentest reports?}
        Q10 -->|Yes| C10["AWS Artifact provides audit reports"]
        Q10 -->|No| Q11

        Q11{Team lacks Kubernetes ops expertise?}
        Q11 -->|Yes| C11["Self-managed K8s risk"]
        Q11 -->|No| Q12
    end

    subgraph DECISION["Decision Matrix"]
        Q12{None of the above?}
        Q12 -->|Stay on Hetzner| D1["STAY ON HETZNER - Re-assess quarterly"]
        Q12 -->|Any triggers| D2["MIGRATE TO HYBRID - Stage 2"]
        Q12 -->|Multiple critical| D3["MIGRATE FULL TO EKS - Stage 3"]
    end

    C1 -.-> D2
    C2 -.-> D2
    C3 -.-> D2
    C4 -.-> D1
    C5 -.-> D2
    C6 -.-> D2
    C7 -.-> D2
    C8 -.-> D2
    C9 -.-> D2
    C10 -.-> D2
    C11 -.-> D2
```

---

## Quick Decision Matrix

```mermaid
flowchart LR
    subgraph INPUTS["Inputs"]
        COST["Monthly Spend"]
        COMPLIANCE["Compliance Needs"]
        TEAM["Team Size"]
        WORKLOADS["Workload Type"]
    end

    subgraph PROCESS["Decision Engine"]
        CHECK1{SOC 2 or PCI or HIPAA Required?}
        CHECK2{US Enterprise Customers?}
        CHECK3{Monthly Spend over $5K?}
        CHECK4{Need Managed Services?}
        CHECK5{Multi-Region HA?}
    end

    subgraph OUTPUTS["Recommended Stage"]
        R1["Stage 1: Hetzner Only Bootstrap MVP EU-focused SaaS Dev/Staging"]
        R2["Stage 2: Hetzner plus EKS Hybrid US plus EU mixed Some regulated workloads Growing startup"]
        R3["Stage 3: Full AWS EKS US enterprise primary PCI DSS HIPAA Series B plus IPO path"]
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
    title Startup Infrastructure Journey
    dateFormat  YYYY-MM
    axisFormat  %m/%Y

    section Stage 1
    Self-managed K3s/Talos on Hetzner   :active, t1, 2024-01, 2025-03
    PostgreSQL + Redis on Hetzner        :t1, 2024-01, 2025-03
    GitHub Actions to kubectl apply      :t1, 2024-01, 2025-03
    Scale to 3-node cluster             :t1, 2024-06, 2025-03

    section Stage 2
    Provision EKS cluster us-east-1      :t2, 2025-03, 2025-07
    Migrate US-facing APIs first        :t2, 2025-04, 2025-07
    Keep EU workloads on Hetzner       :t2, 2025-04, 2025-07
    Setup ArgoCD GitOps on EKS          :t2, 2025-05, 2025-07
    Configure AWS Secrets Manager IRSA   :t2, 2025-06, 2025-09

    section Stage 3
    Migrate remaining workloads         :t3, 2025-09, 2026-03
    Add Aurora Serverless              :t3, 2025-10, 2026-03
    Enable EKS Auto Mode Fargate        :t3, 2025-11, 2026-03
    Multi-AZ plus Multi-Region          :t3, 2025-12, 2026-03
    Full SOC 2 Type II attestation     :t3, 2026-01, 2026-03
```

---

## CI/CD Pipeline Evolution

### Stage 1 — Hetzner Only

```mermaid
sequenceDiagram
    autonumber
    participant DEV as Developer
    participant GH as GitHub
    participant REG as Docker Hub GHCR
    participant RUNNER as GitHub Actions
    participant K8S as K3s/Talos Hetzner
    participant APPS as Applications

    DEV->>GH: git push feature-branch
    DEV->>GH: Merge to main
    GH->>RUNNER: Trigger workflow

    RUNNER->>RUNNER: Run tests
    RUNNER->>RUNNER: lint + security scan
    RUNNER->>REG: docker build + push

    RUNNER->>K8S: kubectl set image deployment/api
    RUNNER->>K8S: helm upgrade api chart

    K8S->>APPS: Rolling update pods
    K8S-->>DEV: Deploy notification
```

### Stage 2 — Hybrid

```mermaid
sequenceDiagram
    autonumber
    participant DEV as Developer
    participant GH as GitHub Actions
    participant ECR as Amazon ECR
    participant GHCR as GH Container Registry
    participant EKS as AWS EKS US Regulated
    participant HETZNER as K3s/Talos Hetzner EU
    participant SM as Secrets Manager AWS

    DEV->>GH: git push main
    GH->>GH: Run tests and security scans

    par US workloads to EKS
        GH->>ECR: docker build push api-us:v3.0.0
        GH->>SM: Fetch DB credentials
        GH->>EKS: kubectl apply us-production
        EKS->>EKS: Rolling update US services
        EKS-->>DEV: US workload deployed
    and EU workloads to Hetzner
        GH->>GHCR: docker build push api-eu:v3.0.0
        GH->>HETZNER: kubectl set image api-eu
        HETZNER->>HETZNER: Rolling update EU services
        HETZNER-->>DEV: EU workload deployed
    end

    Note over SM,HETZNER: External Secrets Operator pulls from AWS SM
```

### Stage 3 — Full EKS

```mermaid
sequenceDiagram
    autonumber
    participant DEV as Developer
    participant GH as GitHub Actions
    participant SONAR as SonarCloud
    participant TRIVY as Trivy
    participant ECR as Amazon ECR
    participant SM as Secrets Manager
    participant TERRAFORM as Terraform Cloud
    participant EKS as AWS EKS
    participant ARGOCD as ArgoCD GitOps
    participant CW as CloudWatch

    DEV->>GH: git push main
    GH->>GH: Unit tests
    GH->>SONAR: Static code analysis
    GH->>TRIVY: Container image scan
    TRIVY-->>GH: No critical CVEs

    par Container Build Push
        GH->>ECR: docker build push api:v4.0.0
        GH->>SM: Fetch secrets via OIDC role
    end

    par Infrastructure as Code
        GH->>TERRAFORM: terraform plan
        TERRAFORM-->>GH: Plan approved
        GH->>TERRAFORM: terraform apply
        TERRAFORM->>EKS: Update EKS add-ons
    end

    par GitOps Sync
        ARGOCD->>ECR: Pull new image tag
        ARGOCD->>EKS: kubectl apply auto-sync
        ARGOCD-->>DEV: GitOps sync complete
    end

    EKS->>CW: Emit metrics and logs
    CW->>DEV: Slack alert deployed

    Note over GH,DEV: Full audit trail via CloudTrail
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

### Annual Savings

- **Monthly Delta**: ~€640
- **Annual Savings on Hetzner**: ~€7,680

### Hidden Cost Comparison

| Factor | Hetzner | AWS EKS |
|---|---|---|
| Server cost | Fixed | Plus EKS cluster (~$73/mo fixed) |
| DDoS protection | Free | Shield Advanced (additional cost) |
| Egress costs | 20TB included (EU) | ~$90/TB |
| Managed K8s | Self-managed | Managed control plane |
| Managed DB/Cache | None | RDS, ElastiCache |
| Compliance certs | ISO 27001, BSI C5 only | SOC 2, PCI DSS, HIPAA, FedRAMP |
| Engineer ops time | Higher | Lower |

### When does EKS ROI make sense?

- Enterprise contract value **over €10K/mo**
- Time saved on ops **over 20hrs/mo**
- Compliance blocks **over €50K revenue**
- Managed DB replaces **1 engineer**

---

## Compliance Comparison

| Certification | Hetzner | AWS EKS |
|---|---|---|
| ISO 27001:2022 | Yes | Yes |
| BSI C5 Type 2 | Yes | Yes |
| SOC 2 | No | Yes |
| PCI DSS Level 1 | No | Yes |
| HIPAA BAA | No | Yes |
| FedRAMP | No | Yes |
| GDPR / EU Data Residency | Yes | Yes (Sovereign Cloud) |

---

## License

MIT
