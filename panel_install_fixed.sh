#!/bin/bash

###########################################################
set_and_export() {
    local var_name=$1
    local prompt_message=$2
    local value
    read -p "$prompt_message" value
    export "$var_name=$value"
}

ensure_env_var() {
    local key="$1"
    local value="$2"
    local file="$3"
    # If exact key=value already exists, skip
    grep -Fxq "$key=$value" "$file" && return
    # If key exists (with any value), comment it out and add new value after
    if grep -q "^$key=" "$file"; then
        sed -i "/^$key=/s/^/# /;/^# $key=/a $key=$value" "$file"
    else
        # Key doesn't exist at all — just append
        echo "$key=$value" >> "$file"
    fi
}

# FIX: skip if swapfile already exists
if [ ! -f /swapfile ]; then
    fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
    echo "✓ Swap created"
else
    echo "✓ Swap already exists, skipping"
fi

apt update -y && apt upgrade -y && apt install cron socat git -y

# FIX: Install Node.js via apt so npm is available system-wide (not nvm)
if ! command -v npm &>/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
    echo "✓ Node.js installed: $(node -v)"
else
    echo "✓ Node.js already installed: $(node -v)"
fi

# FIX: Install acme.sh only if not present, always add to PATH
if [ ! -f ~/.acme.sh/acme.sh ]; then
    set_and_export "ACME_EMAIL" "Enter your email for acme.sh (used for Let's Encrypt notifications): "
    curl https://get.acme.sh | sh -s "email=$ACME_EMAIL"
else
    echo "✓ acme.sh already installed, skipping"
fi
export PATH="$HOME/.acme.sh:$PATH"

# Install Docker if not installed
if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com | sh
    echo "✓ Docker installed"
else
    echo "✓ Docker already installed"
fi

# Remnawave panel related exports.
export remnawave_base_dir="/opt/remnawave"
export remnawave_env_path="$remnawave_base_dir/.env"
export remnawave_docker_compose_path="$remnawave_base_dir/docker-compose.yml"
export remnawave_subscription_panel_folder="$remnawave_base_dir/subscription"
export remnawave_subscription_panel_docker_compose="$remnawave_subscription_panel_folder/docker-compose.yml"
export remnawave_subscription_panel_env="$remnawave_subscription_panel_folder/.env"

export basic_nginx_folder="/opt/nginx"
export basic_nginx_conf="$basic_nginx_folder/nginx.conf"
export basic_nginx_resolver_conf="$basic_nginx_folder/resolver.conf"
export nginx_docker_compose="$basic_nginx_folder/docker-compose.yml"

export template_files_folder="/opt/templates"
export template_files_folder_remnawave="$template_files_folder/remnawave"
export template_files_folder_subscription="$template_files_folder_remnawave/subscription"
export template_files_folder_nginx="$template_files_folder/nginx"
export template_files_nginx_conf="$template_files_folder_nginx/nginx.conf"
export template_files_nginx_resolver_conf="$template_files_folder_nginx/resolver.conf"
export template_files_nginx_docker_compose="$template_files_folder_nginx/docker-compose.yml"
export template_files_subscription_compose="$template_files_folder_subscription/docker-compose.yml"
export template_files_subscription_env="$template_files_folder_subscription/.env"
export template_files_folder_tgb="$template_files_folder/tgb"
export template_files_bot_nginx_folder="$template_files_folder_tgb/nginx"
export template_files_bot_telegram_bot_folder="$template_files_folder_tgb/bot"
export template_files_bot_telegram_bot_env="$template_files_bot_telegram_bot_folder/.env"
export template_files_bot_telegram_bot_app_config_json="$template_files_bot_telegram_bot_folder/app-config.json"
export template_files_bot_telegram_bot_docker_compose="$template_files_bot_telegram_bot_folder/docker-compose.yml"
export template_files_bot_telegram_bot_vpn_logo="$template_files_bot_telegram_bot_folder/vpn_logo.png"
export template_files_bot_webapp_folder="$template_files_folder_tgb/bot_webapp"
export template_files_bot_webapp_env="$template_files_folder_tgb/bot_webapp/.env"
export template_files_bot_nginx_conf="$template_files_bot_nginx_folder/nginx.conf"

