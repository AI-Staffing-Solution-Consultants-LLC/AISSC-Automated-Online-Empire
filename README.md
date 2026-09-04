# AISSC-Automated-Online Empire

This repository contains the production-grade technical implementation of **AISSC (Electron-Online)**, a fully autonomous, self-bootstrapping multi-agent enterprise system. The system is governed by a three-manager OpenClaw core (Sheryl, Krieger, Malory) and utilizes the NEXUS Systems Framework as an enclosed, structured cognitive 'Hive Mind' accessed via a Model Context Protocol (MCP) server.

## Repository Structure

This is a monorepo organized by functional components located in the `components/` directory.

| Component Directory | Role in AISSC Architecture | Target GCP Project (Illustrative) |
| :--- | :--- | :--- |
| `components/sheryl-gateway/` | Control Plane & MCP Router Entrypoint | `prj-ais-core-prod`, `prj-ais-core-dev` |
| `components/krieger-tech-systems/` | Tactical Action Layer (Infrastructure as Code) | `prj-ais-krieger-prod`, `prj-ais-krieger-dev` |
| `components/malory-business-ops/` | Strategic Business Operations Layer | `prj-ais-malory-prod`, `prj-ais-malory-dev` |
| `components/pam-workforce/` | Workforce & Agent Management Layer | `prj-ais-pam-prod`, `prj-ais-pam-dev` |

## Branching Strategy & CI/CD

This repository utilizes GitHub Actions configured for directory-scoped deployments to manage independent CI/CD pipelines for each component.

*   **`main`**: Production branch. Pushes to `main` automatically trigger `terraform apply` against the **Production** GCP project IDs configured in GitHub Secrets.
*   **`develop`**: Staging/Integration branch. Pushes to `develop` trigger `terraform apply` against the **Development/Staging** GCP project IDs.
*   **`feature/*`**: Feature development. Opening a Pull Request from a feature branch to `develop` or `main` will trigger a `terraform plan` check against the target environment.

## Infrastructure Overview (NEXUS-SUAD Framework)

The core infrastructure is defined via Terraform and designed according to the **Suad-Claw-Nexus-AntiGrav** doctrine, emphasizing:

1.  **Serverless-First:** Utilizing Google Cloud Run Services configured with `min_instance_count = 0` to eliminate idle spend.
2.  **Stateless Memory:** OpenViking RAG shared memory is implemented via GCS FUSE mounts, not persistent database instances.
3.  **Event-Driven:** Asynchronous delegation managed by Google Cloud Tasks and Pub/Sub.
4.  **Secrets Management:** Secure injection from Infisical via Google Secret Manager.

## Deployment Setup (First-Time)

1.  Initialize four separate GCP projects for the components.
2.  Configure Google Cloud Workload Identity Federation in each project.
3.  Add the required secrets to this GitHub repository:
    *   `REQUIRED_GCP_PROJECT_ID_PROD`
    *   `REQUIRED_GCP_PROJECT_ID_DEV`
    *   `WORKLOAD_IDENTITY_PROVIDER_ID`
4.  Initialize Terraform states for each component (e.g., using GCS buckets).
