# 🔐 Git Credential Manager dla WSL - Instrukcja Krok po Krok

> **Kompletna instrukcja konfiguracji Git Credential Manager tylko w WSL (bez instalacji na Windows)**

## 📋 Wymagania

- ✅ WSL2 z Ubuntu/Debian (lub inna dystrybucja Linux)
- ✅ Git zainstalowany w WSL
- ✅ Dostęp do internetu
- ✅ Istniejące profile Git w `~/.config/git/profiles/`

## 🚀 Krok 1: Instalacja Git Credential Manager w WSL

### 1.1 Pobierz najnowszą wersję GCM

```bash
# Sprawdź najnowszą wersję
curl -s https://api.github.com/repos/GitCredentialManager/git-credential-manager/releases/latest | grep "tag_name" | cut -d '"' -f 4

# Pobierz dla Linux (aktualna wersja może się różnić)
cd /tmp
wget https://github.com/GitCredentialManager/git-credential-manager/releases/latest/download/gcm-linux_amd64.2.4.1.deb

# Alternatywnie - sprawdź dostępne pliki:
# https://github.com/GitCredentialManager/git-credential-manager/releases/latest
```

### 1.2 Zainstaluj pakiet

```bash
# Instalacja z .deb
sudo dpkg -i gcm-linux_amd64.*.deb

# Jeśli są problemy z zależnościami:
sudo apt-get update
sudo apt-get install -f

# Weryfikacja instalacji
git-credential-manager --version
```

### 1.3 Sprawdź ścieżkę instalacji

```bash
# Znajdź gdzie GCM został zainstalowany
which git-credential-manager

# Typowe lokalizacje:
# /usr/local/bin/git-credential-manager
# /usr/bin/git-credential-manager

# Zapisz ścieżkę - będzie potrzebna w konfiguracji
GCM_PATH=$(which git-credential-manager)
echo "GCM Path: $GCM_PATH"
```

## 🔧 Krok 2: Konfiguracja bazowa GCM

### 2.1 Konfiguracja globalna (opcjonalna)

```bash
# Ustaw GCM jako domyślny credential helper (globalnie)
git config --global credential.helper "$GCM_PATH"

# Lub tylko dla określonych domen:
git config --global credential.https://github.com.helper "$GCM_PATH"
git config --global credential.https://gitlab.com.helper "$GCM_PATH"
```

### 2.2 Konfiguracja WSL-specific

```bash
# WSL ma specjalne wymagania dla GUI
git config --global credential.guiPrompt false
git config --global credential.gitHubAuthModes browser
git config --global credential.gitLabAuthModes browser

# Opcjonalnie - wyłącz automatyczne updates
git config --global credential.autoDetectTimeout 0
```

## 📁 Krok 3: Konfiguracja profili Git

### 3.1 Profil Personal (GitHub)

Edytuj plik `~/.config/git/profiles/personal`:

```ini
[user]
    name = Twoja Nazwa
    email = twoj.email@personal.com

[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519_personal

# 🔐 CREDENTIAL MANAGER - DODAJ TO:
[credential]
    helper = /usr/local/bin/git-credential-manager

[credential "https://github.com"]
    provider = github
    helper = /usr/local/bin/git-credential-manager

# Opcjonalne - inne serwisy
[credential "https://gist.github.com"]  
    provider = github
    helper = /usr/local/bin/git-credential-manager
```

### 3.2 Profil Work (GitLab Enterprise)

Edytuj plik `~/.config/git/profiles/work`:

```ini
[user]
    name = Nazwa Służbowa
    email = nazwa@firma.com

[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519_work

# 🔐 CREDENTIAL MANAGER - DODAJ TO:
[credential]
    helper = /usr/local/bin/git-credential-manager

[credential "https://gitlab.com"]
    provider = gitlab
    helper = /usr/local/bin/git-credential-manager

# Enterprise GitLab (przykład)    
[credential "https://gitlab.firma.com"]
    provider = gitlab
    helper = /usr/local/bin/git-credential-manager

# GitHub firmowy (jeśli używasz)
[credential "https://github.com"]
    provider = github  
    helper = /usr/local/bin/git-credential-manager
```

### 3.3 Profil Client (Multiple services)

Edytuj plik `~/.config/git/profiles/client`:

```ini
[user]
    name = {{USER_NAME}}
    email = {{USER_EMAIL}}

[core] 
    sshCommand = ssh -i ~/.ssh/{{SSH_KEY}}

# 🔐 CREDENTIAL MANAGER - UNIWERSALNY:
[credential]
    helper = /usr/local/bin/git-credential-manager

# Support dla wszystkich popularnych serwisów
[credential "https://github.com"]
    provider = github
    helper = /usr/local/bin/git-credential-manager

[credential "https://gitlab.com"]
    provider = gitlab
    helper = /usr/local/bin/git-credential-manager
    
[credential "https://bitbucket.org"]
    provider = bitbucket
    helper = /usr/local/bin/git-credential-manager

# Azure DevOps (jeśli potrzebujesz)
[credential "https://dev.azure.com"]
    provider = azure-repos  
    helper = /usr/local/bin/git-credential-manager
```

