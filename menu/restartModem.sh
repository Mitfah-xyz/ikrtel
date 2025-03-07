#!/bin/sh
#source Github https://github.com/Haris131/e3372

# READ AUTH
if [ -f "/root/TELEXWRT/AUTH" ]; then
    IFS=$'\n' read -d '' -r -a lines < "/root/TELEXWRT/AUTH"
    if [ "${#lines[@]}" -ge 4 ]; then
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


login(){
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
    er="login gagal, silahkan cek ip/password login."
    echo -e $er
    curl -s -X POST "https://api.telegram.org/bot$bot_token/sendMessage" -d "chat_id=$CHAT_ID" -d "text=$er"
    exit
  fi
fi
}

restart() {
 clear
 login
 clear
 # cookie
 data=$(curl -s http://$ipmodem/api/webserver/SesTokInfo -H "Host: $ipmodem" -H "Connection: keep-alive" -H "Accept: */*" -H "X-Requested-With: XMLHttpRequest" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.119 Safari/537.36" -H "Referer: http://$ipmodem/html/home.html" -H "Accept-Encoding: gzib, deflate" -H "Accept-Language: id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7" -H "Cookie: $scoki")
 sesi=$(echo "$data" | grep "SessionID=" | cut -b 10-147)
 token=$(echo "$data" | grep "TokInfo" | cut -b 10-41)
 curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$USER_ID&text="text=success restart modem"
 # restart modem
 res=$(curl -s -X POST http://$ipmodem/api/device/control -H "Host: $ipmodem" -H "Connection: keep-alive" -H "Accept: */*" -H "Origin: http://$ipmodem" -H "X-Requested-With: XMLHttpRequest" -H "__RequestVerificationToken: $token" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.119 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" -H "Referer: http://$ipmodem/html/home.html" -H "Accept-Encoding: gzib, deflate" -H "Accept-Language: id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7" -H "Cookie: $sesi" -d '<?xml version="1.0" encoding="UTF-8"?><request><Control>1</Control></request>')
 ress=$(echo $res|awk -F "<response>" '{print $2}'|awk -F "</response>" '{print $1}')
 if [ "$ress" = "OK" ]; then
   echo -e "Rebooting..."
 else
   curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$USER_ID&text=$res"
 fi
}

restart
