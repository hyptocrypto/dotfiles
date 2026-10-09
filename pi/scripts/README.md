# Pi Scripts

Utility scripts installed to `~/.local/bin` by `install.sh`.

## ssh-private

SSH wrapper that restricts connections to RFC1918 private address ranges only.

**Allowed ranges:**
- `10.0.0.0/8` (10.x.x.x)
- `172.16.0.0/12` (172.16-31.x.x)  
- `192.168.0.0/16` (192.168.x.x)

**Usage:**
```bash
ssh-private user@192.168.1.100
ssh-private 10.0.0.5 -p 2222
ssh-private homeserver  # resolves hostname to IP first
```

**Why:** Pi agents can invoke this via lean-ctx allowlist for home network management without exposing arbitrary SSH access.