## 🧪 Krok 4: Testowanie konfiguracji

### 4.1 Test podstawowy

```bash
# Przejdź do katalogu z odpowiednim profilem
cd ~/repositories/personal/jakis-projekt

# Sprawdź aktywny profil
git config --get user.name
git config --get user.email
git config --get credential.helper

# Test połączenia
git credential-manager version
```

### 4.2 Test z prawdziwym repozytorium

```bash
# Clone prywatnego repo (będzie wymagał autoryzacji)
git clone https://github.com/twoja-nazwa/private-repo.git

# GCM powinien:
# 1. Otworzyć przeglądarkę dla OAuth
# 2. Poprosić o autoryzację  
# 3. Zapisać token automatycznie
# 4. Użyć go przy następnych operacjach
```

### 4.3 Sprawdzenie zapisanych credentials

```bash
# Lista zapisanych credentials
git-credential-manager get

# Lub sprawdź konfigurację
git config --list | grep credential

# WSL credential store location (zazwyczaj):
ls ~/.gcm/
```

## 🔒 Krok 5: Bezpieczeństwo i zarządzanie tokenami

### 5.1 Zarządzanie tokenami

```bash
# Usuń zapisane credentials dla konkretnego serwisu
git-credential-manager erase

# Wyloguj ze wszystkich serwisów
git-credential-manager logout

# Sprawdź status autoryzacji
git-credential-manager status
```

### 5.2 Konfiguracja per-repository

```bash
# W konkretnym repozytorium możesz nadpisać ustawienia
cd ~/repositories/work/projekt
git config credential.helper "/usr/local/bin/git-credential-manager"
git config credential.provider "gitlab"
```

## 🛠️ Troubleshooting

### Problem 1: "credential helper nie znaleziony"

```bash
# Sprawdź instalację
which git-credential-manager
git-credential-manager --version

# Zaktualizuj ścieżkę w profilach
# Zmień z:
# helper = /usr/local/bin/git-credential-manager  
# Na aktualną ścieżkę z `which`
```

### Problem 1a: "No credential store has been selected"

```bash
# Skonfiguruj credential store (wymagane w GCM 2.6+)
git config --global credential.credentialStore cache

# Alternatywnie inne opcje:
# git config --global credential.credentialStore secretservice  # wymaga libsecret-1
# git config --global credential.credentialStore plaintext      # niezabezpieczony
# git config --global credential.credentialStore gpg           # wymaga pass + GPG
```

### Problem 2: "Browser nie otwiera się"

```bash
# WSL potrzebuje konfiguracji przeglądarki
export BROWSER=/mnt/c/Program\ Files/Google/Chrome/Application/chrome.exe

# Lub dodaj do ~/.bashrc:
echo 'export BROWSER="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"' >> ~/.bashrc
source ~/.bashrc
```

### Problem 3: "Permission denied mimo autoryzacji"

```bash
# Sprawdź czy token jest zapisany
git config --get-urlmatch credential https://github.com/user/repo

# Wymuś re-autoryzację  
git-credential-manager erase
git clone https://github.com/user/repo.git
```

## ⚡ Krok 6: Automatyzacja z aliasami Git

Dodaj do swoich profili praktyczne aliasy:

```ini
# W każdym profilu dodaj:
[alias]
    # Credential management
    cred-status = !git-credential-manager status
    cred-logout = !git-credential-manager logout  
    cred-erase = !git-credential-manager erase
    
    # Quick auth test
    auth-test = !echo "Testing auth for: $(git remote get-url origin)" && git ls-remote
```

## 📊 Podsumowanie

Po wykonaniu tych kroków będziesz miał:

✅ **Git Credential Manager zainstalowany tylko w WSL**  
✅ **Profile Git skonfigurowane z GCM support**  
✅ **Automatyczną autoryzację przez przeglądarkę**  
✅ **Bezpieczne przechowywanie tokenów**  
✅ **Support dla GitHub, GitLab, Bitbucket, Azure DevOps**

---

## 🚀 Następne kroki

1. **Uruchom automatyczny skrypt**: `./scripts/setup-gcm-wsl.sh`
2. **Przetestuj z prawdziwymi repozytoriami**  
3. **Skonfiguruj dodatowe serwisy jeśli potrzebujesz**

---

*Autor: Git Multi-Profile System*  
*Data: $(date +%Y-%m-%d)*