export tgb_base_folder="/opt/tgb"
export tgb_nginx_folder="$tgb_base_folder/nginx"
export tgb_nginx_conf="$tgb_nginx_folder/nginx.conf"
export tgb_base_bot_folder="$tgb_base_folder/bot"
export tgb_base_bot_env="$tgb_base_bot_folder/.env"
export tgb_base_bot_app_config_json="$tgb_base_bot_folder/app-config.json"
export tgb_base_bot_docker_compose="$tgb_base_bot_folder/docker-compose.yml"
export tgb_base_bot_vpn_logo="$tgb_base_bot_folder/vpn_logo.png"
export tgb_base_bot_webapp_folder="$tgb_base_folder/bot_webapp"
export tgb_base_bot_webapp_env="$tgb_base_bot_webapp_folder/.env"
export tgb_webapp_temp_folder="/opt/webapp"
export tgb_base_repo_dir=$tgb_webapp_temp_folder

export MAIN_REPO_NAME="remnawave-bedolaga-telegram-bot"
export CABINET_REPO_NAME="bedolaga-cabinet"
export BASE_REPO_URL="https://github.com/BEDOLAGA-DEV"
export MAIN_BOT_REPO_PATH="$tgb_base_repo_dir/$MAIN_REPO_NAME"
export CABINET_REPO_PATH="$tgb_base_repo_dir/$CABINET_REPO_NAME"

