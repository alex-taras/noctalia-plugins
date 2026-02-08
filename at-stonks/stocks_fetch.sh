#!/bin/bash

get_stock_data() {
    local api_key=$1
    local symbols_str=$2
    IFS=',' read -ra symbols <<< "$symbols_str"
    
    echo '{"stocks":{'
    
    for i in "${!symbols[@]}"; do
        local symbol="${symbols[$i]}"
        local response=$(curl -s "https://finnhub.io/api/v1/quote?symbol=${symbol}&token=${api_key}")
        
        # Parse JSON fields manually with grep/sed
        local price=$(echo "$response" | grep -o '"c":[^,}]*' | cut -d: -f2)
        local change=$(echo "$response" | grep -o '"d":[^,}]*' | cut -d: -f2)
        local prev=$(echo "$response" | grep -o '"pc":[^,}]*' | cut -d: -f2)
        local prc=$(echo "$response" | grep -o '"dp":[^,}]*' | cut -d: -f2)
        
        # Check if we got valid data
        if [ -z "$price" ]; then
            echo -n "\"${symbol}\":{\"success\":1}"
        else
            echo -n "\"${symbol}\":{\"success\":0,\"price\":${price},\"change\":${change},\"prev\":${prev},\"prc\":${prc}}"
        fi
        
        [[ $i -lt $((${#symbols[@]} - 1)) ]] && echo -n ","
    done
    
    echo '}}'
}

DATA=$(get_stock_data "$1" "$2")

echo $DATA