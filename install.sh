#!/bin/sh
# Folio — instalador para Linux x86_64 (qualquer distro, sem root).
#   curl -fsSL https://raw.githubusercontent.com/RichardtJustke/folio-releases/main/install.sh | sh
#
# Opções (use  ... | sh -s -- <opção>):
#   --uninstall         remove o Folio (mantém ~/.config/folio)
#   --help              mostra esta ajuda
# Variáveis:
#   FOLIO_VERSION=0.5   instala essa versão em vez da última
#   FOLIO_BIN_DIR=...   onde colocar o executável (padrão ~/.local/bin)
#   NO_COLOR=1          sem cores
set -eu

REPO="RichardtJustke/folio-releases"
ASSET="Folio-x86_64.AppImage"
BIN_DIR="${FOLIO_BIN_DIR:-$HOME/.local/bin}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
APP_DIR="$DATA_DIR/folio"
DESKTOP="$DATA_DIR/applications/folio.desktop"
ICON="$DATA_DIR/icons/hicolor/scalable/apps/folio.svg"
VERSION_FILE="$APP_DIR/VERSION"

# --- saída bonita (cores e símbolos só quando o terminal suporta) -----------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-dumb}" != "dumb" ]; then
    B="$(printf '\033[1m')"; D="$(printf '\033[2m')"; R="$(printf '\033[0m')"
    BLUE="$(printf '\033[38;5;75m')"; GREEN="$(printf '\033[32m')"
    RED="$(printf '\033[31m')"; YEL="$(printf '\033[33m')"
else
    B=""; D=""; R=""; BLUE=""; GREEN=""; RED=""; YEL=""
fi
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
    *UTF-8*|*utf8*|*UTF8*) OK="✓"; ARROW="→"; BUL="•"; LOGO="▟█▙" ;;
    *)                     OK="+"; ARROW="->"; BUL="*"; LOGO="[F]" ;;
esac

ok()   { printf '  %s%s%s %s\n' "$GREEN" "$OK" "$R" "$*"; }
info() { printf '  %s%s%s %s\n' "$D" "$BUL" "$R" "$*"; }
warn() { printf '  %s!%s %s\n' "$YEL" "$R" "$*"; }
die()  { printf '\n  %s✗ erro:%s %s\n\n' "$RED" "$R" "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "preciso do comando '$1' (instale-o e rode de novo)"; }
tilde() { printf '%s' "$1" | sed "s|^$HOME|~|"; }
human() { # bytes -> "12.3 MB"
    awk -v b="$1" 'BEGIN{ if (b>=1048576) printf "%.1f MB", b/1048576; else printf "%.0f KB", b/1024 }'
}

header() {
    printf '\n  %s%s%s  %sFolio%s %s— gerenciador de arquivos para Linux/Wayland%s\n\n' \
        "$BLUE" "$LOGO" "$R" "$B" "$R" "$D" "$R"
}

# --- ajuda / desinstalar -------------------------------------------------
case "${1:-}" in
    -h|--help)
        cat <<HELP
Folio — instalador (Linux x86_64, sem root)

  curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | sh
  curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | sh -s -- --uninstall

Opções:    --uninstall  remove o Folio (mantém ~/.config/folio)
           --help       mostra esta ajuda
Variáveis: FOLIO_VERSION=0.5  instala essa versão
           FOLIO_BIN_DIR=...  onde colocar o executável (padrão ~/.local/bin)
           NO_COLOR=1         sem cores
HELP
        exit 0 ;;
    --uninstall)
        header
        rm -f "$BIN_DIR/folio" "$DESKTOP" "$ICON"
        rm -rf "$APP_DIR"
        command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DATA_DIR/applications" >/dev/null 2>&1 || true
        ok "Folio removido."
        info "Suas configurações em ~/.config/folio foram mantidas."
        printf '\n'
        exit 0 ;;
    "") ;;
    *) die "opção desconhecida: $1 (use --help)" ;;
esac

header

# --- 1. sistema ----------------------------------------------------------
[ "$(uname -s)" = "Linux" ] || die "o Folio só roda no Linux"
case "$(uname -m)" in
    x86_64|amd64) ;;
    *) die "por enquanto só há build para x86_64 (sua máquina: $(uname -m))" ;;
esac
need curl
need sha256sum
ok "Linux x86_64"

