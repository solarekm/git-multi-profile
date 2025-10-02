# 🔐 Git Credential Manager dla WSL - Quick Start

> **Szybkie rozpoczęcie pracy z Git Credential Manager w WSL**

## 🚀 Opcja 1: Automatyczna instalacja (ZALECANE)

```bash
# Przejdź do katalogu git-multi-profile
cd git-multi-profile

# Podgląd zmian (bez wykonywania)
./scripts/setup-gcm-wsl.sh --dry-run

# Automatyczna instalacja i konfiguracja
./scripts/setup-gcm-wsl.sh
```

**Co zrobi skrypt:**
- ✅ Pobierze i zainstaluje najnowszy Git Credential Manager
- ✅ Skonfiguruje ustawienia WSL dla GCM  
- ✅ Doda konfigurację GCM do wszystkich profili Git
- ✅ Przeprowadzi testy konfiguracji

---

## ⚙️ Opcja 2: Manualna konfiguracja

### Krok 1: Instalacja GCM
```bash
# Pobierz najnowszą wersję
wget https://github.com/GitCredentialManager/git-credential-manager/releases/latest/download/gcm-linux_amd64.2.6.1.deb

# Zainstaluj
sudo dpkg -i gcm-linux_amd64.2.6.1.deb
```

### Krok 2: Konfiguracja WSL
```bash
# Ustawienia globalne dla WSL
git config --global credential.guiPrompt false
git config --global credential.gitHubAuthModes browser
git config --global credential.gitLabAuthModes browser
```

### Krok 3: Dodaj do profili Git

Do każdego pliku `~/.config/git/profiles/nazwa-profilu` dodaj:

```ini
# 🔐 Git Credential Manager Configuration  
[credential]
    helper = /usr/local/bin/git-credential-manager

[credential "https://github.com"]
    provider = github
    helper = /usr/local/bin/git-credential-manager

[credential "https://gitlab.com"]
    provider = gitlab
    helper = /usr/local/bin/git-credential-manager

[credential "https://bitbucket.org"]
    provider = bitbucket
    helper = /usr/local/bin/git-credential-manager
```

---

## 🧪 Test konfiguracji

```bash
# Przejdź do katalogu z profilem (np. personal)
cd ~/repositories/personal/jakis-projekt

# Test z prywatnym repo
git clone https://github.com/twoja-nazwa/private-repo.git

# GCM powinien:
# 1. Otworzyć przeglądarkę
# 2. Poprosić o OAuth login  
# 3. Zapisać token automatycznie
```

---

## 🔧 Przydatne komendy

```bash
# Sprawdź status autoryzacji
git-credential-manager status

# Wyloguj ze wszystkich serwisów  
git-credential-manager logout

# Usuń zapisane tokeny
git-credential-manager erase

# Sprawdź wersję
git-credential-manager --version

# Test działania w aktualnym katalogu
git ls-remote
```

---

## 🐛 Troubleshooting

### Problem: Przeglądarka nie otwiera się

```bash
# Ustaw przeglądarkę dla WSL
export BROWSER="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"

# Dodaj do ~/.bashrc dla stałości
echo 'export BROWSER="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"' >> ~/.bashrc
```

### Problem: "Permission denied" mimo autoryzacji

```bash
# Wymuś nową autoryzację
git-credential-manager erase
git clone https://github.com/user/repo.git
```

### Problem: GCM nie został znaleziony

```bash
# Sprawdź instalację
which git-credential-manager

# Zaktualizuj ścieżkę w profilach jeśli różni się od /usr/local/bin/git-credential-manager
```

---

## 📁 Struktura plików po instalacji

```
~/.config/git/profiles/
├── personal              # ← GCM dodany
├── work                 # ← GCM dodany  
└── client               # ← GCM dodany

~/.gcm/                  # ← Przechowywanie tokenów GCM
```

---

## 💡 Wskazówki pro

1. **Różne profile = różne tokeny**: GCM automatycznie zarządza tokenami per profil
2. **OAuth > Personal Access Tokens**: Używaj OAuth flow gdy możliwe  
3. **2FA support**: GCM obsługuje two-factor authentication
4. **Enterprise**: Działa z GitHub Enterprise, GitLab Enterprise, Azure DevOps

---

**🚀 Gotowe!** Teraz masz profesjonalne zarządzanie tokenami Git w WSL bez instalacji czegokolwiek na Windows!

*Dokumentacja: [git-credential-manager-wsl.md](git-credential-manager-wsl.md)*