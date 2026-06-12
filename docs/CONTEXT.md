# Nouvelle Terre — Contexte Modpack

Briefing pour Claude. Documente l'état complet du projet pour reprendre n'importe quand.

---

## Repos

| Repo | GitHub | Local |
|------|--------|-------|
| Pack (ce repo) | `https://github.com/0Sacha/Nouvelle-Terre-SMP---Pack` | `c:\Users\sacha\Documents\dev\Nouvelle-Terre-SMP---Pack` |
| Mod Fabric | `https://github.com/0Sacha/Nouvelle-Terre-SMP---MOD` | `c:\Users\sacha\Documents\dev\Nouvelle-Terre-SMP---MOD` |
| Site web | `https://github.com/0Sacha/Nouvelle-Terre-SMP` | `https://nouvelle-terre.notdefined.studio` |
| Bot Discord | `https://github.com/0Sacha/Nouvelle-Terre-SMP---Discord-BOT` | Railway (Node.js) |

---

## Infrastructure

| Composant | Valeur |
|-----------|--------|
| Serveur Minecraft | `play.notdefined.studio` (DNS SRV → `91.197.6.86:24314`) |
| Hébergeur serveur | Minestrator (Pterodactyl), panel `https://minestrator.com/my/server/450659` |
| SFTP serveur | `yellox605.30551e80@7017.mystrator.com:2022`, dossier `/mods` |
| RCON serveur | `91.197.6.86:40539` |
| Pack URL | `https://pack.nouvelle-terre.notdefined.studio/pack.toml` (Cloudflare Pages, projet `nouvelle-terre-pack`) |
| Bot Discord | Guild ID `1508123190797406432`, hébergé sur Railway |
| Minecraft | `1.20.1`, Fabric Loader `0.19.2` |

---

## Pipeline CI/CD (100% automatique)

### Déployer une nouvelle version du mod

Push sur `main` du **repo MOD** → GitHub Actions :

