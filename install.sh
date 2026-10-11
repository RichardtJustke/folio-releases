#!/bin/sh
# Folio — instalador para Linux x86_64 (qualquer distro, sem root).
#   curl -fsSL https://raw.githubusercontent.com/RichardtJustke/folio-releases/main/install.sh | sh
#
# Variáveis:  FOLIO_VERSION=0.4   instala essa versão em vez da última
#             FOLIO_BIN_DIR=...   onde colocar o executável (padrão ~/.local/bin)
# Desinstalar: sh install.sh --uninstall
set -eu

REPO="RichardtJustke/folio-releases"
ASSET="Folio-x86_64.AppImage"
BIN_DIR="${FOLIO_BIN_DIR:-$HOME/.local/bin}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
APP_DIR="$DATA_DIR/folio"
DESKTOP="$DATA_DIR/applications/folio.desktop"
ICON="$DATA_DIR/icons/hicolor/scalable/apps/folio.svg"

say() { printf '%s\n' "$*"; }
die() { printf 'erro: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "preciso do comando '$1'"; }

if [ "${1:-}" = "--uninstall" ]; then
    rm -f "$BIN_DIR/folio" "$DESKTOP" "$ICON"
    rm -rf "$APP_DIR"
    say "Folio removido. (Suas configurações em ~/.config/folio foram mantidas.)"
    exit 0
fi

[ "$(uname -s)" = "Linux" ] || die "o Folio só roda no Linux"
case "$(uname -m)" in
    x86_64|amd64) ;;
    *) die "por enquanto só há build para x86_64 (sua máquina: $(uname -m))" ;;
esac
need curl
need sha256sum

if [ -n "${FOLIO_VERSION:-}" ]; then
    tag="v${FOLIO_VERSION}-alpha"
else
    # a URL /releases/latest redireciona para /releases/tag/<tag>
    tag="$(curl -fsSIL -o /dev/null -w '%{url_effective}' "https://github.com/$REPO/releases/latest" | sed 's|.*/tag/||')"
    case "$tag" in
        ""|*/*|*" "*) die "não encontrei nenhuma versão publicada em $REPO" ;;
    esac
fi
base="https://github.com/$REPO/releases/download/$tag"
say "Versão: $tag"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT INT TERM

say "Baixando o Folio…"
curl -fL --progress-bar "$base/$ASSET" -o "$tmp/$ASSET" || die "não consegui baixar $base/$ASSET"
curl -fsSL "$base/SHA256SUMS" -o "$tmp/SHA256SUMS" || die "não consegui baixar a lista de checksums"
(cd "$tmp" && grep " $ASSET\$" SHA256SUMS | sha256sum -c - >/dev/null) || die "checksum não confere — download corrompido"
curl -fsSL "$base/folio.svg" -o "$tmp/folio.svg" || die "não consegui baixar o ícone"

mkdir -p "$BIN_DIR" "$(dirname "$DESKTOP")" "$(dirname "$ICON")"
chmod +x "$tmp/$ASSET"

# AppImage precisa de FUSE 2; sem ele, extrai e roda direto do diretório
if ldconfig -p 2>/dev/null | grep -q 'libfuse\.so\.2'; then
    rm -rf "$APP_DIR"
    install -m 755 "$tmp/$ASSET" "$BIN_DIR/folio"
else
    say "FUSE 2 não encontrado — extraindo o aplicativo."
    rm -rf "$APP_DIR"
    mkdir -p "$APP_DIR"
    (cd "$APP_DIR" && "$tmp/$ASSET" --appimage-extract >/dev/null) || die "falha ao extrair o AppImage"
    ln -sf "$APP_DIR/squashfs-root/AppRun" "$BIN_DIR/folio"
fi

install -m 644 "$tmp/folio.svg" "$ICON"
cat > "$DESKTOP" <<DESK
[Desktop Entry]
Type=Application
Name=Folio
GenericName=Gerenciador de arquivos
Comment=Navegue pelos seus arquivos
Exec=$BIN_DIR/folio %u
Icon=folio
Terminal=false
Categories=System;FileTools;FileManager;Utility;Core;Qt;
MimeType=inode/directory;
StartupWMClass=folio
Keywords=arquivos;pastas;files;folders;
DESK

command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DATA_DIR/applications" >/dev/null 2>&1 || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -q -t "$DATA_DIR/icons/hicolor" >/dev/null 2>&1 || true

say ""
say "Folio instalado em $BIN_DIR/folio"
case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) say "Aviso: $BIN_DIR não está no seu PATH. Adicione-o ou abra o Folio pelo menu de aplicativos." ;;
esac
command -v gio >/dev/null 2>&1 || say "Dica: instale o gvfs para conectar a servidores SSH/SFTP pela barra lateral."
command -v xdg-mime >/dev/null 2>&1 || say "Dica: instale o xdg-utils para escolher aplicativos padrão."
say "Pronto. Rode: folio"
