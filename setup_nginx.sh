#!/bin/bash

# Configuration
LOG_DIR="/opt/homebrew/var/log/nginx"
LOG_FILE="$LOG_DIR/access.log"
NGINX_CONF="/opt/homebrew/etc/nginx/nginx.conf"
NGINX_BIN="/opt/homebrew/bin/nginx"
SERVERS_DIR="/opt/homebrew/etc/nginx/servers"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Homebrew if not present
if ! command_exists brew; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install Nginx if not present
if ! command_exists nginx; then
    echo "Installing Nginx..."
    brew install nginx
fi

# Create log directory and file
if [ ! -d "$LOG_DIR" ]; then
    echo "Creating log directory $LOG_DIR..."
    sudo mkdir -p "$LOG_DIR"
    sudo chown $(whoami):staff "$LOG_DIR"
    sudo chmod 755 "$LOG_DIR"
fi
if [ ! -f "$LOG_FILE" ]; then
    echo "Creating log file $LOG_FILE..."
    sudo touch "$LOG_FILE"
    sudo chown $(whoami):staff "$LOG_FILE"
    sudo chmod o+r "$LOG_FILE"
fi

# Backup nginx.conf
sudo cp "$NGINX_CONF" "$NGINX_CONF.bak"

# Write correct nginx.conf
cat << 'EOF' | sudo tee "$NGINX_CONF"
user nobody;
worker_processes 1;

events {
    worker_connections 1024;
}

http {
    include mime.types;
    default_type application/octet-stream;

    access_log /opt/homebrew/var/log/nginx/access.log;

    sendfile on;
    keepalive_timeout 65;

    include servers/*;
}
EOF

# Ensure servers directory exists
sudo mkdir -p "$SERVERS_DIR"

# Start Nginx
if ! pgrep nginx >/dev/null; then
    echo "Starting Nginx..."
    brew services start nginx
fi

# Test configuration
sudo $NGINX_BIN -t || { echo "Error: Nginx configuration test failed"; exit 1; }

# Reload Nginx
sudo $NGINX_BIN -s reload

# Generate initial log entry
echo "Generating initial log entry..."
curl http://localhost:8080 >/dev/null 2>&1
sleep 1
if [ ! -s "$LOG_FILE" ]; then
    echo "Warning: Log file $LOG_FILE is empty"
fi

echo "Success: Nginx is configured, and $LOG_FILE is ready"
exit 0