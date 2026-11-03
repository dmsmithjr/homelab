# 🏠 My Homelab Architecture & Infrastructure

Welcome to my central homelab repository! This codebase and documentation hub tracks the architecture, container configurations, and automation scripts powering my self-hosted environment. 

---

## 🛠️ Hardware Inventory

| Component | Specification / Model | Role / Purpose |
| :--- | :--- | :--- |
| **Hypervisor Host** | HP Z440 Workstation (8 total RAM slots, 2 occupied) | Runs **Proxmox VE** hypervisor hosting virtual machines and container environments. |
| **Storage / NAS** | OpenMediaVault NAS | Network-attached storage for backups, media, and persistent data volumes. |
| **Edge / Compute** | Raspberry Pi 3 | Low-power companion node for auxiliary network services and lightweight monitoring. |

---

## 🌐 Network & System Architecture

*   **Virtualization Layer:** Managed via Proxmox VE, utilizing isolated virtual machines and Linux containers (LXCs) for service segmentation.
*   **Storage Architecture:** Centralized data storage managed through OpenMediaVault, providing NFS/SMB shares to backing containers and virtual hosts.
*   **Security & Testing Labs:** Isolated sandbox environments including Kali Linux VMs and Metasploitable2 testing instances for security validation.

---

## 📂 Repository Structure

```text
homelab/
├── README.md                  # Main overview and system documentation
├── compose/                   # Docker Compose stacks (monitoring, databases, media)
│   ├── monitoring/
│   │   └── docker-compose.yml
│   └── db/
│       └── docker-compose.yml
├── scripts/                   # System health checks, maintenance, and backup scripts
│   ├── health-check.sh
│   └── backup-nas.sh
└── docs/                      # Extended notes, architecture diagrams, and runbooks
    └── network-topology.md
