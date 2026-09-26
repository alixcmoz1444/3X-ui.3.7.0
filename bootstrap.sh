#!/bin/sh
# JinX v2 | Super JinX Railway Edition - 3x-ui v2.9.4
# Heavy, robust bootstrap with working VLESS/WS/TLS inbound + subscription

set -e

REMARK='جینکس | 𝙎𝙪𝙥𝙚𝙧 𝗝𝗶𝗻𝗫'
UUID="${JINX_UUID:-df70a084-8d46-50bd-dec8-3a0f41903f3a}"
PANEL_USER="${PANEL_USERNAME:-admin}"
PANEL_PASS="${PANEL_PASSWORD:-admin}"
DOMAIN="${RAILWAY_PUBLIC_DOMAIN:-}"
PANEL_PORT=2053
XRAY_PORT=10000
NGINX_PORT=8080

log() {
  echo "[JinX $(date '+%H:%M:%S')] $*"
}

# Wait for panel startup
wait_panel() {
  local i=0
  while [ $i -lt 180 ]; do
    if curl -s "http://127.0.0.1:$PANEL_PORT/" >/dev/null 2>&1; then
      return 0
    fi
    i=$((i+1))
    sleep 1
  done
  return 1
}

# Main panel setup
cd /app || exit 1
./x-ui setting -username "$PANEL_USER" -password "$PANEL_PASS" -port "$PANEL_PORT" -webBasePath "/" >/dev/null 2>&1 || true

# Supervised startup
(while true; do
  cd /app && ./x-ui
  log "Panel crashed, restarting..."
  sleep 3
done) &

# Start nginx
mkdir -p /var/run/nginx /tmp/jinx/sub
nginx -g 'daemon off;' &
log "nginx started on :$NGINX_PORT"

# Wait for panel
if ! wait_panel; then
  log "FATAL: panel did not start"
  exit 1
fi

log "Panel online. Configuring inbound..."

# Login + create inbound (full VLESS/WS/TLS config)
api_login() {
  COOKIE_JAR="/tmp/jinx_cookie"
  curl -s -c "$COOKIE_JAR" -X POST "http://127.0.0.1:$PANEL_PORT/login" \
    --data-urlencode "username=$PANEL_USER" \
    --data-urlencode "password=$PANEL_PASS" >/dev/null 2>&1
}

api_call() {
  curl -s -b "$COOKIE_JAR" -X POST "http://127.0.0.1:$PANEL_PORT$1" \
    "${@:2}" 2>/dev/null
}

api_login

# Create VLESS/WS/TLS inbound
api_call "/panel/api/inbounds/add" \
  --data-urlencode "remark=$REMARK" \
  --data-urlencode "protocol=vless" \
  --data-urlencode "port=$XRAY_PORT" \
  --data-urlencode "listen=127.0.0.1" \
  --data-urlencode "enable=true" \
  --data-urlencode "expiryTime=0" \
  --data-urlencode "up=0" \
  --data-urlencode "down=0" \
  --data-urlencode "total=0" \
  --data-urlencode "settings={\"clients\":[{\"id\":\"$UUID\",\"flow\":\"\",\"email\":\"SuperJinX\",\"limitIp\":0,\"totalGB\":0,\"expiryTime\":0,\"enable\":true,\"subId\":\"jinx\"}],\"decryption\":\"none\",\"fallbacks\":[]}" \
  --data-urlencode "streamSettings={\"network\":\"ws\",\"security\":\"tls\",\"wsSettings\":{\"path\":\"/ws/$UUID\",\"host\":\"$DOMAIN\"},\"tlsSettings\":{\"serverName\":\"$DOMAIN\",\"minVersion\":\"1.2\",\"maxVersion\":\"1.3\",\"alpn\":[\"http/1.1\"],\"settings\":{\"fingerprint\":\"chrome\"}}}" \
  --data-urlencode "sniffing={\"enabled\":true,\"destOverride\":[\"http\",\"tls\",\"quic\",\"fakedns\"]}" \
  --data-urlencode "allocate={\"strategy\":\"always\",\"refresh\":5,\"concurrency\":3}" >/dev/null 2>&1

log "Inbound created"

# Generate subscription
SUB_LINK="vless://$UUID@$DOMAIN:443?path=%2Fws%2F$UUID&security=tls&alpn=http%2F1.1&encryption=none&insecure=0&host=$DOMAIN&fp=chrome&type=ws&sni=$DOMAIN#$REMARK"
echo "$SUB_LINK" | base64 -w 0 > /tmp/jinx/sub/jinx
log "Subscription: https://$DOMAIN/sub/jinx"
log "Config: $SUB_LINK"

# Nginx config
cat > /etc/nginx/nginx.conf <<'NGX'
worker_processes auto;
pid /var/run/nginx/nginx.pid;
error_log /dev/stderr warn;
events { worker_connections 4096; }
http {
  access_log off;
  server_tokens off;
  sendfile on;
  map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
  }
  server {
    listen 8080;
    location = /sub/jinx {
      root /tmp/jinx/sub;
      default_type text/plain;
      add_header profile-title "base64:5pSo5a+86Kej5bGAPwlTdXBlciBKaW7Xk4uyC==" always;
      add_header Cache-Control "no-store" always;
    }
    location /ws/ {
      proxy_pass http://127.0.0.1:10000;
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection $connection_upgrade;
      proxy_set_header Host $host;
      proxy_buffering off;
    }
    location / {
      proxy_pass http://127.0.0.1:2053;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $host;
    }
  }
}
NGX

nginx -s reload 2>/dev/null || true
log "nginx reconfigured"

echo "OK" > /tmp/jinx_ready
log "========= JinX READY =========="
log "Panel: https://$DOMAIN/ (admin)"
log "Sub: https://$DOMAIN/sub/jinx "
log "==========================="

wait
