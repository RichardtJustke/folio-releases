# Folio

Gerenciador de arquivos estilo Finder para Linux/Wayland — leve, minimalista e personalizável.
Este repositório distribui as versões **compiladas** do Folio.

## Instalar (qualquer distro)

```sh
curl -fsSL https://raw.githubusercontent.com/RichardtJustke/folio-releases/main/install.sh | sh
```

Instala em `~/.local/bin/folio` (sem root), cria a entrada no menu de aplicativos e confere o checksum do download.
Requer Linux x86_64 e `curl`.

- Versão específica: `FOLIO_VERSION=0.4 sh install.sh`
- Desinstalar: `sh install.sh --uninstall`

## Dicas

- Conectar a servidores SSH/SFTP pela barra lateral usa o **gvfs** (`gio`).
- Escolher aplicativos padrão usa o **xdg-utils**.
- Se `folio` não for encontrado, adicione `~/.local/bin` ao seu `PATH`.

## Versões

Veja a aba [Releases](../../releases). Status: **alpha**.
