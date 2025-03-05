#!/bin/bash
#source Github https://github.com/Haris131/e3372

# READ AUTH
if [ -f "/root/TELEXWRT/AUTH" ]; then
    IFS=$'\n' read -d '' -r -a lines < "/root/TELEXWRT/AUTH"
    if [ "${#lines[@]}" -ge 2 ]; then
        BOT_TOKEN="${lines[0]}"
        CHAT_ID="${lines[1]}"
        ipmodem="${lines[2]}"
        pass="${lines[3]}"
    else
        echo "Berkas auth harus memiliki setidaknya 2 baris (token dan chat ID Anda)."
        exit 1
    fi
else
    echo "Berkas auth tidak ditemukan."
    exit 1
fi

send_telegram_message() {
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d "chat_id=$CHAT_ID" \
        -d "text=$1" \
        -d "parse_mode=Markdown"
}


human_print(){
while read B dummy; do
  [ $B -lt 1024 ] && echo ${B} B && break
  KB=$(((B+512)/1024))
  [ $KB -lt 1024 ] && echo ${KB} KB && break
  MB=$(((KB+512)/1024))
  [ $MB -lt 1024 ] && echo ${MB} MB && break
  GB=$(((MB+512)/1024))
  [ $GB -lt 1024 ] && echo ${GB} GB && break
  echo $(((GB+512)/1024)) terabytes
done
}
bands() {
case $1 in
    "1")
    echo -e '2100 MHz'
    ;;
    "3")
    echo -e '1800 MHz'
    ;;
    "8")
    echo -e '900 MHz'
    ;;
    "40")
    echo -e '2300 MHz'
    ;;
    esac
}
network() {
case $1 in
  "0")
  echo -e 'No service'
  ;;
  "1")
  echo -e 'GSM (2G)'
  ;;
  "2")
  echo -e 'GPRS (2G)'
  ;;
  "3")
  echo -e 'EDGE (2G)'
  ;;
  "21")
  echo -e 'IS95A'
  ;;
  "22")
  echo -e 'IS95B'
  ;;
  "23")
  echo -e 'CDMA 1X'
  ;;
  "24")
  echo -e 'EVDO rev.0'
  ;;
  "25")
  echo -e 'EVDO rev.A'
  ;;
  "26")
  echo -e 'EVDO rev.B'
  ;;
  "27")
  echo -e 'HYBRID CDMA 1X'
  ;;
  "28")
  echo -e 'HYBRID EVDO rev.0'
  ;;
  "29")
  echo -e 'HYBRID EVDO rev.A'
  ;;
  "30")
  echo -e 'HYBRID EVDO rev.B'
  ;;
  "31")
  echo -e 'eHRPD rel.0'
  ;;
  "32")
  echo -e 'eHRPD rel.A'
  ;;
  "33")
  echo -e 'eHRPD rel.B'
  ;;
  "34")
  echo -e 'HYBRID eHRPD rel.0'
  ;;
  "35")
  echo -e 'HYBRID eHRPD rel.A'
  ;;
  "36")
  echo -e 'HYBRID eHRPD rel.B'
  ;;
  "41")
  echo -e 'UMTS (3G)'
  ;;
  "42")
  echo -e 'HSDPA (3G)'
  ;;
  "43")
  echo -e 'HSUPA (3G)'
  ;;
  "44")
  echo -e 'HSPA (3G)'
  ;;
  "45")
  echo -e 'HSPA+ (3.5G)'
  ;;
  "46")
  echo -e 'DC-HSPA+ (3.5G)'
  ;;
  "61")
  echo -e 'TD-SCDMA (3G)'
  ;;
  "62")
  echo -e 'TD-HSDPA (3G)'
  ;;
  "63")
  echo -e 'TD-HSUPA (3G)'
  ;;
  "64")
  echo -e 'TD-HSPA (3G)'
  ;;
  "65")
  echo -e 'TD-HSPA+ (3.5G)'
  ;;
  "81")
  echo -e '802.16E'
  ;;
  "101")
  echo -e 'LTE (4G)'
  ;;
  "1011")
  echo -e 'LTE CA (4G+)'
  ;;
  "111")
  echo -e 'NR (5G)'
  ;;
esac
}

