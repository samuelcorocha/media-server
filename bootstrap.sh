#!/usr/bin/env bash
# Sobe o media-server do zero numa máquina recém-formatada.
# Uso:  ./bootstrap.sh
set -euo pipefail
cd "$(dirname "$0")"

echo "==> Verificando Docker..."
if ! command -v docker >/dev/null 2>&1; then
  echo "ERRO: Docker não encontrado. Instale com: sudo dnf install -y docker-ce docker-compose-plugin" >&2
  exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "ERRO: plugin 'docker compose' não encontrado." >&2
  exit 1
fi

# .env
if [[ ! -f .env ]]; then
  echo "==> .env não existe; criando a partir de .env.example"
  cp .env.example .env
  echo "    >> Ajuste PUID/PGID/portas em .env se necessário e rode de novo."
fi

# Carrega caminhos do .env
set -a; source .env; set +a
ROOT_PATH="${ROOT_PATH:-./data}"
CONFIG_PATH="${CONFIG_PATH:-./config}"

echo "==> Criando estrutura de pastas..."
mkdir -p \
  "${CONFIG_PATH}"/{jellyfin,sonarr,radarr,prowlarr,qbittorrent,jellyseerr,flaresolverr,recyclarr,bazarr} \
  "${ROOT_PATH}"/media/{movie,anime} \
  "${ROOT_PATH}"/torrents/{complete,incomplete}

echo "==> Baixando imagens e subindo containers..."
docker compose pull
docker compose up -d

# Instala o timer systemd de backup (sábados 14h, com catch-up), se os units existirem.
if [[ -d systemd ]] && command -v systemctl >/dev/null 2>&1; then
  echo "==> Instalando timer de backup (systemd --user)..."
  REPO_DIR="$(pwd)"
  UNIT_DIR="${HOME}/.config/systemd/user"
  mkdir -p "$UNIT_DIR"
  sed "s#__MEDIA_SERVER_DIR__#${REPO_DIR}#g" systemd/media-server-backup.service > "${UNIT_DIR}/media-server-backup.service"
  cp systemd/media-server-backup.timer "${UNIT_DIR}/media-server-backup.timer"
  systemctl --user daemon-reload
  systemctl --user enable --now media-server-backup.timer
  echo "    >> Backup agendado. NÃO esquece de configurar o rclone: rclone config (remote 'gdrive')."
fi

echo ""
echo "==> Pronto! Containers no ar. Se este é um host novo SEM config restaurado,"
echo "    rode ./restore.sh ANTES de configurar as apps na mão."
docker compose ps
