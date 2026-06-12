# Nouvelle Terre — Contexte Modpack

Briefing pour Claude. Documente l'état du projet pour reprendre n'importe quand.

## Repos

| Repo | URL | Local |
|------|-----|-------|
| Pack | `https://github.com/0Sacha/Nouvelle-Terre-SMP---Pack` | `c:\Users\sacha\Documents\dev\Nouvelle-Terre-SMP---Pack` |
| Mod | `https://github.com/0Sacha/Nouvelle-Terre-SMP---MOD` | `c:\Users\sacha\Documents\dev\Nouvelle-Terre-SMP---MOD` |
| Site | `https://github.com/0Sacha/Nouvelle-Terre-SMP` | `https://nouvelle-terre.notdefined.studio` |
| Bot Discord | `https://github.com/0Sacha/Nouvelle-Terre-SMP---Discord-BOT` | Railway (Node.js) |

## Infrastructure

- **Serveur Minecraft** : `play.notdefined.studio` (DNS SRV → `91.197.6.86:24314`, Minestrator)
- **Pack hébergé** : `https://pack.nouvelle-terre.notdefined.studio/pack.toml` (Cloudflare Pages)
- **Bot Discord** : user `Nouvelle Terre#9576`, Guild ID `1508123190797406432`
- **Fabric Loader** : `0.19.2`, **Minecraft** : `1.20.1`

## Stack technique

- **packwiz** + **Cloudflare Pages** + **Prism Launcher**
- Les joueurs importent `Nouvelle Terre.zip` (instance Prism pré-configurée) depuis les releases GitHub
- Pre-launch Prism : `"$INST_JAVA" -jar "$INST_MC_DIR/packwiz-installer-bootstrap.jar" https://pack.nouvelle-terre.notdefined.studio/pack.toml`
- ⚠️ `OverrideCommands=true` obligatoire dans `instance.cfg` sinon Prism ignore la commande
- Mises à jour automatiques à chaque lancement

## Pipeline CI/CD (100% automatique)

Push sur repo MOD → GitHub Actions :
1. Compile le JAR
2. Crée la release GitHub
3. Upload le JAR sur le serveur via **SFTP** (`7017.mystrator.com:2022`, user `yellox605.30551e80`, dossier `/mods`)
4. Redémarre le serveur via **RCON** (port `40539`) avec `/stop` → Minestrator redémarre auto
5. Envoie `repository_dispatch` `mod-released` → repo Pack se met à jour automatiquement
6. Cloudflare déploie → joueurs mis à jour au prochain lancement

## Secrets GitHub

| Secret | Repos | Usage |
|--------|-------|-------|
| `CLOUDFLARE_API_TOKEN` | Pack | Déploiement Cloudflare Pages |
| `PACK_UPDATE_TOKEN` | MOD + Pack | Cross-repo dispatch + commit |
| `SFTP_PASSWORD` | MOD | Upload JAR sur serveur |
| `RCON_PASSWORD` | MOD | Redémarrage serveur |

## Outils locaux

- **packwiz** : `$env:USERPROFILE\go\bin\packwiz.exe` (⚠️ le stub Windows Store est invalide)
- **Go** : installé via winget
- **wrangler** : `npx wrangler` (authentifié OAuth Cloudflare)

## Pièges connus

- **Fins de ligne** : les `.pw.toml` doivent être en **LF** (pas CRLF). `core.autocrlf=true` sur Windows peut corrompre les hashes. Toujours committer avec `git -c core.autocrlf=false add` ou vérifier que `.gitattributes` force bien LF.
- **`.packwizignore`** : indispensable pour que packwiz n'indexe pas tout le repo (`.github/`, `docs/`, etc.). Seuls les `mods/*.pw.toml` doivent être dans `index.toml`.
- **`packwiz refresh`** : à relancer après tout ajout/modification de mod, sinon les hashes dans `index.toml` sont désynchronisés → erreurs côté client.

## Mise à jour mods Modrinth (manuelle)

```powershell
cd "c:\Users\sacha\Documents\dev\Nouvelle-Terre-SMP---Pack"
& "$env:USERPROFILE\go\bin\packwiz.exe" update --all
& "$env:USERPROFILE\go\bin\packwiz.exe" refresh
git -c core.autocrlf=false add mods/ index.toml pack.toml
git commit -m "chore: update mods"
git push
```

## Structure du repo Pack

```
pack.toml                        ← config packwiz (servi par Cloudflare)
index.toml                       ← index auto-généré par packwiz (LF uniquement)
.packwizignore                   ← exclut tout sauf mods/ de l'index
.gitattributes                   ← force LF pour tous les fichiers texte
_headers                         ← CORS Cloudflare Pages
mods/                            ← références mods (.pw.toml)
instance/
  instance.cfg                   ← config Prism (OverrideCommands=true + pre-launch)
  mmc-pack.json                  ← versions Fabric/Minecraft pour Prism
  servers.dat                    ← serveur play.notdefined.studio pré-configuré
scripts/
  update-bridge.ps1              ← mise à jour manuelle nouvelle-terre-bridge
.github/workflows/
  deploy.yml                     ← déploiement Cloudflare sur push
  auto-update.yml                ← écoute mod-released, met à jour le pack
  release.yml                    ← génère Nouvelle Terre.zip (instance Prism)
docs/
  CONTEXT.md                     ← ce fichier
README.md                        ← guide installation joueurs (mentionne 8 Go RAM)
```
