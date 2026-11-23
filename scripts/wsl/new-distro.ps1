<#
.SYNOPSIS
  Create (or resume) a dedicated, disposable WSL distribution for this repository, then provision it with Ansible.
.DESCRIPTION
  Method documented by Microsoft: export a container image filesystem and import it into WSL
  (https://learn.microsoft.com/windows/wsl/use-custom-distro).
  Base image: official Debian 13 (trixie), pinned by digest. Everything else is done by
  ansible/playbooks/workstation.yml, so the distribution can be destroyed and rebuilt at will:
    .\scripts\wsl\new-distro.ps1 -Recreate
  Re-running without -Recreate resumes: existing distribution kept, uv/Ansible checked, playbook re-applied.
.EXAMPLE
  .\scripts\wsl\new-distro.ps1                   # create or resume "iac" in D:\WSL\iac, user = Windows user
  .\scripts\wsl\new-distro.ps1 -WithCluster      # also create the k3d cluster + Flux (playbooks/cluster.yml)
#>
[CmdletBinding()]
param(
  [string]$Name = 'iac',
  [string]$InstallDir = "D:\WSL\$Name",
  # renovate: datasource=docker depName=debian
  [string]$Image = 'debian:trixie@sha256:9c6e381421d0f48d1b8133e573f33c185ee16cbf505eda9c4a8a4791b25ea8a6',
  [string]$User = ($env:USERNAME.ToLower() -replace '[^a-z0-9_-]', ''),
  # renovate: datasource=github-releases depName=astral-sh/uv
  [string]$UvVersion = '0.13.9',
  # renovate: datasource=pypi depName=ansible-core
  [string]$AnsibleCoreVersion = '2.22.0',
  [switch]$Recreate,
  [switch]$SkipProvision,
  [switch]$WithCluster
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

# Run a bash script inside the distribution WITHOUT an intermediate shell (wsl -e), from a temp file with LF endings.
function Invoke-InDistro([string]$Script, [switch]$AsRoot) {
  $tmp = Join-Path $env:TEMP ("wsl-{0}.sh" -f [guid]::NewGuid())
  [IO.File]::WriteAllText($tmp, ($Script -replace "`r", ''), (New-Object Text.UTF8Encoding $false))
  try {
    $path = (wsl -d $Name -e wslpath -a ($tmp -replace '\\', '/')).Trim()
    if ($AsRoot) { wsl -d $Name -u root -e bash $path } else { wsl -d $Name -e bash -l $path }
    if ($LASTEXITCODE) { throw "Script failed in '$Name' (exit $LASTEXITCODE)" }
  } finally { Remove-Item $tmp -ErrorAction SilentlyContinue }
}

$exists = [bool]((wsl -l -q) -replace "`0", '' | Where-Object { $_.Trim() -eq $Name })
if ($exists -and $Recreate) { Write-Host "==> Unregistering '$Name'"; wsl --unregister $Name; $exists = $false }

if (-not $exists) {
  docker info --format '{{.ServerVersion}}' *> $null; if ($LASTEXITCODE) { throw 'Docker engine is not running (start Docker Desktop).' }
  Write-Host "==> Exporting $Image"
  $tar = Join-Path $env:TEMP "$Name-rootfs.tar"
  docker pull $Image | Out-Null
  $cid = docker create $Image
  try { docker export $cid -o $tar } finally { docker rm $cid | Out-Null }
  Write-Host "==> Importing into WSL as '$Name' ($InstallDir)"
  New-Item -ItemType Directory -Force $InstallDir | Out-Null
  wsl --import $Name $InstallDir $tar --version 2
  Remove-Item $tar
} else { Write-Host "==> '$Name' exists: resuming" }

Write-Host "==> Base setup (user '$User', systemd, C.UTF-8, passwordless sudo for this dev-only distribution)"
Invoke-InDistro -AsRoot @"
set -eu
export DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8
apt-get update -qq
apt-get install -y -qq sudo ca-certificates curl git python3 >/dev/null
echo 'LANG=C.UTF-8' > /etc/default/locale
id -u $User >/dev/null 2>&1 || useradd -m -s /bin/bash -G sudo $User
echo '$User ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-$User
chmod 0440 /etc/sudoers.d/90-$User
cat > /etc/wsl.conf <<'EOF'
[boot]
systemd=true
[user]
default=$User
[interop]
appendWindowsPath=false
EOF
"@
wsl --terminate $Name

Write-Host "==> uv $UvVersion (official release, checksum verified) + ansible-core $AnsibleCoreVersion"
Invoke-InDistro @'
set -eu
export LANG=C.UTF-8
UV_VERSION="__UV__"
if ! ~/.local/bin/uv --version 2>/dev/null | grep -q " $UV_VERSION"; then
  tmp=$(mktemp -d)
  base="https://github.com/astral-sh/uv/releases/download/$UV_VERSION"
  curl -fsSL -o "$tmp/uv.tar.gz" "$base/uv-x86_64-unknown-linux-gnu.tar.gz"
  expected=$(curl -fsSL "$base/uv-x86_64-unknown-linux-gnu.tar.gz.sha256" | cut -d' ' -f1)
  echo "$expected  $tmp/uv.tar.gz" | sha256sum -c -
  mkdir -p ~/.local/bin
  tar -xzf "$tmp/uv.tar.gz" --strip-components=1 -C ~/.local/bin
  rm -rf "$tmp"
fi
grep -q 'HOME/.local/bin' ~/.bashrc || echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
export PATH=$HOME/.local/bin:$PATH
uv --version
uv tool install --python 3.14 "ansible-core==__ANSIBLE__"
ansible --version | head -1
'@.Replace('__UV__', $UvVersion).Replace('__ANSIBLE__', $AnsibleCoreVersion)

if ($SkipProvision) { Write-Host 'Done (provisioning skipped).'; return }
$wslRepo = (wsl -d $Name -e wslpath -a ($repo -replace '\\', '/')).Trim()
$playbooks = @('playbooks/workstation.yml') + $(if ($WithCluster) { @('playbooks/cluster.yml') } else { @() })
# Git identity for the distribution, read from this machine's git config (never stored in the repository)
$vars = Join-Path $env:TEMP 'iac-distro-vars.json'
[IO.File]::WriteAllText($vars, (@{
      workstation_git_name  = "$(git config --global user.name)"
      workstation_git_email = "$(git config --global user.email)"
    } | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
$wslVars = (wsl -d $Name -e wslpath -a ($vars -replace '\\', '/')).Trim()
foreach ($pb in $playbooks) {
  Write-Host "==> ansible-playbook $pb"
  Invoke-InDistro ("set -eu`nexport PATH=`$HOME/.local/bin:`$PATH`ncd '$wslRepo/ansible'`nANSIBLE_CONFIG=ansible.cfg ansible-playbook $pb -e @'$wslVars'")
}
Remove-Item $vars -ErrorAction SilentlyContinue
