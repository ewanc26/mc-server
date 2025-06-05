# DuckDNS Setup (Optional)

## What is DuckDNS?

DuckDNS is a free dynamic DNS service. The script `setup_duckdns.sh` automates updating your IP every hour.

### Prerequisites

* <https://www.duckdns.org> account and token.
* `curl`, `cron` installed

#### Ubuntu

```bash
sudo apt update && sudo apt install curl cron -y
```

#### macOS

* `curl` is pre-installed.
* `cron` available, but `launchd` is preferred.

### Running the Script

```bash
cd mc-server
chmod +x setup_duckdns.sh
./setup_duckdns.sh
```

Follow prompts for domain and token.

### macOS Notes

* May require Full Disk Access for Terminal.
* Consider using `launchd` instead of `cron`.
