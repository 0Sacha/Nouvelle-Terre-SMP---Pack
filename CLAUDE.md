# Nouvelle Terre SMP — Pack

Repo packwiz du modpack Nouvelle Terre. Contient les fichiers `.pw.toml` de tous les mods et la configuration packwiz.

## Infrastructure

- **Hébergement packwiz** : `https://pack.nouvelle-terre.notdefined.studio/pack.toml` (Cloudflare Pages, projet `nouvelle-terre-pack`)
- **Auto-déploiement** : GitHub Actions sur push `main` → Cloudflare Pages (`.github/workflows/deploy.yml`)
- **Serveur Minecraft** : `play.notdefined.studio` (DNS SRV → `91.197.6.86:24314`)

## Pipeline CI/CD

Ce repo est la deuxième étape du pipeline automatique :

1. Push sur repo MOD (`0Sacha/Nouvelle-Terre-SMP---MOD`) → compile JAR → upload SFTP → redémarre serveur
2. Le repo MOD envoie un `repository_dispatch` `mod-released` à **ce repo**
3. GitHub Actions met à jour `nouvelle-terre-bridge.pw.toml` + `packwiz refresh` + commit + push
4. Cloudflare Pages redéploie automatiquement
5. Les joueurs reçoivent la mise à jour au prochain lancement de Prism

## Distribution joueurs

- **Release GitHub** : `https://github.com/0Sacha/Nouvelle-Terre-SMP---Pack/releases/latest`
- Contient `Nouvelle Terre.zip` — instance Prism pré-configurée
- Pre-launch configuré : `"$INST_JAVA" -jar packwiz-installer-bootstrap.jar https://pack.nouvelle-terre.notdefined.studio/pack.toml`
- Les joueurs importent le `.zip` dans Prism → les mods se mettent à jour automatiquement à chaque lancement

## Commandes utiles

### Mettre à jour les mods Modrinth (manuel)

```powershell
& "$env:USERPROFILE\go\bin\packwiz.exe" update --all
& "$env:USERPROFILE\go\bin\packwiz.exe" refresh
git add -A
git commit -m "chore: update mods"
git push
```

### Ajouter un mod

```powershell
& "$env:USERPROFILE\go\bin\packwiz.exe" modrinth add <slug-ou-url>
& "$env:USERPROFILE\go\bin\packwiz.exe" refresh
```

### Supprimer un mod

```powershell
& "$env:USERPROFILE\go\bin\packwiz.exe" remove <nom-du-mod>
& "$env:USERPROFILE\go\bin\packwiz.exe" refresh
```

## Outils requis

- **Go** : installer via `winget install GoLang.Go`
- **packwiz** : `go install github.com/packwiz/packwiz@latest` — toujours appeler `$env:USERPROFILE\go\bin\packwiz.exe` (le stub Windows Store dans `AppData\Local\Microsoft\WindowsApps\` est invalide)
- **wrangler** : `npx wrangler` (s'authentifier via `npx wrangler login`)

## Secrets GitHub nécessaires

- `CLOUDFLARE_API_TOKEN` — deploy Cloudflare Pages
- `PACK_UPDATE_TOKEN` — PAT GitHub (scope `repo`) pour recevoir le `repository_dispatch` du repo MOD

## Repos liés

- Mod : `https://github.com/0Sacha/Nouvelle-Terre-SMP---MOD`
- Site : `https://github.com/0Sacha/Nouvelle-Terre-SMP`
- Bot Discord : `https://github.com/0Sacha/Nouvelle-Terre-SMP---Discord-BOT`
