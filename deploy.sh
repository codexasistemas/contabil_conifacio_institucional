#!/bin/bash

USER="root"
HOST="168.227.239.59"
REMOTE_PATH="/codexa/clientes/escritorio/site_institucional"
SOCK="/tmp/ssh-$HOST.sock"

echo "Destino: $USER@$HOST:$REMOTE_PATH"
echo ""

# abre conexão master
ssh -M -S "$SOCK" -fnN "$USER@$HOST" || exit 1

# verifica se a pasta existe
ssh -S "$SOCK" "$USER@$HOST" "[ -d '$REMOTE_PATH' ]"
EXISTS=$?

if [ $EXISTS -ne 0 ]; then
  echo "Pasta remota NÃO existe:"
  echo "$REMOTE_PATH"
  read -p "Criar essa pasta? (s/n): " RESP

  if [[ "$RESP" != "s" ]]; then
    echo "Deploy cancelado."
    ssh -S "$SOCK" -O exit "$USER@$HOST"
    exit 1
  fi

  ssh -S "$SOCK" "$USER@$HOST" "mkdir -p '$REMOTE_PATH'"
fi

echo ""
echo "Enviando arquivos..."
scp -o ControlPath="$SOCK" -r ./* "$USER@$HOST:$REMOTE_PATH"

echo ""
echo "Verificando containers usando o volume..."

CONTAINER_USING_VOLUME=$(ssh -S "$SOCK" "$USER@$HOST" "
docker ps -a --format '{{.ID}} {{.Names}} {{.Mounts}}' | grep '$REMOTE_PATH'
")

if [ -n \"$CONTAINER_USING_VOLUME\" ]; then
  echo "Já existe container usando esse mount:"
  echo "$CONTAINER_USING_VOLUME"
  echo "Docker run NÃO será executado."
else
  read -p "Nenhum container encontrado. Nome do novo container: " CONTAINER_NAME

  if [ -z \"$CONTAINER_NAME\" ]; then
    echo "Nome inválido. Cancelando."
    ssh -S "$SOCK" -O exit "$USER@$HOST"
    exit 1
  fi

  echo "Subindo container $CONTAINER_NAME..."

  ssh -S "$SOCK" "$USER@$HOST" "
  docker run -d \
    --name $CONTAINER_NAME \
    --network proxy_network \
    -v $REMOTE_PATH:/usr/share/nginx/html:ro \
    --user root \
    nginx:alpine
  "
fi

# fecha conexão master
ssh -S "$SOCK" -O exit "$USER@$HOST"

echo "Deploy finalizado."
