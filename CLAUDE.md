# Nouvelle Terre SMP — Pack

Repo packwiz du modpack Nouvelle Terre. Contient les fichiers `.pw.toml` de tous les mods et la configuration packwiz.

## Infrastructure

- **Serveur Minecraft** : `play.notdefined.studio` (DNS SRV → `91.197.6.86:24314`)
- Ce repo n'est plus déployé nulle part automatiquement : il sert uniquement de source de vérité packwiz (fichiers `.pw.toml`) à partir de laquelle le `.mrpack` est exporté et publié à la main sur Modrinth.

## Pipeline CI/CD

Ce repo est la deuxième étape du pipeline automatique (mise à jour du repo uniquement, plus aucun déploiement en aval) :

1. Push sur repo MOD (`0Sacha/Nouvelle-Terre-SMP---MOD`) → compile JAR → upload SFTP → redémarre serveur
2. Le repo MOD envoie un `repository_dispatch` `mod-released` à **ce repo**
3. GitHub Actions (`.github/workflows/auto-update.yml`) met à jour `nouvelle-terre-bridge.pw.toml` + `packwiz refresh` + commit + push

La publication sur Modrinth est **manuelle** (l'ancien workflow automatique poussait des versions que Modrinth rejetait, et le lien packwiz direct n'est utilisé par aucun joueur — 100% des joueurs passent par l'app Modrinth).

## Distribution joueurs

- **Modrinth** : `https://modrinth.com/project/V9xFVxMk`
- Publication manuelle : `packwiz modrinth export` puis upload du `.mrpack` généré sur la page Modrinth du projet

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

### Publier sur Modrinth (manuel)

```powershell
& "$env:USERPROFILE\go\bin\packwiz.exe" modrinth export
```

Puis uploader le `.mrpack` généré à la main sur `https://modrinth.com/project/V9xFVxMk/versions`.

## Outils requis

- **Go** : installer via `winget install GoLang.Go`
- **packwiz** : `go install github.com/packwiz/packwiz@latest` — toujours appeler `$env:USERPROFILE\go\bin\packwiz.exe` (le stub Windows Store dans `AppData\Local\Microsoft\WindowsApps\` est invalide)

## Secrets GitHub nécessaires

- `PACK_UPDATE_TOKEN` — PAT GitHub (scope `repo`) pour recevoir le `repository_dispatch` du repo MOD

## Repos liés

- Mod : `https://github.com/0Sacha/Nouvelle-Terre-SMP---MOD`
- Site : `https://github.com/0Sacha/Nouvelle-Terre-SMP`
- Bot Discord : `https://github.com/0Sacha/Nouvelle-Terre-SMP---Discord-BOT`
