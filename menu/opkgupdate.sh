#!/bin/sh

# READ AUTH
if [ -f "/root/TELEXWRT/AUTH" ]; then
    IFS=$'\n' read -d '' -r -a lines < "/root/TELEXWRT/AUTH"
    if [ "${#lines[@]}" -ge 2 ]; then
        bot_token="${lines[0]}"
        CHAT_ID="${lines[1]}"
    else
        echo "Berkas auth harus memiliki setidaknya 2 baris (token dan chat ID Anda)."
        exit 1
    fi
else
    echo "Berkas auth tidak ditemukan."
    exit 1
fi


opkgres=$(opkg update)


if [ $? -eq 0 ]; then
    
    message="$opkgres"
else
   
    message="gagal opkg update"
fi

# Mengirim pesan ke akun Telegram pribadi
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$USER_ID&text=$MSG"
