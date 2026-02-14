#!/usr/bin/env bash
set -euo pipefail

QAZI_DIR="/etc/qazi"
TUN_DIR="$QAZI_DIR/tunnels.d"

# ---------------- UI Helpers ----------------
print_header() {
  clear
  cat <<'ART'
                                                                                          
                                                                                          
                                                                                          
                                                                                          
                                                                                          
                                            .                                             
                                       .:..  ..   .                                       
                                    ..=#%*++=-----=+++=-:                                 
                                ....-#@@@@@@@%%%%%%@@@%%#=.                               
                               ....-%@@@@@@@@@@@@@@@@@%%%*=.                              
                           .  ....-#%%%@@@@@@@@@@@@@@@%%#++:                              
                           . ....:*%%%%%%@@@@@@@@@@@@@%#*++:....                          
                             ...:=#%%%%%@@@@@@%@@@@%%%%#*+=-....                          
                            ....-*#%%#++++++*##%**+=-==+++==:....                         
                             ...=*##*---:. ..+%#-   .::..:==-....                         
                             ...=###+**=:::-=#@%=.:----::.:-=...                          
                            ....=###*==--+*+#%@%*=+#+--::-===.....                        
                           :+*=.=%%%%%%%%%%%%@@@*+*%%%#####*=.:=+=:                       
                           --*%-=#%%%%%%@%%%%@@@#++#%%%%%%#++::+:-=                       
                           .*%#*=#%%%@@@@@%#%%@@#***#%%###+--..+**:                       
                            +##*-+*#%@@@@%#*===-. :+*%@%*+=:..-*#-                        
                            .*#*--+*#%@%%%#+-.    :+**%%*=-.  +*=                         
                             :**=.:-+#%##+:        .:-+#+:..  --                          
                              :+-.:.:=+=.  ..::-::.   .=-                                 
                                 ....::.:=**#*==+++==-...                                 
                                     . .=###+.   -+*+=-                                   
                                     ..:+###*===+**#+=:                                   
                                       :-=+===+=--::..                                    
                                   .     ..:.......                                       
                                   -                      -                               
                                  .%+:                   ==                               
                                   +%%*-.              .+=                                
                                    .-*%#+-:.        -++:                                 
                                        :=*#*+-.  :*#*:                                   
                                           .-*#*=##=.                                     
                                               -#=            ....                        
                            .                   -             ...::...                    
                                                             .....:::::...                
                     ...                                    ...........:::::...           
                   ...                                      ..................::..        
                ...                                                 ..................    
              .                                                        .................  
                                                                       .............      
                                                                         ..   ..          
                                                                                          
                                                                                          
ART
  echo
  echo "Qazi - مدیر تانل‌های GOST (h2 / h2+tls)"
  echo "============================================================"
  echo
}

pause() {
  echo
  read -rp "برای ادامه Enter بزنید..."
}

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "❌ این اسکریپت باید با کاربر root اجرا شود."
    echo "مثال: sudo Qazi"
    exit 1
  fi
}

