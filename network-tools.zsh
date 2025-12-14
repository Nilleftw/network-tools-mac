#!/bin/bash

# --- HELPER FUNCTIONS ---

print_line() {
    echo "----------------------------------------"
}

# validate_ip: Checks if a specific string is a valid IPv4 address (0-255)
validate_ip() {
    local ip=$1
    local stat=1

    # Check format X.X.X.X
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip_parts=($ip)
        IFS=$OIFS
        
        # Check each octet is <= 255
        if [[ ${ip_parts[0]} -le 255 && ${ip_parts[1]} -le 255 && \
              ${ip_parts[2]} -le 255 && ${ip_parts[3]} -le 255 ]]; then
            stat=0
        fi
    fi
    return $stat
}

# validate_target: 
# 1. Checks for empty/spaces/invalid chars.
# 2. If it looks like an IP, validates the octets.
validate_target() {
    local input="$1"
    
    # 1. Basic sanity checks (Empty, Spaces)
    if [[ -z "$input" ]]; then
        echo "❌ Error: Input cannot be empty."
        return 1
    fi
    if [[ "$input" =~ \  ]]; then
        echo "❌ Error: Input cannot contain spaces."
        return 1
    fi

    # 2. Check for illegal characters (security)
    if [[ ! "$input" =~ ^[a-zA-Z0-9.:-]+$ ]]; then
        echo "❌ Error: Invalid characters found."
        return 1
    fi

    # 3. IP Logic Check
    # If the input contains ONLY numbers and dots, we assume it's an IP and strict check it.
    if [[ "$input" =~ ^[0-9.]+$ ]]; then
        if ! validate_ip "$input"; then
            echo "❌ Error: '$input' is not a valid IPv4 address (Octets must be 0-255)."
            return 1
        fi
    fi

    # If it's a hostname (contains letters), we pass it through (assuming basic regex passed)
    return 0
}

# --- MAIN LOOP ---

while true; do
    echo ""
    print_line
    echo "   NETWORK DIAGNOSTIC TOOL"
    print_line
    echo "1. Ping Test"
    echo "2. DNS Lookup (nslookup)"
    echo "3. TCP Port Test"
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

            if [[ ! "$count" =~ ^[0-9]+$ ]]; then
                 echo "❌ Error: Packet count must be a number."
                 continue
            fi

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

            if [[ ! "$rtype" =~ ^[a-zA-Z]+$ ]]; then
                echo "❌ Error: Invalid record type."
                continue
            fi

            echo "Resolving $rtype records for $target..."
            print_line
            nslookup -type="$rtype" "$target"
            ;;
            
        3)
            # --- TCP PORT TEST ---
            read -p "Enter Host or IP: " target
            if ! validate_target "$target"; then continue; fi
            
            read -p "Enter Port (e.g., 80, 443): " port
            if [[ ! "$port" =~ ^[0-9]+$ ]]; then
                echo "❌ Error: Port must be a number."
                continue
            fi
            
            echo "Testing connection to $target on port $port..."
            if nc -z -w 5 "$target" "$port" 2>&1 > /dev/null; then
                echo "✅ SUCCESS: Port $port on $target is OPEN."
            else
                echo "❌ FAILURE: Port $port on $target is CLOSED or FILTERED."
            fi
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