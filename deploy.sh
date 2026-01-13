#!/bin/bash

USER="root"
HOST="168.227.239.59"
REMOTE_PATH="/codexa/clientes/escritorio/site_institucional"

echo "Destino: $USER@$HOST:$REMOTE_PATH"
echo "Digite a senha do SSH quando solicitado."
echo ""

scp -r ./* "$USER@$HOST:$REMOTE_PATH"

if [ $? -eq 0 ]; then
  echo "Deploy concluido."
else
  echo "Erro no deploy."
fi
