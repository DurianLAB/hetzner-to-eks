# Startup Migration: Hetzner → AWS EKS
## Architecture & Decision Diagrams

```
diagrams/
├── README.md                 ← You are here
├── activity-diagram.mmd      ← Migration journey (main flow)
├── architecture-stage1-hetzner.mmd   ← Stage 1: Hetzner only
├── architecture-stage2-hybrid.mmd     ← Stage 2: Hetzner + EKS hybrid
├── architecture-stage3-full-eks.mmd  ← Stage 3: Full AWS EKS
├── decision-flowchart.mmd    ← Migration trigger decision tree
├── decision-matrix.mmd       ← Quick decision matrix
├── journey-timeline.mmd      ← Timeline of progression
├── sequence-cicd-stage1.mmd  ← CI/CD: Hetzner only
├── sequence-cicd-stage2.mmd  ← CI/CD: Hybrid pipeline
├── sequence-cicd-stage3.mmd  ← CI/CD: Full EKS pipeline
└── cost-comparison.mmd       ← Cost comparison Hetzner vs EKS
```

## Quick Reference: When to Use Each Diagram

| Diagram | Audience | Purpose |
|---|---|---|
| `activity-diagram.mmd` | Engineers + Management | End-to-end migration journey with decision points |
| `architecture-stage*.mmd` | Engineers | Infrastructure layout at each stage |
| `decision-flowchart.mmd` | CTO / Engineering Lead | Should we migrate? What triggers it? |
| `decision-matrix.mmd` | Any | 30-second quick decision guide |
| `journey-timeline.mmd` | All stakeholders | Timeline of progression phases |
| `sequence-cicd-*.mmd` | DevOps / Platform Engineers | CI/CD evolution at each stage |
| `cost-comparison.mmd` | CTO / CFO | TCO comparison Hetzner vs AWS EKS |

## 3-Stage Summary

### Stage 1 — Hetzner Foundation
- **Team**: 1-5 engineers
- **Spend**: €20-100/mo
- **Stack**: Hetzner Cloud + Self-managed K3s/Talos + GitHub Actions
- **CI/CD**: GitHub Actions → kubectl
- **Data**: Self-managed PostgreSQL + Redis on Hetzner
- **Compliance**: ISO 27001 (Hetzner), GDPR

### Stage 2 — Hetzner + EKS Hybrid
- **Team**: 5-15 engineers
- **Spend**: €100-500/mo (Hetzner) + ~$500-2000/mo (AWS)
- **Stack**: EKS for US/regulated, Hetzner for EU/non-critical
- **CI/CD**: GitHub Actions → ECR + ArgoCD (GitOps)
- **Data**: Hetzner for EU data residency, RDS + ElastiCache on AWS
- **Compliance**: AWS SOC 2, ISO 27001, BSI C5 (Hetzner)

### Stage 3 — Full AWS EKS
- **Team**: 15+ engineers
- **Spend**: $2K-20K/mo on AWS
- **Stack**: Full AWS ecosystem (EKS, RDS Aurora, ElastiCache, S3, etc.)
- **CI/CD**: GitHub Actions + Terraform + ArgoCD + CloudFormation
- **Data**: Fully managed AWS services, multi-AZ
- **Compliance**: SOC 2 Type II, PCI DSS L1, HIPAA BAA, FedRAMP, ISO 27001

---

## Viewing Diagrams

### VS Code (Recommended)
1. Install **Mermaid Markdown Preview** extension
2. Open any `.mmd` file
3. Click **"Open Preview"** button

### Mermaid Live Editor
1. Go to [mermaid.live](https://mermaid.live)
2. Paste contents of any `.mmd` file
3. Edit in real-time, export as PNG/SVG

### CLI
```bash
# Install mermaid-cli
npm install -g @mermaid-js/mermaid-cli

# Convert to PNG
mmdc -i activity-diagram.mmd -o activity-diagram.png

# Convert all diagrams
for f in *.mmd; do mmdc -i "$f" -o "${f%.mmd}.png"; done
```

### GitHub / GitLab
Add `.mmd` files directly into Markdown:
````markdown
```mermaid
%% paste diagram content here
```
````
