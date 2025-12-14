#!/bin/bash

# --- CONFIGURATION ---
LOG_FILE="network_report.log"
LOGGING=false

# --- ARGUMENT PARSING ---
while getopts "l" opt; do
  case $opt in
    l)
      LOGGING=true
      echo "📝 Logging enabled. Saving to: $LOG_FILE"
      sleep 1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# --- LOGGING FUNCTION ---
log_transaction() {
    local cmd="$1"
    local output="$2"
    
    if [ "$LOGGING" = true ]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$timestamp] CMD: $cmd" >> "$LOG_FILE"
        echo "RESULT: $output" >> "$LOG_FILE"
        echo "" >> "$LOG_FILE"
    fi
}

print_line() {
    echo "----------------------------------------"
}

# --- VALIDATION FUNCTIONS ---
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
<<<<<<< HEAD
    local cmd_log="curl -so /dev/null -w %{time_connect} --connect-timeout 3 telnet://$target:$port"
    
=======
    
    # Log string
    local cmd_log="curl -so /dev/null -w %{time_connect} --connect-timeout 3 telnet://$target:$port"
    
    # FIX: Restored 'echo QUIT |' to prevent hanging on open ports
>>>>>>> origin/main
    local result
    result=$(echo "QUIT" | curl -so /dev/null -w "%{time_connect}" --connect-timeout 3 "telnet://$target:$port")
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
<<<<<<< HEAD
        ms=$(echo "$result" | awk '{print $1 * 1000}')
        ms_formatted=$(printf "%.2f" $ms)
=======
        # Success Logic
        ms=$(echo "$result" | awk '{print $1 * 1000}')
        ms_formatted=$(printf "%.2f" $ms)
        
>>>>>>> origin/main
        echo "✅ SUCCESS! (${ms_formatted} ms)"
        log_transaction "$cmd_log" "Success - Latency: ${ms_formatted} ms"
        return 0
    else
<<<<<<< HEAD
=======
        # Failure Logic
>>>>>>> origin/main
        echo "❌ Failed."
        log_transaction "$cmd_log" "Failed - Connection Refused or Timeout"
        return 1
    fi
}

check_udp() {
    local target=$1
    local port=$2
<<<<<<< HEAD
    echo -n "👉 Attempting UDP... "
    local cmd_log="nc -u -z -w 2 $target $port"
=======
    
    echo -n "👉 Attempting UDP... "
    
    local cmd_log="nc -u -z -w 2 $target $port"
    
    # Run nc (Netcat) in UDP mode
>>>>>>> origin/main
    if nc -u -z -w 2 "$target" "$port" 2>&1 > /dev/null; then
        echo "✅ SUCCESS!"
        log_transaction "$cmd_log" "Success - Packet Accepted (Open)"
        return 0
    else
        echo "❌ Failed."
        log_transaction "$cmd_log" "Failed - Unreachable or Closed"
        return 1
    fi
}

# --- MAIN LOOP ---

while true; do
    echo ""
    print_line
    echo "   NETWORK DIAGNOSTIC TOOL"
    if [ "$LOGGING" = true ]; then echo "   (Logs active)"; fi
    print_line
    echo "1. Ping Test"
<<<<<<< HEAD
    echo "2. DNS Lookup (dig)"
    echo "3. Port Test (UDP/TCP)"
=======
    echo "2. DNS Lookup (nslookup)"
    echo "3. Port Test (Flexible)"
>>>>>>> origin/main
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
            
            cmd_log="ping -c $count $target"
            echo "Running: $cmd_log"
            print_line
<<<<<<< HEAD
=======
            
>>>>>>> origin/main
            output=$(ping -c "$count" "$target" 2>&1)
            echo "$output"
            log_transaction "$cmd_log" "$output"
            ;;
            
        2)
            # --- DNS LOOKUP (DIG) ---
            read -p "Enter Hostname to resolve: " target
            if ! validate_target "$target"; then continue; fi
            echo "Common types: A (IP), MX (Mail), TXT (Text), CNAME (Alias), NS (Nameserver)"
            read -p "Enter Record Type [default: A]: " rtype
            rtype=${rtype:-A}
            if [[ ! "$rtype" =~ ^[a-zA-Z]+$ ]]; then echo "❌ Error: Invalid record type."; continue; fi
            
<<<<<<< HEAD
            # Using 'dig' with options:
            # +noall +answer : Hide header garbage, show answers
            # +stats : Show the footer with "Query time"
            cmd_log="dig +noall +answer +stats -t $rtype $target"
            echo "Resolving $rtype for $target..."
            print_line
            
            # Capture output
            raw_output=$(dig +noall +answer +stats -t "$rtype" "$target" 2>&1)
            
            # Extract just the "Query time" line for display
            query_time=$(echo "$raw_output" | grep "Query time" | sed 's/;; //')
            
            # Extract just the answer lines (lines that don't start with ;)
            answers=$(echo "$raw_output" | grep -v "^;")

            if [[ -z "$answers" ]]; then
                echo "❌ No $rtype records found or lookup failed."
                echo "$query_time"
            else
                echo "$answers"
                echo ""
                echo "⏱️  $query_time"
            fi
            
            # Log the full clean output
            log_transaction "$cmd_log" "$raw_output"
            ;;
            
        3)
            # --- PORT TEST UDP/TCP ---
=======
            cmd_log="nslookup -type=$rtype $target"
            echo "Running: $cmd_log"
            print_line
            
            output=$(nslookup -type="$rtype" "$target" 2>&1)
            echo "$output"
            
            clean_output=$(echo "$output" | sed '/^$/d')
            log_transaction "$cmd_log" "$clean_output"
            ;;
            
        3)
            # --- FLEXIBLE PORT TEST ---
>>>>>>> origin/main
            read -p "Enter Host or IP: " target
            if ! validate_target "$target"; then continue; fi
            read -p "Enter Port: " port
            if [[ ! "$port" =~ ^[0-9]+$ ]]; then echo "❌ Error: Port must be a number."; continue; fi
            
            echo "Choose Protocol: [Enter]=Auto, [tcp], [udp]"
            read -p "Selection: " proto
            proto=${proto:-both}
            proto=$(echo "$proto" | tr '[:upper:]' '[:lower:]')

            echo "Testing $target:$port..."
            print_line

            case $proto in
                tcp) check_tcp "$target" "$port" ;;
                udp) check_udp "$target" "$port" ;;
                both|auto)
<<<<<<< HEAD
                    if check_udp "$target" "$port"; then :; else check_tcp "$target" "$port"; fi ;;
=======
                    if check_udp "$target" "$port"; then
                        :
                    else
                        check_tcp "$target" "$port"
                    fi
                    ;;
>>>>>>> origin/main
                *) echo "❌ Error: Invalid protocol.";;
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