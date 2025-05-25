#!/bin/bash

   # Configuration
   LOG_DIR="/var/log/nginx"
   LOG_FILE="$LOG_DIR/access.log"
   NGINX_CONF="/etc/nginx/nginx.conf"
   NGINX_BIN="/usr/sbin/nginx"
   SERVERS_DIR="/etc/nginx/conf.d"
   HTML_DIR="/usr/share/nginx/html"

   # Function to check if command exists
   command_exists() {
       command -v "$1" >/dev/null 2>&1
   }

   # Install Nginx if not present
   if ! command_exists nginx; then
       echo "Installing Nginx..."
       sudo apt update
       sudo apt install -y nginx
   fi

   # Create log directory and file
   if [ ! -d "$LOG_DIR" ]; then
       echo "Creating log directory $LOG_DIR..."
       sudo mkdir -p "$LOG_DIR"
       sudo chown www-data:adm "$LOG_DIR"
       sudo chmod 755 "$LOG_DIR"
   fi
   if [ ! -f "$LOG_FILE" ]; then
       echo "Creating log file $LOG_FILE..."
       sudo touch "$LOG_FILE"
       sudo chown www-data:adm "$LOG_FILE"
       sudo chmod 644 "$LOG_FILE"
   fi

   # Backup nginx.conf
   sudo cp "$NGINX_CONF" "$NGINX_CONF.bak"

   # Write nginx.conf
   cat << 'EOF' | sudo tee "$NGINX_CONF"
   user www-data;
   worker_processes auto;

   events {
       worker_connections 1024;
   }

   http {
       include /etc/nginx/mime.types;
       default_type application/octet-stream;

       access_log /var/log/nginx/access.log;

       sendfile on;
       keepalive_timeout 65;

       include /etc/nginx/conf.d/*.conf;
   }
   EOF

   # Ensure servers directory exists
   sudo mkdir -p "$SERVERS_DIR"

   # Copy fastapi.conf
   sudo cp nginx/fastapi.conf "$SERVERS_DIR/fastapi.conf"

   # Create default 50x.html if not exists
   if [ ! -f "$HTML_DIR/50x.html" ]; then
       echo "<html><body><h1>500 Internal Server Error</h1></body></html>" | sudo tee "$HTML_DIR/50x.html"
   fi

   # Start Nginx
   if ! systemctl is-active --quiet nginx; then
       echo "Starting Nginx..."
       sudo systemctl start nginx
   fi

   # Test configuration
   sudo $NGINX_BIN -t || { echo "Error: Nginx configuration test failed"; exit 1; }

   # Reload Nginx
   sudo systemctl reload nginx

   # Generate initial log entry
   echo "Generating initial log entry..."
   curl http://localhost:8080 >/dev/null 2>&1
   sleep 1
   if [ ! -s "$LOG_FILE" ]; then
       echo "Warning: Log file $LOG_FILE is empty"
   fi

   echo "Success: Nginx is configured, and $LOG_FILE is ready"
   exit 0
