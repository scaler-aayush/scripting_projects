#!/bin/bash

   # Configuration
   LOG_FILE="/var/log/nginx/access.log"
   ERROR_PATTERN='" 500[[:space:]]'
   ALERT_SCRIPT="./send_slack_alert.py"
   SETUP_SCRIPT="./setup_nginx.sh"

   # Run setup script
   if ! bash "$SETUP_SCRIPT"; then
       echo "Aborting: Nginx setup failed"
       exit 1
   fi

   # Verify alert script
   if [ ! -f "$ALERT_SCRIPT" ]; then
       echo "Error: Alert script $ALERT_SCRIPT not found"
       exit 1
   fi

   # Verify log file exists
   if [ ! -f "$LOG_FILE" ]; then
       echo "Error: Log file $LOG_FILE not found"
       exit 1
   fi

   # Monitor logs
   echo "Monitoring $LOG_FILE for errors..."
   tail -f "$LOG_FILE" | grep --line-buffered "$ERROR_PATTERN" | while read -r line; do
       echo "Error detected: $line"
       python3 "$ALERT_SCRIPT" "$line"
   done
