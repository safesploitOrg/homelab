## Components

### DNS GitOps `git_clone_dns_configs_bind.sh`

Synchronises DNS configuration Git repository to DNS servers.

Responsibilities:

- Detect repository changes
- Clone latest configuration
- Deploy zone files
- Generate DNS records
- Reload BIND
- Track deployed commit versions

This script implements the GitOps deployment workflow used by the DNS platform.

---

### CI/CD Workflow `bind-ci.yml`

GitHub Actions workflow used to validate DNS configuration before deployment.

Responsibilities:

- Build a clean AlmaLinux environment
- Install BIND
- Validate `named.conf`
- Validate zone files
- Start a temporary BIND instance
- Execute DNS queries

This workflow helps prevent invalid DNS configuration from reaching production systems.
