#!/bin/bash

# READ AUTH
if [ -f "/root/TELEXWRT/AUTH" ]; then
    IFS=$'\n' read -d '' -r -a lines < "/root/TELEXWRT/AUTH"
    if [ "${#lines[@]}" -ge 2 ]; then
        BOT_TOKEN="${lines[0]}"
        USER_ID="${lines[1]}"
    else
        echo "Berkas token.txt harus memiliki setidaknya 2 baris (token dan chat ID Anda)."
        exit 1
    fi
else
    echo "Berkas token tidak ditemukan."
    exit 1
fi
# PING SERVER
SERVER=("google.com")
messages=()
failed=0
for server in "${SERVER[@]}"
do
    result=$(ping -c 1 $SERVER)
    if [ $? -eq 0 ]; then
        ping=$(echo "$result" | awk -F'/' 'END {printf "%.0f", $5}')
        messages+=("ping google.com 📈 $ping ms")
    else
        messages+=("Failed ❌")
        failed=$((failed_count + 1))
    fi
done
for msg in "${messages[@]}"
do
    MSG+="$msg"
done
# SEND MSG TO TG
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$USER_ID&text=$MSG"
