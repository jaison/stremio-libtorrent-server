# Deploy no Coolify

Este fork está preparado para o cenário principal em que o servidor roda no Coolify, com o Compose do repositório como fonte de configuração.

## 1. Criar a aplicação

Em um projeto do Coolify, crie uma nova aplicação a partir do GitHub e selecione:

- repositório: `jaison/stremio-libtorrent-server`
- branch: `main`
- build pack: **Docker Compose**
- base directory: `/`
- compose file: `/compose.yaml`

## 2. Domínio

Associe o domínio público do serviço à porta interna `8080`.

Exemplo:

`https://stremio.exemplo.com` → `8080`

HTTPS fica a cargo do proxy do Coolify. Não é necessário publicar as portas `8080`, `11470` ou `12470` no host.

## 3. Variáveis

O `compose.yaml` já traz os valores padrão usados por esta instalação:

```env
STREMIOSRV_CACHE_SIZE=10GB
STREMIOSRV_LIBRARY_UI=true
STREMIOSRV_SEED_ON_COMPLETE=false
STREMIOSRV_ENABLE_UPNP=false
```

Defina também o endereço público do servidor:

```env
SERVER_URL=https://stremio.exemplo.com
```

Não defina `IPADDRESS` no Coolify. O proxy do Coolify termina o HTTPS externo.

## 4. Armazenamento

O Compose já declara o volume persistente:

```yaml
volumes:
  - stremio-cache:/root/.stremio-server
```

O caminho `/root/.stremio-server` é usado pela aplicação para cache, downloads, certificados e arquivos de estado da Library.

## 5. Portas

Somente `6881/TCP` e `6881/UDP` são publicados diretamente pelo Compose, para inbound BitTorrent.

```text
8080   web player + API   → proxy do Coolify
11470  API interna         → não publicar
12470  HTTPS interno       → não publicar
6881   BitTorrent          → publicar TCP + UDP
```

## 6. Healthcheck

O Compose já possui um healthcheck em `11470/health`. Não é necessário criar um healthcheck adicional no painel.

## 7. Após o deploy

Teste:

```text
https://stremio.exemplo.com/
https://stremio.exemplo.com/library/
```

O Web Player deve reconhecer automaticamente o servidor porque `SERVER_URL` aponta para o domínio público.

## 8. Configuração específica deste fork

Esta configuração assume:

- Coolify como reverse proxy e terminador TLS;
- volume persistente local para cache/downloads;
- Library UI habilitada;
- downloads sem seeding automático ao concluir;
- UPnP/NAT-PMP desabilitado;
- porta 6881 publicada quando inbound BitTorrent for desejado;
- nenhuma credencial ou segredo armazenado no Git.