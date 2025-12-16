#!/usr/bin/env bash
set -euo pipefail

########################################
# CachyOS System Baseline Checker/Fixer
# Boot + NVIDIA + AMD P-State + Btrfs +
# Swappiness + Wayland
########################################

AUTO_MODE=0
[[ "${1:-}" == "--auto" ]] && AUTO_MODE=1

### ========= BASELINE ESPERADO =========

EXPECTED_CMDLINE=(
  "amd_pstate=active"
  "amd_pstate.shared_mem=1"
  "nvidia_drm.modeset=1"
  "nvidia_drm.fbdev=1"
)

EXPECTED_SWAPPINESS=10
EXPECTED_BTRFS_OPTS=("noatime" "compress=zstd" "commit=60")

### ========= UTILITÁRIOS =========

log()  { echo -e "\n[INFO] $*"; }
warn() { echo -e "\n[WARN] $*"; }

ask() {
  [[ "$AUTO_MODE" -eq 1 ]] && return 0
  read -rp "→ Deseja aplicar esta correção? [s/N]: " r
  [[ "$r" =~ ^[sS]$ ]]
}

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Execute como root."
    exit 1
  fi
}

backup_file() {
  local f="$1"
  cp -a "$f" "${f}.bak.$(date +%F_%H-%M-%S)"
}

### ========= SYSTEMD-BOOT =========

get_active_entry() {
  bootctl status | awk -F': ' '/Current Entry/ {print $2}'
}

get_entry_file() {
  echo "/boot/loader/entries/$(get_active_entry)"
}

### ========= CHECKS =========

check_cmdline() {
  log "Kernel cmdline"
  local cmdline missing=()
  cmdline="$(cat /proc/cmdline)"

  for p in "${EXPECTED_CMDLINE[@]}"; do
    grep -qw "$p" <<<"$cmdline" || missing+=("$p")
  done

  [[ "${#missing[@]}" -eq 0 ]] && {
    echo "✓ Cmdline OK"
    return
  }

  warn "Parâmetros ausentes:"
  printf ' - %s\n' "${missing[@]}"

  local entry
  entry="$(get_entry_file)"
  echo "Entry ativa: $entry"

  if ask; then
    backup_file "$entry"
    sed -i "s|^options .*|& ${missing[*]}|" "$entry"
    echo "✓ Cmdline atualizado"
    NEED_REBOOT=1
  fi
}

check_nvidia() {
  log "NVIDIA DRM"
  local m f
  m="$(cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null || echo N)"
  f="$(cat /sys/module/nvidia_drm/parameters/fbdev 2>/dev/null || echo N)"

  if [[ "$m" == "Y" && "$f" == "Y" ]]; then
    echo "✓ NVIDIA DRM ativo"
  else
    warn "NVIDIA DRM não ativo (corrigido via cmdline)"
  fi
}

check_wayland() {
  log "Sessão gráfica"
  if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
    echo "✓ Wayland ativo"
  else
    warn "Sessão não é Wayland"
  fi
}

check_amd_pstate() {
  log "AMD P-State"
  local s
  s="$(cat /sys/devices/system/cpu/amd_pstate/status 2>/dev/null || echo unknown)"

  [[ "$s" == "active" ]] && echo "✓ amd_pstate ativo" || warn "amd_pstate: $s"
}

check_swappiness() {
  log "Swappiness"
  local cur
  cur="$(sysctl -n vm.swappiness)"

  [[ "$cur" -eq "$EXPECTED_SWAPPINESS" ]] && {
    echo "✓ Swappiness OK ($cur)"
    return
  }

  warn "Swappiness atual: $cur (esperado $EXPECTED_SWAPPINESS)"

  if ask; then
    echo "vm.swappiness=$EXPECTED_SWAPPINESS" > /etc/sysctl.d/99-swappiness.conf
    sysctl -p /etc/sysctl.d/99-swappiness.conf >/dev/null
    echo "✓ Swappiness ajustado"
  fi
}

check_btrfs() {
  log "Btrfs mount options"
  local opts missing=()
  opts="$(findmnt -no OPTIONS /)"

  for o in "${EXPECTED_BTRFS_OPTS[@]}"; do
    grep -qw "$o" <<<"$opts" || missing+=("$o")
  done

  [[ "${#missing[@]}" -eq 0 ]] && {
    echo "✓ Btrfs OK"
    return
  }

  warn "Opções Btrfs ausentes:"
  printf ' - %s\n' "${missing[@]}"
  warn "Correção requer edição manual do /etc/fstab (não automática)"
}

### ========= EXECUÇÃO =========

require_root
NEED_REBOOT=0

check_cmdline
check_nvidia
check_wayland
check_amd_pstate
check_swappiness
check_btrfs

if [[ "$NEED_REBOOT" -eq 1 ]]; then
  warn "Reboot necessário para aplicar tudo."
else
  log "Sistema consistente com o baseline."
fi

log "Execução finalizada."
