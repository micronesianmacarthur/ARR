# AGENTS.md — servarr stack

## Symptoms
- All containers on `arr_network` can't reach the internet: both DNS and TCP time out,
  while the Docker host itself has working connectivity.
- Typical curl inside `radarr`:
  - `curl https://www.google.com` → `curl: (28) Resolving timed out`
  - `curl http://1.1.1.1` → `curl: (28) Connection timed out`

## Root cause (diagnosed 2026-09-17)
The WiFi/ISP link returns **every reply packet with `IP ttl 1`**. Evidence (tcpdump on
`wlp1s0` during a failed container curl):

```
142.251.155.119.443 > 192.168.30.250.55850: Flags [S.], ... ttl 1
192.168.30.250 > 142.251.155.119: ICMP time exceeded in-transit
```

- The container's SYN leaves fine (TTL 63 after host forward), the SYN-ACK comes back
  with TTL 1.
- **Host-local** connections still work because local delivery never decrements TTL.
- **Forwarded** (container) connections die: `ip_forward` decrements the reply TTL
  `1 -> 0`, which triggers `ICMP time exceeded in-transit` and drops the packet before
  it ever reaches the bridge. This is why the host works but every container times out.
- DNS failing (containers use `dns: [8.8.8.8, 8.8.4.4]`) is the SAME bug: UDP replies
  also arrive with TTL 1 and are dropped on forward. 8.8.8.8 itself is not blocked.

## Fix (runtime, immediate)
Run once (via `sudo`, or from a `nicolaka/netshoot` container with
`--network host --privileged`, which shares the host netns):

```
iptables -t mangle -I PREROUTING 1 -i wlp1s0 -m conntrack --ctstate RELATED,ESTABLISHED -j TTL --ttl-set 62
```

Bump the incoming reply TTL before forwarding so the reply survives the single
`ip_forward` decrement.

This rule is in the kernel's ip table and is **lost on reboot** unless persisted.

## Persistence (UFW-backed)
> Note: the actual host firewall is **UFW** (`ufw.service` enabled), NOT
> `nftables.service` (inactive). Do NOT follow an nftables-based persistence route.

The mangle rule is persisted in `/etc/ufw/before.rules` (loaded by `ufw` at boot and on
`ufw reload`). Append the `*mangle` section after the existing `*filter` block:

```
# TTL fix: ISP link returns reply packets with IP ttl 1, which dies on ip_forward.
*mangle
:PREROUTING ACCEPT [0:0]
-A PREROUTING -i wlp1s0 -m conntrack --ctstate RELATED,ESTABLISHED -j TTL --ttl-set 62
COMMIT
```

Validate and apply:
```
cat /etc/ufw/before.rules | sudo iptables-restore --test   # syntax check
sudo ufw reload
```

After reload two identical PREROUTING rules may coexist (the live iptables rule + the
reloaded one; `ufw reload` uses `--noflush`). They are idempotent — keep either. To
de-duplicate: `sudo iptables -t mangle -D PREROUTING 2`.

## Verification
```
docker exec radarr sh -c 'curl -sS -o /dev/null -w "%{http_code} %{time_total}s" --max-time 8 https://www.google.com'
# expect: 200 < 1s
```

## Troubleshooting notes (do not regress)
- `net.ipv4.ip_forward=1` is required and set.
- The host firewall is UFW (iptables-nft; `ufw` commands) with default `deny routed`;
  Docker's forward traffic is allowed via the `DOCKER-USER`/`DOCKER-FORWARD` chains,
  which permit `ip saddr 172.16.0.0/12` etc. `nftables.service` is inactive.
- Docker's published ports and MASQUERADE NAT are intact and were never the problem.
- rp_filter, ip rules, conntrack, and the DOCKER-USER isolation rules were all ruled
  out during diagnosis.