# Download templates from the latest release if not already present or empty
mkdir -p "$template_files_folder_subscription" "$template_files_bot_telegram_bot_folder" "$template_files_bot_webapp_folder"
if [ ! -s "$template_files_bot_telegram_bot_env" ]; then
    echo "Downloading templates from latest release..."
    RELEASE_URL=$(curl -s https://api.github.com/repos/j5j5-afk/remnawave_bot_basic_config/releases/latest | grep "tarball_url" | cut -d '"' -f 4)
    cd /opt && curl -L "$RELEASE_URL" -o remnawave_bot_basic_config.tar.gz
    tar -xzf remnawave_bot_basic_config.tar.gz --wildcards "*templates*" --strip-components=1
    rm -f remnawave_bot_basic_config.tar.gz
    echo "✓ Templates downloaded"
else
    echo "✓ Templates already exist, skipping download"
fi
# Fallback: only touch if still missing after download
[ ! -f "$template_files_subscription_env" ] && touch "$template_files_subscription_env"
[ ! -f "$template_files_bot_telegram_bot_env" ] && touch "$template_files_bot_telegram_bot_env"
[ ! -f "$template_files_bot_webapp_env" ] && touch "$template_files_bot_webapp_env"

# FIX: Skip remnawave panel setup if already configured
if [ ! -f "$remnawave_env_path" ]; then
    mkdir -p $remnawave_base_dir
    curl -o $remnawave_docker_compose_path https://raw.githubusercontent.com/remnawave/backend/refs/heads/main/docker-compose-prod.yml
    curl -o $remnawave_env_path https://raw.githubusercontent.com/remnawave/backend/refs/heads/main/.env.sample

    sed -i "s/^JWT_AUTH_SECRET=.*/JWT_AUTH_SECRET=$(openssl rand -hex 64)/" $remnawave_env_path
    sed -i "s/^JWT_API_TOKENS_SECRET=.*/JWT_API_TOKENS_SECRET=$(openssl rand -hex 64)/" $remnawave_env_path
    sed -i "s/^METRICS_PASS=.*/METRICS_PASS=$(openssl rand -hex 64)/" $remnawave_env_path
    sed -i "s/^WEBHOOK_SECRET_HEADER=.*/WEBHOOK_SECRET_HEADER=$(openssl rand -hex 64)/" $remnawave_env_path
    pw=$(openssl rand -hex 24)
    sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$pw/" $remnawave_env_path
    sed -i "s|^\(DATABASE_URL=\"postgresql://postgres:\)[^\@]*\(@.*\)|\1$pw\2|" $remnawave_env_path

    set_and_export "FRONT_END_DOMAIN" "Enter front-end domain: "
    set_and_export "SUB_PUBLIC_DOMAIN" "Enter subscription domain: "
    ensure_env_var "FRONT_END_DOMAIN" "$FRONT_END_DOMAIN" "$remnawave_env_path"
    ensure_env_var "SUB_PUBLIC_DOMAIN" "$SUB_PUBLIC_DOMAIN" "$remnawave_env_path"

    set_and_export "temp_123" "Press enter to start remnawave panel (ctrl + c to exit logs): "
    docker compose --project-directory "$remnawave_base_dir" up -d && docker compose --project-directory "$remnawave_base_dir" logs -f -t
else
    echo "✓ Remnawave panel already configured, skipping"
    set_and_export "FRONT_END_DOMAIN" "Enter front-end domain: "
    set_and_export "SUB_PUBLIC_DOMAIN" "Enter subscription domain: "
fi

set_and_export "temp_123" "Press enter to continue..."

mkdir -p $basic_nginx_folder

if [ ! -f "$basic_nginx_folder/$FRONT_END_DOMAIN.fullchain.pem" ]; then
    ~/.acme.sh/acme.sh --issue --standalone -d "$FRONT_END_DOMAIN" --alpn --tlsport 8443 --server letsencrypt
    ~/.acme.sh/acme.sh --install-cert -d "$FRONT_END_DOMAIN" --key-file "$basic_nginx_folder/$FRONT_END_DOMAIN.privkey.key" --fullchain-file "$basic_nginx_folder/$FRONT_END_DOMAIN.fullchain.pem"
else
    echo "✓ Certificate for $FRONT_END_DOMAIN already exists, skipping"
fi

if [ ! -f "$basic_nginx_folder/$SUB_PUBLIC_DOMAIN.fullchain.pem" ]; then
    ~/.acme.sh/acme.sh --issue --standalone -d "$SUB_PUBLIC_DOMAIN" --alpn --tlsport 8443 --server letsencrypt
    ~/.acme.sh/acme.sh --install-cert -d "$SUB_PUBLIC_DOMAIN" --key-file "$basic_nginx_folder/$SUB_PUBLIC_DOMAIN.privkey.key" --fullchain-file "$basic_nginx_folder/$SUB_PUBLIC_DOMAIN.fullchain.pem"
else
    echo "✓ Certificate for $SUB_PUBLIC_DOMAIN already exists, skipping"
fi

if [ ! -f "$basic_nginx_conf" ]; then
    cp -f $template_files_nginx_conf $basic_nginx_conf
    cp -f $template_files_nginx_resolver_conf $basic_nginx_resolver_conf
    cp -f $template_files_nginx_docker_compose $nginx_docker_compose
    sed -i "s/replace_me_frontend_panel_domain_name/$FRONT_END_DOMAIN/g" $basic_nginx_conf
    sed -i "s/replace_me_frontend_subscription_domain_name/$SUB_PUBLIC_DOMAIN/g" $basic_nginx_conf
else
    echo "✓ Nginx config already exists, skipping"
fi

mkdir -p $remnawave_subscription_panel_folder
[ ! -f "$remnawave_subscription_panel_docker_compose" ] && cp -f $template_files_subscription_compose $remnawave_subscription_panel_docker_compose
touch "$remnawave_subscription_panel_env"

mkdir -p $tgb_base_folder $tgb_nginx_folder

set_and_export "WEBHOOKS_DOMAIN" "Enter webhooks domain: "
set_and_export "CABINET_DOMAIN" "Enter cabinet domain: "

if [ ! -f "$tgb_nginx_folder/$WEBHOOKS_DOMAIN.fullchain.pem" ]; then
    ~/.acme.sh/acme.sh --issue --standalone -d "$WEBHOOKS_DOMAIN" --alpn --tlsport 8443 --server letsencrypt
    ~/.acme.sh/acme.sh --install-cert -d "$WEBHOOKS_DOMAIN" --key-file "$tgb_nginx_folder/$WEBHOOKS_DOMAIN.privkey.key" --fullchain-file "$tgb_nginx_folder/$WEBHOOKS_DOMAIN.fullchain.pem"
else
    echo "✓ Certificate for $WEBHOOKS_DOMAIN already exists, skipping"
fi

if [ ! -f "$tgb_nginx_folder/$CABINET_DOMAIN.fullchain.pem" ]; then
    ~/.acme.sh/acme.sh --issue --standalone -d "$CABINET_DOMAIN" --alpn --tlsport 8443 --server letsencrypt
    ~/.acme.sh/acme.sh --install-cert -d "$CABINET_DOMAIN" --key-file "$tgb_nginx_folder/$CABINET_DOMAIN.privkey.key" --fullchain-file "$tgb_nginx_folder/$CABINET_DOMAIN.fullchain.pem"
else
    echo "✓ Certificate for $CABINET_DOMAIN already exists, skipping"
fi

if [ ! -f "$tgb_nginx_conf" ]; then
    cp -f $template_files_bot_nginx_conf $tgb_nginx_conf
    sed -i "s/replace_me_webhooks_domain_name/$WEBHOOKS_DOMAIN/g" $tgb_nginx_conf
    sed -i "s/replace_me_cabinet_domain_name/$CABINET_DOMAIN/g" $tgb_nginx_conf
else
    echo "✓ Bot nginx config already exists, skipping"
fi

mkdir -p $tgb_webapp_temp_folder

docker compose --project-directory "$basic_nginx_folder" up -d --no-deps --build --force-recreate remnawave-nginx

echo "Visit https://$FRONT_END_DOMAIN"
echo "Please generate two API tokens in the panel and enter them below"
echo "After authorization visit: https://$FRONT_END_DOMAIN/dashboard/management/settings to generate tokens."
set_and_export "temp_123" "Press enter to continue..."

set_and_export "BOT_PANEL_API_TOKEN" "Enter api token for bot: "
set_and_export "SUBSCRIPTION_PANEL_API_TOKEN" "Enter api token for subscription panel: "

echo "Updating token for the subscription panel container..."
ensure_env_var "REMNAWAVE_API_TOKEN" "$SUBSCRIPTION_PANEL_API_TOKEN" "$remnawave_subscription_panel_env"

set_and_export "temp_123" "Press enter to start subscription panel (ctrl + c to exit logs): "
docker compose --project-directory "$remnawave_subscription_panel_folder" up -d && docker compose --project-directory "$remnawave_subscription_panel_folder" logs -f -t

set_and_export "temp_123" "Press enter to continue..."

echo "Create your first node and host: https://$FRONT_END_DOMAIN/dashboard/management/nodes"
set_and_export "temp_123" "Press enter to continue after creating a node..."

mkdir -p $tgb_base_bot_folder
cp -f $template_files_bot_telegram_bot_env $tgb_base_bot_env
cp -f $template_files_bot_telegram_bot_app_config_json $tgb_base_bot_app_config_json
cp -f $template_files_bot_telegram_bot_docker_compose $tgb_base_bot_docker_compose
cp -f $template_files_bot_telegram_bot_vpn_logo $tgb_base_bot_vpn_logo

mkdir -p $tgb_base_bot_folder/data $tgb_base_bot_folder/logs $tgb_base_bot_folder/postgres_data $tgb_base_bot_folder/redis_data $tgb_base_bot_folder/locales
chmod 777 $tgb_base_bot_folder/data $tgb_base_bot_folder/logs $tgb_base_bot_folder/postgres_data $tgb_base_bot_folder/redis_data $tgb_base_bot_folder/locales

set_and_export "TELEGRAM_BOT_TOKEN" "Enter your Telegram bot token: "
set_and_export "TELEGRAM_BOT_CHAT_ID" "Please create a supergroup chat, enable topics mode, add your bot in it as admin, and enter the id (-100): "

export testFile=$tgb_base_bot_env
ensure_env_var "BOT_TOKEN" "$TELEGRAM_BOT_TOKEN" "$testFile"
ensure_env_var "ADMIN_NOTIFICATIONS_CHAT_ID" "$TELEGRAM_BOT_CHAT_ID" "$testFile"
ensure_env_var "ADMIN_REPORTS_CHAT_ID" "$TELEGRAM_BOT_CHAT_ID" "$testFile"
ensure_env_var "BACKUP_SEND_CHAT_ID" "$TELEGRAM_BOT_CHAT_ID" "$testFile"
ensure_env_var "LOG_ROTATION_CHAT_ID" "$TELEGRAM_BOT_CHAT_ID" "$testFile"
set_and_export "temp_123" "Enter admin id: "
ensure_env_var "ADMIN_IDS" "$temp_123" "$testFile"
ensure_env_var "SUPPORT_TICKET_SLA_ENABLED" "true" "$testFile"
ensure_env_var "CABINET_ENABLED" "true" "$testFile"
ensure_env_var "CABINET_URL" "https://$CABINET_DOMAIN" "$testFile"
ensure_env_var "CABINET_JWT_SECRET" "$(openssl rand -hex 32)" "$testFile"
ensure_env_var "CABINET_ACCESS_TOKEN_EXPIRE_MINUTES" "60" "$testFile"
ensure_env_var "CABINET_ALLOWED_ORIGINS" "https://$CABINET_DOMAIN" "$testFile"
set_and_export "temp_123" "Enter admin notifications topic id: "
ensure_env_var "ADMIN_NOTIFICATIONS_TOPIC_ID" "$temp_123" "$testFile"
set_and_export "temp_123" "Enter admin notifications tickets topic id: "
ensure_env_var "ADMIN_NOTIFICATIONS_TICKET_TOPIC_ID" "$temp_123" "$testFile"
set_and_export "temp_123" "Enter admin notifications nalogs topic id: "
ensure_env_var "ADMIN_NOTIFICATIONS_NALOG_TOPIC_ID" "$temp_123" "$testFile"
set_and_export "temp_123" "Enter admin reports topic id: "
ensure_env_var "ADMIN_REPORTS_TOPIC_ID" "$temp_123" "$testFile"
set_and_export "temp_123" "Enter suspicious notifications topic id: "
ensure_env_var "SUSPICIOUS_NOTIFICATIONS_TOPIC_ID" "$temp_123" "$testFile"
set_and_export "temp_123" "Enter backup send topic id: "
ensure_env_var "BACKUP_SEND_TOPIC_ID" "$temp_123" "$testFile"
set_and_export "temp_123" "Enter log rotation topic id: "
ensure_env_var "LOG_ROTATION_TOPIC_ID" "$temp_123" "$testFile"
ensure_env_var "ADMIN_REPORTS_ENABLED" "true" "$testFile"
ensure_env_var "TRAFFIC_FAST_CHECK_ENABLED" "true" "$testFile"
ensure_env_var "TRAFFIC_DAILY_CHECK_ENABLED" "true" "$testFile"
ensure_env_var "BLACKLIST_CHECK_ENABLED" "true" "$testFile"
ensure_env_var "BLACKLIST_GITHUB_URL" "https://raw.githubusercontent.com/BEDOLAGA-DEV/VPN-BLACKLIST/refs/heads/main/blacklist.txt" "$testFile"
ensure_env_var "BLACKLIST_UPDATE_INTERVAL_HOURS" "1" "$testFile"
ensure_env_var "SQLITE_PATH" "/app/data/bot.db" "$testFile"
ensure_env_var "LOCALES_PATH" "/app/locales" "$testFile"
ensure_env_var "REMNAWAVE_API_URL" "http://remnawave:3000" "$testFile"
ensure_env_var "REMNAWAVE_API_KEY" "$BOT_PANEL_API_TOKEN" "$testFile"
ensure_env_var "REMNAWAVE_CADDY_TOKEN" "" "$testFile"
ensure_env_var "REMNAWAVE_USER_DESCRIPTION_TEMPLATE" "\"Bot user ({telegram_id}): {full_name} {username} {username_clean}\"" "$testFile"
ensure_env_var "REMNAWAVE_USER_DELETE_MODE" "disable" "$testFile"
ensure_env_var "REMNAWAVE_AUTO_SYNC_ENABLED" "true" "$testFile"
ensure_env_var "REMNAWAVE_AUTO_SYNC_TIMES" "03:00,15:00" "$testFile"
ensure_env_var "TRIAL_USER_TAG" "TRIAL" "$testFile"
ensure_env_var "PAID_SUBSCRIPTION_USER_TAG" "PAID" "$testFile"
ensure_env_var "TRIAL_DURATION_DAYS" "0" "$testFile"
ensure_env_var "TRIAL_TRAFFIC_LIMIT_GB" "0" "$testFile"
ensure_env_var "TRIAL_DEVICE_LIMIT" "0" "$testFile"
ensure_env_var "REFERRAL_PROGRAM_ENABLED" "false" "$testFile"
ensure_env_var "MULENPAY_SHOP_ID" "123" "$testFile"
ensure_env_var "FREEKASSA_SHOP_ID" "123" "$testFile"
ensure_env_var "FREEKASSA_PAYMENT_SYSTEM_ID" "123" "$testFile"
ensure_env_var "KASSA_AI_SHOP_ID" "123" "$testFile"
ensure_env_var "LOGO_FILE" "/app/vpn_logo.png" "$testFile"
ensure_env_var "MINIAPP_CUSTOM_URL" "https://$CABINET_DOMAIN" "$testFile"
ensure_env_var "APP_CONFIG_PATH" "/app/app-config.json" "$testFile"
ensure_env_var "BACKUP_INCLUDE_LOGS" "true" "$testFile"
ensure_env_var "LOG_FILE" "/app/logs/bot.log" "$testFile"
ensure_env_var "LOG_ROTATION_ENABLED" "true" "$testFile"
ensure_env_var "LOG_DIR" "/app/logs" "$testFile"
ensure_env_var "DEBUG" "false" "$testFile"
ensure_env_var "WEBHOOK_URL" "https://$WEBHOOKS_DOMAIN" "$testFile"
ensure_env_var "WEBHOOK_SECRET_TOKEN" "$(openssl rand -hex 32)" "$testFile"
ensure_env_var "WEB_API_DEFAULT_TOKEN" "$(openssl rand -hex 32)" "$testFile"
ensure_env_var "BOT_RUN_MODE" "webhook" "$testFile"
ensure_env_var "WEB_API_ENABLED" "true" "$testFile"
ensure_env_var "WEB_API_ALLOWED_ORIGINS" "https://$CABINET_DOMAIN" "$testFile"
ensure_env_var "WEB_API_DOCS_ENABLED" "true" "$testFile"

rm -rf $tgb_webapp_temp_folder

mkdir -p $tgb_base_bot_webapp_folder
cp -f $template_files_bot_webapp_env $tgb_base_bot_webapp_env

export testFile=$tgb_base_bot_webapp_env
set_and_export "temp_123" "Enter telegram bot username for cabinet (without @): "
ensure_env_var "VITE_TELEGRAM_BOT_USERNAME" "$temp_123" "$testFile"
set_and_export "temp_123" "Enter app name (displayed in header and browser tab): "
ensure_env_var "VITE_APP_NAME" "$temp_123" "$testFile"
set_and_export "temp_123" "Enter short logo text (1-2 characters, displayed in logo icon): "
ensure_env_var "VITE_APP_LOGO" "$temp_123" "$testFile"

mkdir -p $tgb_base_repo_dir

echo "Cloning the main repository..."
rm -rf "$MAIN_BOT_REPO_PATH"
git clone "$BASE_REPO_URL/$MAIN_REPO_NAME" "$MAIN_BOT_REPO_PATH"

echo "Cloning the cabinet repository..."
rm -rf "$CABINET_REPO_PATH"
git clone "$BASE_REPO_URL/$CABINET_REPO_NAME" "$CABINET_REPO_PATH"

echo "Building the cabinet..."
cp -f $tgb_base_bot_webapp_env "$CABINET_REPO_PATH/.env"
npm --prefix "$CABINET_REPO_PATH" install
npm --prefix "$CABINET_REPO_PATH" run build

echo "Building the telegram bot..."
docker compose --project-directory "$tgb_base_bot_folder" up -d --build --force-recreate

docker compose --project-directory "$basic_nginx_folder" restart

echo "Make sure you don't forget to add webapp url (https://$CABINET_DOMAIN) in @BotFather bot settings."

echo -e "\n\n\n"
echo -e "List of final docker paths:"
echo "Remnawave panel: $remnawave_base_dir"
echo "Subscription panel: $remnawave_subscription_panel_folder"
echo "Primary nginx server: $basic_nginx_folder"
echo "Telegram bot: $tgb_base_bot_folder"
echo -e "\n"
echo -e "Useful commands:"
echo "Restart:       docker compose --project-directory \"folder\" restart"
echo "Logs:          docker compose --project-directory \"folder\" logs -f -t"
echo "Stop:          docker compose --project-directory \"folder\" down"
echo "Force rebuild: docker compose --project-directory \"folder\" up -d --build --force-recreate"
echo -e "\nBuild cabinet:"
echo -e "\t cp -f \"$tgb_base_bot_webapp_env\" \"$CABINET_REPO_PATH/.env\" && rm -rf \"$CABINET_REPO_PATH/node_modules\" \"$CABINET_REPO_PATH/package-lock.json\" \"$CABINET_REPO_PATH/dist\" && git -C \"$CABINET_REPO_PATH\" pull origin main && npm --prefix \"$CABINET_REPO_PATH\" install && npm --prefix \"$CABINET_REPO_PATH\" run build"
echo -e "\nUpdate bot:"
echo -e "\t git -C \"$MAIN_BOT_REPO_PATH\" pull origin main && docker compose --project-directory \"$tgb_base_bot_folder\" up -d --build --force-recreate"
echo -e "\n\n\n"
