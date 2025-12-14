#!/bin/bash

# Function to print a separator line
print_line() {
    echo "----------------------------------------"
}

# Infinite loop to keep the program running
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
    
    # Read user choice
    read -p "Select an option [1-4]: " option
    echo ""

    case $option in
        1)
            # --- PING TEST ---
            read -p "Enter Host or IP to ping: " target
            read -p "Enter packet count (default 3): " count
            
            # Set default count to 3 if input is empty
            count=${count:-3}

            if [[ -z "$target" ]]; then
                echo "❌ Error: Host cannot be empty."
            else
                echo "Running ping on $target ($count packets)..."
                print_line
                # We let ping output directly to screen so you see the results in real-time
                ping -c "$count" "$target"
            fi
            ;;
            
        2)
            # --- NSLOOKUP TEST ---
            read -p "Enter Hostname to resolve: " target
            
            if [[ -z "$target" ]]; then
                echo "❌ Error: Hostname cannot be empty."
            else
                echo "Resolving $target..."
                print_line
                nslookup "$target"
            fi
            ;;
            
        3)
            # --- TCP PORT TEST ---
            read -p "Enter Host or IP: " target
            read -p "Enter Port (e.g., 80, 443, 22): " port
            
            if [[ -z "$target" || -z "$port" ]]; then
                echo "❌ Error: Target and Port are required."
            else
                echo "Testing connection to $target on port $port..."
                # Using nc (netcat)
                # -z = scan mode, -v = verbose, -w = timeout
                # We capture the output to determine success/fail for a cleaner message
                if nc -z -w 5 "$target" "$port" 2>&1 > /dev/null; then
                    echo "✅ SUCCESS: Port $port on $target is OPEN."
                else
                    echo "❌ FAILURE: Port $port on $target is CLOSED or FILTERED."
                fi
            fi
            ;;
            
        4)
            # --- EXIT ---
            echo "Exiting. Goodbye!"
            exit 0
            ;;
            
        *)
            echo "❌ Invalid option. Please select 1-4."
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..." dummy
    clear # Clears the screen for the next run (remove this line if you want to keep history)
done