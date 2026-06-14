#!/usr/bin/env bash
# Restaura config/ + .env a partir de um backup gerado por ./backup.sh.
# Uso:   ./restore.sh                      # usa o backup mais recente em $BACKUP_DIR
#        ./restore.sh caminho/arquivo.tar.gz
set -euo pipefail
cd "$(dirname "$0")"

BACKUP_DIR="${BACKUP_DIR:-./backups}"

if [[ $# -ge 1 ]]; then
  ARCHIVE="$1"
else
  ARCHIVE="$(ls -1t "${BACKUP_DIR%/}"/media-server-config-*.tar.gz 2>/dev/null | head -1 || true)"
fi

if [[ -z "${ARCHIVE:-}" || ! -f "$ARCHIVE" ]]; then
  echo "ERRO: nenhum backup encontrado. Passe o caminho: ./restore.sh arquivo.tar.gz" >&2
  exit 1
fi

echo "==> Restaurando de: $ARCHIVE"
read -r -p "Isso vai sobrescrever config/ e .env. Continuar? [s/N] " ans
[[ "${ans,,}" == "s" ]] || { echo "Abortado."; exit 0; }

echo "==> Parando containers (se houver)..."
docker compose down 2>/dev/null || true

tar -xzf "$ARCHIVE" -C .
echo "==> Restaurado. Agora rode: ./bootstrap.sh  (ou: docker compose up -d)"