# --- 2. versão -----------------------------------------------------------
if [ -n "${FOLIO_VERSION:-}" ]; then
    tag="v${FOLIO_VERSION#v}"
    case "$tag" in *-alpha) ;; *) tag="${tag}-alpha" ;; esac
else
    # a URL /releases/latest redireciona para /releases/tag/<tag>
    tag="$(curl -fsSIL -o /dev/null -w '%{url_effective}' "https://github.com/$REPO/releases/latest" | sed 's|.*/tag/||')"
    case "$tag" in
        ""|*/*|*" "*) die "não encontrei nenhuma versão publicada em $REPO" ;;
    esac
fi
base="https://github.com/$REPO/releases/download/$tag"
new="${tag#v}"
old=""
[ -f "$VERSION_FILE" ] && old="$(cat "$VERSION_FILE" 2>/dev/null || true)"
if [ -z "$old" ]; then
    ok "Instalando Folio ${B}${new}${R}"
elif [ "$old" = "$new" ]; then
    ok "Reinstalando Folio ${B}${new}${R}"
else
    ok "Atualizando Folio ${D}${old}${R} ${ARROW} ${B}${new}${R}"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT INT TERM

# --- 3. download + checksum ----------------------------------------------
printf '  %s%s%s Baixando…\n' "$D" "$BUL" "$R"
if [ -t 1 ]; then
    curl -fL -# "$base/$ASSET" -o "$tmp/$ASSET" || die "não consegui baixar $base/$ASSET (a versão $new existe?)"
    printf '\033[1A\033[2K\033[1A\033[2K'   # apaga a barra de progresso e a linha "Baixando…"
else
    curl -fsSL "$base/$ASSET" -o "$tmp/$ASSET" || die "não consegui baixar $base/$ASSET (a versão $new existe?)"
fi
size="$(wc -c < "$tmp/$ASSET" | tr -d ' ')"
ok "Baixado ($(human "$size"))"

curl -fsSL "$base/SHA256SUMS" -o "$tmp/SHA256SUMS" || die "não consegui baixar a lista de checksums"
(cd "$tmp" && grep " $ASSET\$" SHA256SUMS | sha256sum -c - >/dev/null 2>&1) || die "checksum não confere — download corrompido, tente de novo"
ok "Checksum SHA-256 conferido"
curl -fsSL "$base/folio.svg" -o "$tmp/folio.svg" || die "não consegui baixar o ícone"

# --- 4. instalação -------------------------------------------------------
mkdir -p "$BIN_DIR" "$(dirname "$DESKTOP")" "$(dirname "$ICON")"
chmod +x "$tmp/$ASSET"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"

# AppImage precisa de FUSE 2; sem ele, extrai e roda direto do diretório
if ldconfig -p 2>/dev/null | grep -q 'libfuse\.so\.2'; then
    install -m 755 "$tmp/$ASSET" "$BIN_DIR/folio"
    ok "Executável em $(tilde "$BIN_DIR/folio")"
else
    info "FUSE 2 não encontrado — extraindo o aplicativo"
    (cd "$APP_DIR" && "$tmp/$ASSET" --appimage-extract >/dev/null) || die "falha ao extrair o AppImage"
    ln -sf "$APP_DIR/squashfs-root/AppRun" "$BIN_DIR/folio"
    ok "Executável em $(tilde "$BIN_DIR/folio") ${D}(extraído)${R}"
fi
printf '%s\n' "$new" > "$VERSION_FILE"

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
ok "Entrada no menu de aplicativos e ícone"

# --- 5. avisos e resumo --------------------------------------------------
printf '\n'
case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) warn "$(tilde "$BIN_DIR") não está no seu PATH — adicione-o, ou abra o Folio pelo menu de aplicativos." ;;
esac
command -v gio >/dev/null 2>&1 || info "Dica: instale o gvfs para conectar a servidores SSH/SFTP pela barra lateral."
command -v xdg-mime >/dev/null 2>&1 || info "Dica: instale o xdg-utils para escolher aplicativos padrão."

printf '\n  %sPronto!%s Rode %sfolio%s ou procure "Folio" no menu.\n' "$B" "$R" "$BLUE" "$R"
printf '  %sAtualizar:%s rode este mesmo comando de novo.   %sRemover:%s ... | sh -s -- --uninstall\n\n' "$D" "$R" "$D" "$R"
