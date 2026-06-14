# Media Server (arr stack)

Stack de mídia com Docker Compose: **Jellyfin, Sonarr, Radarr, Prowlarr, qBittorrent,
Jellyseerr, Bazarr, FlareSolverr e Recyclarr**. Projetado para ser remontado rápido
depois de formatar a máquina.

## Pré-requisitos
- Docker + plugin `docker compose`
- Fedora: `sudo dnf install -y docker-ce docker-compose-plugin && sudo systemctl enable --now docker`
- Adicione seu usuário ao grupo: `sudo usermod -aG docker $USER` (relogar depois)

## Subir do zero (máquina nova)
```bash
git clone <seu-repo> media-server && cd media-server
./restore.sh /caminho/do/backup.tar.gz   # restaura config das apps (opcional, mas é o que evita reconfigurar tudo)
./bootstrap.sh                            # cria pastas, baixa imagens e sobe tudo
```
Sem backup? `./bootstrap.sh` sobe tudo zerado e você configura as apps na mão uma vez.

## Backup / Restore
```bash
./backup.sh                               # gera ./backups/media-server-config-AAAAMMDD-HHMMSS.tar.gz
BACKUP_DIR=/run/media/voce/HD ./backup.sh # ou manda pra um HD externo
./restore.sh                              # restaura o backup mais recente de BACKUP_DIR
```
O backup leva só o **estado das apps** (`config/` + `.env`), sem cache/logs/metadados
regeneráveis. **Não** inclui sua mídia (`data/media`) nem torrents — isso é arquivo grande,
faça backup à parte se quiser.

> Dica: o `bootstrap.sh` já instala um **systemd timer** que roda o backup aos **sábados 14h**
> com upload pro Google Drive (`RCLONE_REMOTE=gdrive:media-server-backups`). Tem `Persistent=true`,
> então se o PC estiver desligado no horário, o backup roda assim que você ligar/logar.

### Agendamento (systemd timer)
Instalado automaticamente pelo `bootstrap.sh` a partir de `systemd/`. Comandos:
```bash
systemctl --user list-timers media-server-backup.timer   # próxima execução
systemctl --user start media-server-backup.service       # rodar agora
journalctl --user -u media-server-backup.service          # logs
```

### Google Drive (rclone) — passo manual após formatar
O backup sobe pro Drive via `rclone`, mas a credencial do Google **não** vai pro repo nem pro
backup. Numa máquina nova, configure uma vez:
```bash
sudo dnf install -y rclone
rclone config        # crie um remote chamado 'gdrive' (tipo: drive / Google Drive)
```

## Acessos (portas padrão, veja `.env`)
| Serviço      | URL                     |
|--------------|-------------------------|
| Jellyfin     | http://localhost:8096   |
| Sonarr       | http://localhost:8989   |
| Radarr       | http://localhost:7878   |
| Prowlarr     | http://localhost:9696   |
| qBittorrent  | http://localhost:8080   |
| Jellyseerr   | http://localhost:5055   |
| Bazarr       | http://localhost:6767   |
| FlareSolverr | http://localhost:8191   |
| Homepage     | http://localhost:3000   |
| Cleanuparr   | http://localhost:11011  |

> **VueTorrent**: o qBittorrent usa a WebUI alternativa VueTorrent (instalada via `DOCKER_MODS`
> e já ativada em `qBittorrent.conf`). Em uma máquina nova, depois de restaurar o backup já vem ligada.
>
> **Cleanuparr**: na primeira vez, abra `:11011` e conecte Sonarr/Radarr/qBittorrent (URL interna
> `http://sonarr:8989` etc. + API key) para ativar a limpeza automática de downloads travados.

## Estrutura de dados
```
data/
├── media/{movie,anime}   # biblioteca (Jellyfin lê daqui)
└── torrents/{complete,incomplete}
```
Sonarr/Radarr/qBittorrent compartilham o mesmo root `/data` dentro dos containers,
o que permite **hardlink + atomic move** (não duplica arquivo ao importar).

## O que NÃO vai pro git
`config/`, `data/`, `.env` e `backups/` (ver `.gitignore`). Segredos (API keys, senhas)
ficam só no backup, nunca no repositório.
