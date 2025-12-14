#!/bin/bash

# --- HELPER FUNCTIONS ---

print_line() {
    echo "----------------------------------------"
}

validate_ip() {
    local ip=$1
    local stat=1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS; IFS='.'; ip_parts=($ip); IFS=$OIFS
        if [[ ${ip_parts[0]} -le 255 && ${ip_parts[1]} -le 255 && \
              ${ip_parts[2]} -le 255 && ${ip_parts[3]} -le 255 ]]; then
            stat=0
        fi
    fi
    return $stat
}

validate_target() {
    local input="$1"
    if [[ -z "$input" ]]; then echo "❌ Error: Input cannot be empty."; return 1; fi
    if [[ "$input" =~ \  ]]; then echo "❌ Error: Input cannot contain spaces."; return 1; fi
    if [[ ! "$input" =~ ^[a-zA-Z0-9.:-]+$ ]]; then echo "❌ Error: Invalid characters found."; return 1; fi
    if [[ "$input" =~ ^[0-9.]+$ ]]; then
        if ! validate_ip "$input"; then
            echo "❌ Error: '$input' is not a valid IPv4 address."; return 1
        fi
    fi
    return 0
}

# --- PORT TESTING FUNCTIONS ---

check_tcp() {
    local target=$1
    local port=$2
    
    echo -n "👉 Attempting TCP... "
    # Uses curl for precise timing
    result=$(echo "QUIT" | curl -so /dev/null -w "%{time_connect}" --connect-timeout 3 telnet://"$target":"$port")
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        ms=$(echo "$result" | awk '{print $1 * 1000}')
        ms_formatted=$(printf "%.2f" $ms)
        echo "✅ SUCCESS!"
        echo "   Protocol: TCP"
        echo "   Latency:  ${ms_formatted} ms"
        return 0
    else
        echo "❌ Failed."
        return 1
    fi
}

check_udp() {
    local target=$1
    local port=$2
    
    echo -n "👉 Attempting UDP... "
    # Uses nc -u -z -w 2 (2 second timeout)
    if nc -u -z -w 2 "$target" "$port" 2>&1 > /dev/null; then
        echo "✅ SUCCESS!"
        echo "   Protocol: UDP"
        echo "   Note: UDP is connectionless; 'Success' usually means the packet was accepted."
        return 0
    else
        echo "❌ Failed."
        return 1
    fi
}

# --- MAIN LOOP ---

while true; do
    echo ""
    print_line
    echo "   NETWORK DIAGNOSTIC TOOL"
    print_line
    echo "1. Ping Test"
    echo "2. DNS Lookup (nslookup)"
    echo "3. Port Test (Flexible)"
    echo "4. Exit"
    echo ""
    
    read -p "Select an option [1-4]: " option
    echo ""

    case $option in
        1)
            # --- PING TEST ---
            read -p "Enter Host or IP to ping: " target
            if ! validate_target "$target"; then continue; fi
            read -p "Enter packet count (default 3): " count
            count=${count:-3} 
            if [[ ! "$count" =~ ^[0-9]+$ ]]; then echo "❌ Error: Packet count must be a number."; continue; fi
            echo "Running ping on $target ($count packets)..."
            print_line
            ping -c "$count" "$target"
            ;;
            
        2)
            # --- NSLOOKUP TEST ---
            read -p "Enter Hostname to resolve: " target
            if ! validate_target "$target"; then continue; fi
            echo "Common types: A (IP), MX (Mail), TXT (Text), CNAME (Alias), NS (Nameserver)"
            read -p "Enter Record Type [default: A]: " rtype
            rtype=${rtype:-A}
            if [[ ! "$rtype" =~ ^[a-zA-Z]+$ ]]; then echo "❌ Error: Invalid record type."; continue; fi
            echo "Resolving $rtype records for $target..."
            print_line
            nslookup -type="$rtype" "$target"
            ;;
            
        3)
            # --- FLEXIBLE PORT TEST ---
            read -p "Enter Host or IP: " target
            if ! validate_target "$target"; then continue; fi
            
            read -p "Enter Port (e.g., 53, 80, 443): " port
            if [[ ! "$port" =~ ^[0-9]+$ ]]; then echo "❌ Error: Port must be a number."; continue; fi
            
            # ASK FOR PROTOCOL
            echo "Choose Protocol:"
            echo "   [Enter] = Auto (Try UDP first, then TCP)"
            echo "   [tcp]   = TCP only"
            echo "   [udp]   = UDP only"
            read -p "Selection: " proto
            
            # Default to "both" if empty
            proto=${proto:-both}
            # Normalize to lowercase
            proto=$(echo "$proto" | tr '[:upper:]' '[:lower:]')

            echo "Testing connection to $target on port $port..."
            print_line

            case $proto in
                tcp)
                    check_tcp "$target" "$port"
                    ;;
                udp)
                    check_udp "$target" "$port"
                    ;;
                both|auto)
                    # 1. Try UDP first (Your request)
                    if check_udp "$target" "$port"; then
                        # If UDP success, do nothing else
                        : 
                    else
                        # If UDP failed, try TCP
                        check_tcp "$target" "$port"
                    fi
                    ;;
                *)
                    echo "❌ Error: Invalid protocol selection."
                    ;;
            esac
            ;;
            
        4)
            echo "Exiting. Goodbye!"
            exit 0
            ;;
            
        *)
            echo "❌ Invalid option. Please select 1-4."
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..." dummy
    clear
done