login(){
echo -e "---------------------------"
data=$(curl -s http://$ipmodem/api/webserver/SesTokInfo -H "Host: $ipmodem" -H "Connection: keep-alive" -H "Accept: */*" -H "X-Requested-With: XMLHttpRequest" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.119 Safari/537.36" -H "Referer: http://$ipmodem/html/home.html" -H "Accept-Encoding: gzib, deflate" -H "Accept-Language: id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7")
sesi=$(echo "$data" | grep "SessionID=" | cut -b 10-147)
token=$(echo "$data" | grep "TokInfo" | cut -b 10-41)

check=$(curl -s http://$ipmodem/api/user/state-login -H "Host: $ipmodem" -H "Connection: keep-alive" -H "Accept: */*" -H "X-Requested-With: XMLHttpRequest" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.119 Safari/537.36" -H "Referer: http://$ipmodem/html/home.html" -H "Accept-Encoding: gzib, deflate" -H "Accept-Language: id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7" -H "Cookie: $sesi")
state=$(echo $check|awk -F "<State>" '{print $2}'|awk -F "</State>" '{print $1}')
type=$(echo $check|awk -F "<password_type>" '{print $2}'|awk -F "</password_type>" '{print $1}')
if [ $state = "0" ]; then
  echo "Activated Successfully";
else
  if [ $type = "4" ]; then
    pass1=$(echo -n "$pass"|sha256sum|head -c 64|base64 -w 0)
    pass1=$(echo -n "admin$pass1$token"|sha256sum|head -c 64|base64 -w 0)
    pass1=$(echo -n "$pass1</Password><password_type>4</password_type>")
  else
    pass1=$(echo -n "$pass"|base64 -w 0)
    pass1=$(echo -n "$pass1</Password>")
  fi
  login=$(curl -s -D- -o/dev/null -X POST http://$ipmodem/api/user/login -H "Host: $ipmodem" -H "Connection: keep-alive" -H "Accept: */*" -H "Origin: http://$ipmodem" -H "X-Requested-With: XMLHttpRequest" -H "__RequestVerificationToken: $token" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.119 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" -H "Referer: http://$ipmodem/html/home.html" -H "Accept-Encoding: gzib, deflate" -H "Accept-Language: id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7" -H "Cookie: $sesi" -d '<?xml version="1.0" encoding="UTF-8"?><request><Username>admin</Username><Password>'$pass1'</request>')
  scoki=$(echo "$login"|grep [Ss]et-[Cc]ookie|cut -d':' -f2|cut -b 1-138)
  if [ $scoki ]; then
    echo -e "Login Success"
  else
    echo -e "Login Failed"
    exit
  fi
fi
}

info(){
 login
 clear
 data=$(curl -s http://$ipmodem/api/webserver/SesTokInfo -H "Host: $ipmodem" -H "Connection: keep-alive" -H "Accept: */*" -H "X-Requested-With: XMLHttpRequest" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.119 Safari/537.36" -H "Referer: http://$ipmodem/html/home.html" -H "Accept-Encoding: gzib, deflate" -H "Accept-Language: id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7" -H "Cookie: $scoki")
 sesi=$(echo "$data" | grep "SessionID=" | cut -b 10-147)
 token=$(echo "$data" | grep "TokInfo" | cut -b 10-41)
 oper=$(curl -s http://$ipmodem/api/net/current-plmn -H "Host: $ipmodem" -H "Connection: keep-alive" -H "Accept: */*" -H "X-Requested-With: XMLHttpRequest" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.119 Safari/537.36" -H "Referer: http://$ipmodem/html/home.html" -H "Accept-Encoding: gzib, deflate" -H "Accept-Language: id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7" -H "Cookie: $sesi")
 operator=$(echo $oper|awk -F "<FullName>" '{print $2}'|awk -F "</FullName>" '{print $1}')
 ip=$(curl -s http://$ipmodem/api/device/information -H "Host: $ipmodem" -H "Connection: keep-alive" -H "Accept: */*" -H "X-Requested-With: XMLHttpRequest" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.119 Safari/537.36" -H "Referer: http://$ipmodem/html/home.html" -H "Accept-Encoding: gzib, deflate" -H "Accept-Language: id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7" -H "Cookie: $sesi")
 ipp=$(echo $ip|awk -F "<WanIPAddress>" '{print $2}'|awk -F "</WanIPAddress>" '{print $1}')
 tp=$(echo $ip|awk -F "<DeviceName>" '{print $2}'|awk -F "</DeviceName>" '{print $1}')
 dns=$(curl -s http://$ipmodem/api/monitoring/status -H "Host: $ipmodem" -H "Connection: keep-alive" -H "Accept: */*" -H "X-Requested-With: XMLHttpRequest" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.119 Safari/537.36" -H "Referer: http://$ipmodem/html/home.html" -H "Accept-Encoding: gzib, deflate" -H "Accept-Language: id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7" -H "Cookie: $sesi")
 dns1=$(echo $dns|awk -F "<PrimaryDns>" '{print $2}'|awk -F "</PrimaryDns>" '{print $1}')
 dns2=$(echo $dns|awk -F "<SecondaryDns>" '{print $2}'|awk -F "</SecondaryDns>" '{print $1}')
 net=$(echo $dns|awk -F "<CurrentNetworkTypeEx>" '{print $2}'|awk -F "</CurrentNetworkTypeEx>" '{print $1}')
 td=$(curl -s http://$ipmodem/api/monitoring/traffic-statistics -H "Host: $ipmodem" -H "Connection: keep-alive" -H "Accept: */*" -H "X-Requested-With: XMLHttpRequest" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.119 Safari/537.36" -H "Referer: http://$ipmodem/html/home.html" -H "Accept-Encoding: gzib, deflate" -H "Accept-Language: id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7" -H "Cookie: $sesi")
 tup=$(echo $td|awk -F "<TotalUpload>" '{print $2}'|awk -F "</TotalUpload>" '{print $1}'|human_print)
 tdd=$(echo $td|awk -F "<TotalDownload>" '{print $2}'|awk -F "</TotalDownload>" '{print $1}'|human_print)
 par=$(curl -s http://$ipmodem/config/deviceinformation/add_param.xml -H "Host: $ipmodem" -H "Connection: keep-alive" -H "Accept: */*" -H "X-Requested-With: XMLHttpRequest" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.119 Safari/537.36" -H "Referer: http://$ipmodem/html/home.html" -H "Accept-Encoding: gzib, deflate" -H "Accept-Language: id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7" -H "Cookie: $sesi")
 band=$(echo $par|awk -F "<band>" '{print $2}'|awk -F "</band>" '{print $1}')
 dlfreq=$(echo $par|awk -F "<freq1>" '{print $2}'|awk -F "</freq1>" '{print $1}')
 upfreq=$(echo $par|awk -F "<freq2>" '{print $2}'|awk -F "</freq2>" '{print $1}')
 dvi=$(curl -s http://$ipmodem/api/device/signal -H "Host: $ipmodem" -H "Connection: keep-alive" -H "Accept: */*" -H "X-Requested-With: XMLHttpRequest" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.119 Safari/537.36" -H "Referer: http://$ipmodem/html/home.html" -H "Accept-Encoding: gzib, deflate" -H "Accept-Language: id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7" -H "Cookie: $sesi")
 pci=$(echo $dvi|awk -F "<pci>" '{print $2}'|awk -F "</pci>" '{print $1}')
 cellid=$(echo $dvi|awk -F "<cell_id>" '{print $2}'|awk -F "</cell_id>" '{print $1}')
 rsrp=$(echo $dvi|awk -F "<rsrp>" '{print $2}'|awk -F "</rsrp>" '{print $1}')
 rssi=$(echo $dvi|awk -F "<rssi>" '{print $2}'|awk -F "</rssi>" '{print $1}')
 rsrq=$(echo $dvi|awk -F "<rsrq>" '{print $2}'|awk -F "</rsrq>" '{print $1}')
 sinr=$(echo $dvi|awk -F "<sinr>" '{print $2}'|awk -F "</sinr>" '{print $1}')

 message="
 ╔════════❖══════════❖════════╗
                          𝕀ℕ𝔽𝕆ℝ𝕄𝔸𝕊𝕀 𝕄𝕆𝔻𝔼𝕄
╚════════❖══════════❖════════╝
 ➥ 𝙾𝚙𝚎𝚛𝚊𝚝𝚘𝚛 : $operator
 ➥ 𝙳𝚎𝚟𝚒𝚌𝚎 : $tp
 ➥ 𝚆𝚊𝚗 𝙸𝙿 : $ipp
 ➥ 𝙳𝙽𝚂 1 : $dns1
 ➥ 𝙳𝙽𝚂 2 : $dns2
 ➥ $(echo -ne "𝙽𝚎𝚝𝚠𝚘𝚛𝚔 : ";network $net)
 ➥ 𝚃𝚘𝚝𝚊𝚕 𝚄𝚙𝚕𝚘𝚊𝚍 : $tup
 ➥ 𝚃𝚘𝚝𝚊𝚕 𝙳𝚘𝚠𝚗𝚕𝚘𝚊𝚍 : $tdd
 ➥ $(echo -ne "𝙱𝚊𝚗𝚍 : ";bands $band;) $(echo -ne "("$band")")
 ➥ 𝙿𝙲𝙸 : $pci
 ➥ 𝙲𝚎𝚕𝚕 𝙸𝙳 : $cellid
 ➥ 𝙳𝙻 𝙵𝚛𝚎𝚚𝚞𝚎𝚗𝚌𝚢 : $dlfreq
 ➥ 𝚄𝙿 𝙵𝚛𝚎𝚚𝚞𝚎𝚗𝚌𝚢 : $upfreq
 ➥ 𝚁𝚜𝚛𝚙 : $rsrp
 ➥ 𝚁𝚜𝚜𝚒 : $rssi
 ➥ 𝚁𝚜𝚛𝚚 : $rsrq
 ➥ 𝚂𝚒𝚗𝚛 : $sinr
 ▰▱▰▱▰▱▰▱▰▱▰▱▰▱▰▱▰▱▰▱▰
                              🇮​​🇰​​🇦​​🇷​​🇴​​🇳​​🇪​​🇹​ 2️⃣0️⃣2️⃣5️⃣
╚════════❖══════════❖════════╝
 "
}

info
send_telegram_message "$message"
