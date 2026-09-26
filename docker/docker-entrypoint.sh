#!/usr/bin/env bash
set -euo pipefail

: "${TACHIDUBB_AUTH_USER:?Set TACHIDUBB_AUTH_USER in the container environment}"
: "${TACHIDUBB_AUTH_PASSWORD:?Set TACHIDUBB_AUTH_PASSWORD in the container environment}"
if [[ ${#TACHIDUBB_AUTH_PASSWORD} -lt 16 ]]; then
  echo "TACHIDUBB_AUTH_PASSWORD must be at least 16 characters" >&2
  exit 1
fi

APP_ROOT=/opt/tachidubb
DATA_ROOT=/data/tachidubb
mkdir -p "$DATA_ROOT"
for name in uploads outputs jobs_db; do
  mkdir -p "$DATA_ROOT/$name"
  if [[ ! -L "$APP_ROOT/$name" ]]; then
    if [[ -d "$APP_ROOT/$name" ]]; then
      cp -an "$APP_ROOT/$name/." "$DATA_ROOT/$name/"
      mv "$APP_ROOT/$name" "$APP_ROOT/${name}.image"
    fi
    ln -s "$DATA_ROOT/$name" "$APP_ROOT/$name"
  fi
done
for name in tachidubb.db config-user.json; do
  if [[ -e "$APP_ROOT/$name" && ! -L "$APP_ROOT/$name" ]]; then
    mv "$APP_ROOT/$name" "$DATA_ROOT/$name"
    ln -s "$DATA_ROOT/$name" "$APP_ROOT/$name"
  fi
done
mkdir -p "$DATA_ROOT/voice_presets"
if [[ ! -L "$APP_ROOT/presets/voices" ]]; then
  if [[ -d "$APP_ROOT/presets/voices" ]]; then
    cp -an "$APP_ROOT/presets/voices/." "$DATA_ROOT/voice_presets/"
    mv "$APP_ROOT/presets/voices" "$APP_ROOT/presets/voices.image"
  fi
  ln -s "$DATA_ROOT/voice_presets" "$APP_ROOT/presets/voices"
fi

printf '%s' "$TACHIDUBB_AUTH_PASSWORD" | htpasswd -B -C 12 -i -c /etc/nginx/.htpasswd "$TACHIDUBB_AUTH_USER"
chmod 640 /etc/nginx/.htpasswd
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
