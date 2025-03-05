#!/bin/sh

# READ AUTH
if [ -f "/root/TELEXWRT/AUTH" ]; then
    IFS=$'\n' read -d '' -r -a lines < "/root/TELEXWRT/AUTH"
    if [ "${#lines[@]}" -ge 2 ]; then
        BOT_TOKEN="${lines[0]}"
        CHAT_ID="${lines[1]}"
    else
        echo "Berkas auth harus memiliki setidaknya 2 baris (token dan chat ID Anda)."
        exit 1
    fi
else
    echo "Berkas auth tidak ditemukan."
    exit 1
fi

# Menjalankan speedtest dan menyimpan hasilnya dalam variabel
speedtest_result=$(speedtest)

# Cek apakah speedtest berhasil atau gagal
if [ $? -eq 0 ]; then
    # Jika berhasil, maka mengambil nilai-nilai yang diperlukan
    download=$(echo "$speedtest_result" | grep "Download" | awk '{print $2}')
    upload=$(echo "$speedtest_result" | grep "Upload" | awk '{print $2}')
    ping=$(echo "$speedtest_result" | grep "Latency" | awk '{print $2}' | sed 's/ms//')
    isp=$(echo "$speedtest_result" | grep "ISP" | cut -d ':' -f2-)
    server_name=$(echo "$speedtest_result" | grep "Server" | cut -d ':' -f2- | sed 's/(id = [0-9]*)//') # Menghilangkan "(id = ...)"
    result_url=$(echo "$speedtest_result" | grep "Result URL" | cut -d ':' -f2-)

    # Mengambil informasi dari perintah curl
    curl_result=$(curl -sS ipinfo.io/json?token=7b5dbaccc41db0)
    ip=$(echo "$curl_result" | jq -r '.ip')
    hostname=$(echo "$curl_result" | jq -r '.hostname')
    org=$(echo "$curl_result" | jq -r '.org')
    timezone=$(echo "$curl_result" | jq -r '.timezone')

    # Menambahkan tanggal dan waktu terakhir pembaruan
    current_time=$(date +"%d-%m-%Y %I:%M %p")

    # Membuat pesan dengan format yang diinginkan jika speedtest berhasil
    message="
    ╔════════❖══════════❖════════╗
                          𝕊ℙ𝔼𝔼𝔻𝕋𝔼𝕊𝕋 𝕊𝕌𝕄𝕄𝔸ℝ𝕐
╚════════❖══════════❖════════╝
 ➥ 𝙷𝚘𝚜𝚝 : $(uci get system.@system[0].hostname | tr -d '\0') 
 ➥ 𝚙𝚒𝚗𝚐 : $ping ms
 ➥ 𝚒𝚙 : $ip
 ➥ 𝚂𝚎𝚛𝚟𝚎𝚛 : $server_name
 ➥ 𝙸𝚂𝙿 : $org 
 ➥ 𝚁𝚎𝚐𝚒𝚘𝚗 : $timezone 
 ➥ 𝙳𝚘𝚠𝚗𝚕𝚘𝚊𝚍 : $download Mbps
 ➥ 𝚄𝚙𝚕𝚘𝚊𝚍 : $upload Mbps
 ▰▱▰▱▰▱▰▰▱▰▱▰▱▰▱▰▱▰▱▰▱
                              ​🇮​​🇰​​🇦​​🇷​​🇴​​🇳​​🇪​​🇹​ 2️⃣0️⃣2️⃣5️⃣
╚════════❖══════════❖════════╝
"
else
    # Jika speedtest gagal, maka mengirimkan pesan notifikasi
    message="FAILED SPEEDTEST....."
fi

# Mengirim pesan ke akun Telegram pribadi
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$USER_ID&text=$MSG"
