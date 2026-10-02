#!/usr/bin/env bash
# Envia arquivos para a pasta do Google Drive definida em GDRIVE_FOLDER_ID.
# Uso: gdrive-upload.sh <arquivo> [<arquivo> ...]
# Requer: GDRIVE_CLIENT_ID, GDRIVE_CLIENT_SECRET, GDRIVE_REFRESH_TOKEN, GDRIVE_FOLDER_ID
set -euo pipefail

: "${GDRIVE_CLIENT_ID:?GDRIVE_CLIENT_ID não definido}"
: "${GDRIVE_CLIENT_SECRET:?GDRIVE_CLIENT_SECRET não definido}"
: "${GDRIVE_REFRESH_TOKEN:?GDRIVE_REFRESH_TOKEN não definido}"
: "${GDRIVE_FOLDER_ID:?GDRIVE_FOLDER_ID não definido}"

if [ "$#" -eq 0 ]; then
  echo "Uso: gdrive-upload.sh <arquivo> [<arquivo> ...]" >&2
  exit 1
fi

TOKEN=$(curl -sSf -X POST https://oauth2.googleapis.com/token \
  --data-urlencode "client_id=${GDRIVE_CLIENT_ID}" \
  --data-urlencode "client_secret=${GDRIVE_CLIENT_SECRET}" \
  --data-urlencode "refresh_token=${GDRIVE_REFRESH_TOKEN}" \
  --data-urlencode "grant_type=refresh_token" \
  | jq -er '.access_token')

enviar() {
  local arquivo="$1"
  local nome file_id

  if [ ! -f "$arquivo" ]; then
    echo "Arquivo não encontrado: $arquivo" >&2
    exit 1
  fi

  nome=$(basename "$arquivo")
  file_id=$(curl -sSf -X POST "https://www.googleapis.com/drive/v3/files" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg nome "$nome" --arg pasta "$GDRIVE_FOLDER_ID" \
      '{name: $nome, parents: [$pasta]}')" \
    | jq -er '.id')

  curl -sSf -X PATCH "https://www.googleapis.com/upload/drive/v3/files/${file_id}?uploadType=media" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/octet-stream" \
    --data-binary @"${arquivo}" > /dev/null

  echo "Enviado: ${nome} (id=${file_id})"
}

for arquivo in "$@"; do
  enviar "$arquivo"
done
