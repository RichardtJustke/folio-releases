# Folio

Gerenciador de arquivos estilo Finder para Linux/Wayland — leve, minimalista e personalizável.
Este repositório distribui as versões **compiladas** do Folio.

## Instalar (qualquer distro)

```sh
curl -fsSL https://raw.githubusercontent.com/RichardtJustke/folio-releases/main/install.sh | sh
```

Instala em `~/.local/bin/folio` (sem root), cria a entrada no menu de aplicativos e confere o checksum do download.
Requer Linux x86_64 e `curl`.

- Atualizar: rode o mesmo comando de novo (ele mostra `0.4 → 0.5`).
- Versão específica: `curl -fsSL .../install.sh | FOLIO_VERSION=0.4 sh`
- Desinstalar: `curl -fsSL .../install.sh | sh -s -- --uninstall`

## Dicas

- Conectar a servidores SSH/SFTP pela barra lateral usa o **gvfs** (`gio`).
- Escolher aplicativos padrão usa o **xdg-utils**.
- Se `folio` não for encontrado, adicione `~/.local/bin` ao seu `PATH`.

## Versões

Veja a aba [Releases](../../releases). Status: **alpha**.
