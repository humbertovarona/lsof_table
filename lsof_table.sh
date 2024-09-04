#!/bin/bash

# Run lsof to get network-related information
output=$(sudo lsof -i -P -n)

# Color formatting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print table header with dividers
printf "%-15s | %-8s | %-15s | %-6s | %-15s | %-6s | %-10s | %-15s | %-10s | %-10s\n" \
       "PROCESS NAME" "PROTO" "LOCAL IP" "L.PORT" "FOREIGN IP" "F.PORT" "STATE" "USER" "TYPE" "INTERFACE"
printf "%s\n" "------------------------------------------------------------------------------------------------------------------------------------------"

# Parse the lsof output, skipping the first line (header)
echo "$output" | tail -n +2 | while read -r line; do
    # Extract relevant fields using awk and field splitting
    process_name=$(echo "$line" | awk '{print $1}')  # Process name (real application)
    proto=$(echo "$line" | awk '{print $8}')    # Protocol (TCP/UDP)
    pid=$(echo "$line" | awk '{print $2}')      # Process ID (PID)
    user=$(echo "$line" | awk '{print $3}')     # User
    fd=$(echo "$line" | awk '{print $4}')       # File Descriptor (used for type)
    type=$(echo "$line" | awk '{print $5}')     # Connection type (IPv4/IPv6)
    local_address=$(echo "$line" | awk '{print $9}' | cut -d'-' -f1)  # Local address
    foreign_address=$(echo "$line" | awk '{print $9}' | cut -d'>' -f2)  # Foreign address
    
    # Extract local and foreign IP and port
    local_ip=$(echo "$local_address" | rev | cut -d':' -f2- | rev)
    local_port=$(echo "$local_address" | rev | cut -d':' -f1 | rev)
    foreign_ip=$(echo "$foreign_address" | rev | cut -d':' -f2- | rev)
    foreign_port=$(echo "$foreign_address" | rev | cut -d':' -f1 | rev)
    
    # Determine the state
    state=$(echo "$line" | awk '{print $10}')
    if [[ $state != "LISTEN" && $state != "ESTABLISHED" ]]; then
        state="-"
    fi

    # Determine the interface (assume based on the local IP for simplicity)
    if [[ $local_ip == 127.0.0.1* ]]; then
        interface="lo"
    elif [[ $local_ip == *:* ]]; then
        interface="ipv6"
    else
        interface="eth0"  # Assuming a default interface for external IPs
    fi

    # Apply color based on protocol and print formatted data
    if [[ $proto == "TCP" ]]; then
        printf "${GREEN}%-15s | %-8s | %-15s | %-6s | %-15s | %-6s | %-10s | %-15s | %-10s | %-10s${NC}\n" \
               "$process_name" "$proto" "$local_ip" "$local_port" "$foreign_ip" "$foreign_port" "$state" "$user" "$type" "$interface"
    elif [[ $proto == "UDP" ]]; then
        printf "${YELLOW}%-15s | %-8s | %-15s | %-6s | %-15s | %-6s | %-10s | %-15s | %-10s | %-10s${NC}\n" \
               "$process_name" "$proto" "$local_ip" "$local_port" "$foreign_ip" "$foreign_port" "-" "$user" "$type" "$interface"
    fi
done

# Final divider line
printf "%s\n"