1. Compile le JAR
2. Crée une release GitHub (tag `v{version}`)
3. Upload le JAR sur le serveur via SFTP (remplace l'ancien `nouvelle-terre-bridge-*.jar` dans `/mods`)
4. Notifie Discord (webhook)
5. Envoie `repository_dispatch` `mod-released` → **repo Pack**

Repo Pack reçoit le dispatch → GitHub Actions :

6. Télécharge le JAR depuis la release, calcule son SHA1
7. Met à jour `mods/nouvelle-terre-bridge.pw.toml`
8. `packwiz refresh` → met à jour `index.toml`
9. Commit + push sur `main`
10. Cloudflare Pages redéploie automatiquement

Les joueurs reçoivent la mise à jour au prochain lancement de Prism (fenêtre noire quelques secondes).

### Déployer une mise à jour du pack (mods Modrinth, config, etc.)

Push sur `main` du **repo Pack** → Cloudflare Pages redéploie automatiquement.

### Déclencher manuellement

- Repo MOD → **Actions** → "Compiler & Publier NouvelleTerreBridge" → **Run workflow**
- Repo Pack → **Actions** → "Mise à jour automatique nouvelle-terre-bridge" → **Run workflow**

---

## Distribution joueurs

Les joueurs importent `Nouvelle Terre.zip` depuis `https://github.com/0Sacha/Nouvelle-Terre-SMP---Pack/releases/latest` dans Prism Launcher.

Le ZIP contient :
- `instance.cfg` — config Prism avec la commande pre-launch
- `mmc-pack.json` — versions Minecraft/Fabric pour Prism
- `.minecraft/packwiz-installer-bootstrap.jar` — télécharge les mods au premier lancement
- `.minecraft/servers.dat` — serveur `play.notdefined.studio` pré-configuré dans la liste multijoueur

Pre-launch command configurée dans `instance.cfg` :
```
"$INST_JAVA" -jar "$INST_MC_DIR/packwiz-installer-bootstrap.jar" https://pack.nouvelle-terre.notdefined.studio/pack.toml
```

⚠️ `OverrideCommands=true` est obligatoire dans `instance.cfg` — sans ça Prism ignore la commande pre-launch et aucun mod n'est téléchargé.

---

## Secrets GitHub

| Secret | Repo | Usage |
|--------|------|-------|
| `CLOUDFLARE_API_TOKEN` | Pack | Déploiement Cloudflare Pages |
| `PACK_UPDATE_TOKEN` | Pack + MOD | PAT GitHub (scope `repo`) — cross-repo dispatch et commit |
| `SFTP_PASSWORD` | MOD | Upload JAR sur serveur Minestrator |
| `RCON_PASSWORD` | MOD | Redémarrage serveur via RCON |
| `DISCORD_WEBHOOK` | MOD | Notification Discord à chaque build |
| `WEBHOOK_SECRET` | Bot Discord | Validation des webhooks GitHub entrants (⚠️ ne pas préfixer par `GITHUB_`) |

---

## Outils locaux (Windows)

- **packwiz** : `& "$env:USERPROFILE\go\bin\packwiz.exe"` — ⚠️ le stub `AppData\Local\Microsoft\WindowsApps\packwiz.exe` est invalide, toujours utiliser le chemin complet
- **Go** : installé via `winget install GoLang.Go`, packwiz installé via `go install github.com/packwiz/packwiz@latest`
- **wrangler** : `npx wrangler` (authentifié via `npx wrangler login`)

---

## Pièges connus

### CRLF vs LF (critique)
`core.autocrlf=true` sur Windows fait que packwiz calcule les hashes sur des fichiers CRLF, mais git push en LF et Cloudflare sert du LF → **mismatch de hash côté client** ("Invalid mod file hash", ~56/58 erreurs).

Toujours committer les fichiers packwiz avec :
```powershell
git -c core.autocrlf=false add mods/ index.toml pack.toml
```

Le `.gitattributes` force `eol=lf` pour tous les fichiers texte, mais ne suffit pas seul à cause de `core.autocrlf=true` au checkout.

### `.packwizignore` obligatoire
Sans ce fichier, `packwiz refresh` indexe tout le repo (`.github/`, `docs/`, `instance/`, etc.). L'installeur essaie alors de télécharger ces fichiers depuis Cloudflare et échoue. Seuls les `mods/*.pw.toml` doivent apparaître dans `index.toml`.

### `packwiz refresh` après chaque modification
À relancer systématiquement après tout ajout, suppression ou modification d'un mod, sinon `index.toml` est désynchronisé → erreurs côté client.

### `OverrideCommands=true` dans instance.cfg
Sans ce flag, Prism ignore la `PreLaunchCommand` même si elle est définie dans `instance.cfg`. Le dossier `mods/` reste vide et la connexion au serveur échoue (handshake owo-lib raté car owo-lib absent côté client).

---

## Commandes utiles

### Mettre à jour les mods Modrinth

```powershell
cd "c:\Users\sacha\Documents\dev\Nouvelle-Terre-SMP---Pack"
& "$env:USERPROFILE\go\bin\packwiz.exe" update --all
& "$env:USERPROFILE\go\bin\packwiz.exe" refresh
git -c core.autocrlf=false add mods/ index.toml pack.toml
git commit -m "chore: update mods"
git push
```

### Ajouter un mod

```powershell
& "$env:USERPROFILE\go\bin\packwiz.exe" modrinth add <slug-ou-url>
& "$env:USERPROFILE\go\bin\packwiz.exe" refresh
git -c core.autocrlf=false add mods/ index.toml pack.toml
git commit -m "feat: add <nom-du-mod>"
git push
```

### Supprimer un mod

```powershell
& "$env:USERPROFILE\go\bin\packwiz.exe" remove <nom-du-mod>
& "$env:USERPROFILE\go\bin\packwiz.exe" refresh
git -c core.autocrlf=false add mods/ index.toml pack.toml
git commit -m "chore: remove <nom-du-mod>"
git push
```

---

## Structure du repo Pack

```
pack.toml                        <- config packwiz principale (servi par Cloudflare)
index.toml                       <- index auto-généré (LF uniquement, ne pas éditer)
.packwizignore                   <- exclut tout sauf mods/ de l'indexation packwiz
.gitattributes                   <- force LF pour tous les fichiers texte
_headers                         <- headers CORS pour Cloudflare Pages
mods/                            <- un .pw.toml par mod
  nouvelle-terre-bridge.pw.toml  <- mis à jour automatiquement par auto-update.yml
  restart-server.pw.toml         <- side=server uniquement
  ...
instance/
  instance.cfg                   <- config Prism (OverrideCommands=true + PreLaunchCommand)
  mmc-pack.json                  <- composants Minecraft/Fabric pour Prism
  servers.dat                    <- NBT binaire : serveur play.notdefined.studio pré-ajouté
scripts/
  update-bridge.ps1              <- mise à jour manuelle de nouvelle-terre-bridge
.github/workflows/
  deploy.yml                     <- push main -> Cloudflare Pages
  auto-update.yml                <- reçoit mod-released, met à jour le pack
  release.yml                    <- génère et publie Nouvelle Terre.zip sur chaque push
docs/
  CONTEXT.md                     <- ce fichier
README.md                        <- guide installation joueurs (8 Go RAM requis)
```
