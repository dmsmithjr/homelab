# Homelab → Portfolio Sync Setup

`homelab-sync.sh` runs on the Proxmox host and pushes to this repo. The portfolio's Lab Log page reads from it:

- **Live status:** `status.json` on the `status` branch, refreshed every 15 minutes
- **Lab Log entries:** commits on `main` whose message starts with `log:`
- **Config backups:** sanitized Proxmox VM/LXC configs in `proxmox/`, synced nightly

Nothing on the homelab is exposed to the internet. The host only makes outbound pushes to GitHub.

## 1. Create a fine-grained GitHub token

1. GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Fine-grained tokens** → **Generate new token**
2. **Token name:** `proxmox-homelab-sync`
3. **Expiration:** your choice. When it expires, generate a new one and repeat step 3 below.
4. **Repository access:** *Only select repositories* → `dmsmithjr/homelab`
5. **Permissions → Repository permissions → Contents:** *Read and write*. Leave everything else at *No access*.
6. **Generate token** and copy it (starts with `github_pat_`). GitHub only shows it once.

## 2. Install git and clone the repo (on the Proxmox host, as root)

```bash
apt update && apt install -y git
git clone https://github.com/dmsmithjr/homelab.git /opt/homelab
cd /opt/homelab
git config user.name "dmsmithjr"
git config user.email "demetriussmith247@gmail.com"
```

## 3. Store the token

```bash
cd /opt/homelab
git config credential.helper "store --file=/root/.homelab-git-credentials"
read -rsp "Paste token: " TOKEN; echo
printf 'https://dmsmithjr:%s@github.com\n' "$TOKEN" > /root/.homelab-git-credentials
unset TOKEN
chmod 600 /root/.homelab-git-credentials
```

`read -s` keeps the token out of your shell history. The file is readable only by root, and the token can only touch this one repo.

## 4. Test it

```bash
chmod +x /opt/homelab/scripts/homelab-sync.sh
/opt/homelab/scripts/homelab-sync.sh status
/opt/homelab/scripts/homelab-sync.sh configs
```

Check GitHub: a `status` branch with `status.json` should appear, plus a `proxmox/` folder on `main`. **Look through `proxmox/` before going further** and make sure nothing sensitive got through. Add words to `SECRET_PATTERN` in the script if needed.

## 5. Schedule it

```bash
cat > /etc/cron.d/homelab-sync <<'EOF'
*/15 * * * * root /opt/homelab/scripts/homelab-sync.sh status  >> /var/log/homelab-sync.log 2>&1
0 3 * * *    root /opt/homelab/scripts/homelab-sync.sh configs >> /var/log/homelab-sync.log 2>&1
EOF
```

## Posting a Lab Log entry

From the Proxmox shell:

```bash
/opt/homelab/scripts/homelab-sync.sh log "Set up Grafana and Prometheus monitoring in an LXC"
```

Or from any machine, start a commit message with `log:` and push. Either way it shows on the portfolio within a few minutes.