ensure_dirs() {
  mkdir -p "$TUN_DIR"
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

# ---------------- GOST Install/Update ----------------
install_or_update_gost() {
  print_header
  cat <<'TXT'
راهنما:
- این گزینه، GOST را دقیقاً با اسکریپت رسمی پروژه نصب/آپدیت می‌کند:
  bash <(curl -fsSL https://github.com/go-gost/gost/raw/master/install.sh) --install

نکات:
- نیاز به اینترنت دارد.
- اگر قبلاً نصب باشد، معمولاً آپدیت می‌شود.
TXT
  echo
  read -rp "ادامه بدهم؟ (y/n): " yn
  [[ "$yn" =~ ^[Yy]$ ]] || return 0

  bash <(curl -fsSL https://github.com/go-gost/gost/raw/master/install.sh) --install

  echo
  echo "✅ نصب/آپدیت GOST انجام شد."
  echo "نسخه:"
  gost -V || true
  pause
}

# ---------------- Firewall helper ----------------
open_firewall_port() {
  local port="$1"
  if have_cmd ufw; then
    ufw allow "${port}/tcp" >/dev/null 2>&1 || true
  fi
}

# ---------------- Tunnel Service Management ----------------
svc_name() {
  local name="$1"
  echo "qazi-${name}.service"
}

write_service() {
  local name="$1"
  local exec_cmd="$2"

  local unit="/etc/systemd/system/$(svc_name "$name")"

  cat >"$unit" <<EOF
[Unit]
Description=Qazi GOST Tunnel: ${name}
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${exec_cmd}
Restart=always
RestartSec=2
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable "$(svc_name "$name")" >/dev/null 2>&1 || true
}

save_conf() {
  local name="$1"
  shift
  local conf="$TUN_DIR/${name}.conf"
  {
    echo "# Qazi tunnel config"
    echo "# name=${name}"
    for kv in "$@"; do
      echo "$kv"
    done
  } >"$conf"
}

load_conf() {
  local name="$1"
  local conf="$TUN_DIR/${name}.conf"
  [[ -f "$conf" ]] || return 1
  # shellcheck disable=SC1090
  source <(grep -E '^[a-zA-Z0-9_]+=' "$conf" || true)
}

list_tunnels() {
  print_header
  echo "تانل‌های موجود:"
  echo "------------------------------------------------------------"
  if compgen -G "$TUN_DIR/*.conf" >/dev/null; then
    for f in "$TUN_DIR"/*.conf; do
      local n
      n="$(basename "$f" .conf)"
      echo "• $n"
    done
  else
    echo "(هیچ تانلی ساخته نشده)"
  fi
  echo "------------------------------------------------------------"
  pause
}

status_tunnel() {
  print_header
  read -rp "نام تانل: " name
  if [[ ! -f "$TUN_DIR/${name}.conf" ]]; then
    echo "❌ تانل پیدا نشد."
    pause
    return
  fi
  systemctl status "$(svc_name "$name")" --no-pager || true
  pause
}

start_tunnel() {
  print_header
  read -rp "نام تانل: " name
  systemctl restart "$(svc_name "$name")"
  echo "✅ تانل $name اجرا شد."
  pause
}

stop_tunnel() {
  print_header
  read -rp "نام تانل: " name
  systemctl stop "$(svc_name "$name")" || true
  echo "✅ تانل $name متوقف شد."
  pause
}

logs_tunnel() {
  print_header
  read -rp "نام تانل: " name
  echo "راهنما: برای خروج از لاگ، کلید q را بزنید."
  echo
  journalctl -u "$(svc_name "$name")" -e -f
}

delete_tunnel() {
  print_header
  read -rp "نام تانل برای حذف: " name
  if [[ ! -f "$TUN_DIR/${name}.conf" ]]; then
    echo "❌ تانل پیدا نشد."
    pause
    return
  fi
  read -rp "⚠️ مطمئن هستید؟ (y/n): " yn
  [[ "$yn" =~ ^[Yy]$ ]] || return 0

  systemctl stop "$(svc_name "$name")" >/dev/null 2>&1 || true
  systemctl disable "$(svc_name "$name")" >/dev/null 2>&1 || true
  rm -f "/etc/systemd/system/$(svc_name "$name")"
  rm -f "$TUN_DIR/${name}.conf"
  systemctl daemon-reload

  echo "✅ تانل حذف شد."
  pause
}

# ---------------- Tunnel Creator ----------------
create_tunnel() {
  print_header

  if ! have_cmd gost; then
    echo "❌ GOST نصب نیست."
    echo "اول از منوی «نصب/آپدیت GOST» استفاده کن."
    pause
    return
  fi

  cat <<'TXT'
راهنمای ساخت تانل:
- هر تانل یک سرویس systemd جدا می‌شود.
- دو نقش داریم:
  1) Listener (این سرور گوش می‌دهد)  ← معمولاً روی سرور خارج
  2) Connector (این سرور وصل می‌شود) ← معمولاً روی سرور ایران

- دو نوع پروتکل:
  1) بدون TLS :  http2://
  2) با TLS   :  http+h2://   (h2 + TLS با گواهی خودکار GOST)

نکته مهم:
- اگر روی خارج پورت‌هایی مثل 80/8080 دست x-ui باشد، برای گوش دادن GOST یک پورت آزاد مثل 9090 انتخاب کن.
TXT
  echo

  read -rp "نام تانل (مثال: ir_to_out_80): " name
  name="${name// /_}"

  if [[ -f "$TUN_DIR/${name}.conf" ]]; then
    echo "❌ این نام از قبل وجود دارد."
    pause
    return
  fi

  echo
  echo "نقش این سرور:"
  echo "  1) Listener  (گوش‌دهنده)"
  echo "  2) Connector (وصل‌شونده)"
  read -rp "انتخاب (1/2): " role

  echo
  echo "پروتکل:"
  echo "  1) بدون TLS  (http2)"
  echo "  2) با TLS    (http+h2)"
  read -rp "انتخاب (1/2): " proto_sel

  local proto_base=""
  if [[ "$proto_sel" == "1" ]]; then
    proto_base="http2"
  else
    proto_base="http+h2"
  fi

  echo
  read -rp "آیا احراز هویت (user/pass) فعال شود؟ (y/n): " use_auth
  local user="" pass="" auth_prefix="" auth_mid=""
  if [[ "$use_auth" =~ ^[Yy]$ ]]; then
    read -rp "نام کاربری: " user
    read -rsp "رمز عبور: " pass
    echo
  fi

  # Build commands
  local exec_cmd=""
  local listen_port=""
  local inbound_host="127.0.0.1"
  local inbound_port=""
  local remote_ip="" remote_port=""
  local tls_verify="false"

  if [[ "$role" == "1" ]]; then
    # Listener: gost -L <proto>://:LISTEN -F tcp://127.0.0.1:INBOUND
    echo
    echo "تنظیمات Listener (این سرور گوش می‌دهد):"
    read -rp "پورت گوش‌دادن تونل (مثال 9090): " listen_port
    read -rp "پورت inbound مقصد (مثال inboundهای x-ui: 80): " inbound_port
    read -rp "آی‌پی مقصد (پیشفرض 127.0.0.1): " inbound_host_in
    inbound_host="${inbound_host_in:-127.0.0.1}"

    # auth in listener URL: http+h2://user:pass@:9090
    if [[ "$use_auth" =~ ^[Yy]$ ]]; then
      auth_prefix="${proto_base}://${user}:${pass}@:${listen_port}"
    else
      auth_prefix="${proto_base}://:${listen_port}"
    fi

    exec_cmd="/usr/local/bin/gost -L ${auth_prefix} -F tcp://${inbound_host}:${inbound_port}"

    open_firewall_port "$listen_port"

    save_conf "$name" \
      "ROLE=listener" \
      "PROTO=${proto_base}" \
      "LISTEN_PORT=${listen_port}" \
      "INBOUND_HOST=${inbound_host}" \
      "INBOUND_PORT=${inbound_port}" \
      "AUTH=${use_auth}" \
      "USER=${user}" \
      "PASS=${pass}"

    write_service "$name" "$exec_cmd"

    echo
    echo "✅ تانل Listener ساخته شد."
    echo "ℹ️ این سرویس روی این سرور گوش می‌دهد و ترافیک را به ${inbound_host}:${inbound_port} می‌فرستد."
    echo "برای اجرا: systemctl restart $(svc_name "$name")"
    pause
    return

  elif [[ "$role" == "2" ]]; then
    # Connector: gost -L tcp://:LOCAL -F <proto>://REMOTE:PORT[?secure=...]
    echo
    echo "تنظیمات Connector (این سرور وصل می‌شود):"
    read -rp "پورت لوکال برای ارائه سرویس (مثال 80): " listen_port
    read -rp "آی‌پی سرور مقابل (مثال 212.87.198.106): " remote_ip
    read -rp "پورت تونل روی سرور مقابل (مثال 9090): " remote_port

    if [[ "$proto_base" == "http+h2" ]]; then
      echo
      echo "TLS فعال است."
      echo "راهنما:"
      echo "- اگر Secure را فعال کنیم، کلاینت گواهی را بررسی می‌کند."
      echo "- چون دامنه ندارید، معمولاً serverName را روی gost.run می‌گذاریم (حالت رایج با cert خودکار)."
      read -rp "TLS Verify (secure=true) فعال شود؟ (پیشنهادی) (y/n): " tv
      if [[ "$tv" =~ ^[Yy]$ ]]; then
        tls_verify="true"
      fi
    fi

    # auth in client URL: http+h2://user:pass@IP:PORT
    if [[ "$use_auth" =~ ^[Yy]$ ]]; then
      auth_mid="${proto_base}://${user}:${pass}@${remote_ip}:${remote_port}"
    else
      auth_mid="${proto_base}://${remote_ip}:${remote_port}"
    fi

    # add TLS verify params if needed
    if [[ "$proto_base" == "http+h2" && "$tls_verify" == "true" ]]; then
      auth_mid="${auth_mid}?secure=true&serverName=gost.run"
    fi

    exec_cmd="/usr/local/bin/gost -L tcp://:${listen_port} -F ${auth_mid}"

    save_conf "$name" \
      "ROLE=connector" \
      "PROTO=${proto_base}" \
      "LOCAL_PORT=${listen_port}" \
      "REMOTE_IP=${remote_ip}" \
      "REMOTE_PORT=${remote_port}" \
      "TLS_VERIFY=${tls_verify}" \
      "AUTH=${use_auth}" \
      "USER=${user}" \
      "PASS=${pass}"

    write_service "$name" "$exec_cmd"

    echo
    echo "✅ تانل Connector ساخته شد."
    echo "ℹ️ این سرویس روی این سرور به پورت ${listen_port} گوش می‌دهد و ترافیک را به ${remote_ip}:${remote_port} تونل می‌کند."
    echo "برای اجرا: systemctl restart $(svc_name "$name")"
    pause
    return
  else
    echo "❌ انتخاب نقش نامعتبر است."
    pause
    return
  fi
}

# ---------------- Main Menu ----------------
main_menu() {
  while true; do
    print_header
    echo "1) نصب/آپدیت GOST (اسکریپت رسمی)"
    echo "2) ساخت تانل جدید (Listener / Connector)"
    echo "3) لیست تانل‌ها"
    echo "4) اجرای تانل (Restart)"
    echo "5) توقف تانل"
    echo "6) وضعیت تانل"
    echo "7) لاگ تانل (Live)"
    echo "8) حذف تانل"
    echo "0) خروج"
    echo
    read -rp "انتخاب شما: " choice

    case "$choice" in
      1) install_or_update_gost ;;
      2) create_tunnel ;;
      3) list_tunnels ;;
      4) start_tunnel ;;
      5) stop_tunnel ;;
      6) status_tunnel ;;
      7) logs_tunnel ;;
      8) delete_tunnel ;;
      0) exit 0 ;;
      *) echo "گزینه نامعتبر"; pause ;;
    esac
  done
}

# ---------------- Run ----------------
require_root
ensure_dirs
main_menu
