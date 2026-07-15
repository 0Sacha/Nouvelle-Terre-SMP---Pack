# Nouvelle Terre SMP — Pack

Repo packwiz du modpack Nouvelle Terre. Contient les fichiers `.pw.toml` de tous les mods et la configuration packwiz. C'est la source de vérité de la composition du pack, à partir de laquelle le `.mrpack` publié sur Modrinth est généré.

## Infrastructure

- **Serveur Minecraft** : `play.notdefined.studio` (DNS SRV → `91.197.6.86:24314`)
- **Distribution joueurs** : 100% des joueurs installent/mettent à jour le pack via l'app Modrinth (`https://modrinth.com/app`). Personne n'utilise de lien packwiz direct.
- Ce repo n'est déployé nulle part automatiquement (plus de Cloudflare Pages) : il sert uniquement de source de vérité packwiz, exportée et publiée à la main sur Modrinth.

## Pipeline CI/CD

1. Push sur repo MOD (`0Sacha/Nouvelle-Terre-SMP---MOD`) → compile le JAR → upload SFTP → redémarre le serveur
2. Le repo MOD envoie un `repository_dispatch` `mod-released` à **ce repo**
3. GitHub Actions (`.github/workflows/auto-update.yml`) met à jour `mods/nouvelle-terre-bridge.pw.toml` (nouvelle URL de download + hash) + `packwiz refresh` + commit + push automatique

C'est **le seul workflow automatique restant**. Il n'y a plus de déploiement Cloudflare Pages ni de publication Modrinth automatique (l'ancien workflow `mc-publish` poussait des versions que Modrinth rejetait) — voir `.github/workflows/` (seul `auto-update.yml` existe).

**Après un push automatique de `auto-update.yml`**, penser à `git pull` avant de reprendre du travail sur ce repo en local, puis à régénérer et republier le `.mrpack` si une nouvelle version du mod bridge vient de sortir.

## Publier une nouvelle version sur Modrinth (manuel)

1. S'assurer que le repo est à jour (`git pull`) et que les mods voulus sont ajoutés/à jour
2. Bump `pack.toml` → champ `version` : incrémenter le numéro `1.0.x` (ex: `1.0.74` → `1.0.75`). **Ne jamais repartir à `0.1.0`** — l'ancien CI publiait déjà des versions `1.0.$run_number` sur Modrinth (dernière automatique : `1.0.72`), donc une version plus basse apparaîtrait comme un downgrade dans la liste des versions Modrinth
3. `packwiz refresh` puis `packwiz modrinth export` → génère `Nouvelle Terre-<version>.mrpack` à la racine du repo (déjà dans `.gitignore`), et supprimer le `.mrpack` de la version précédente (ne garder que le dernier export en local)
4. Uploader ce fichier à la main sur `https://modrinth.com/project/V9xFVxMk/versions` (alias `https://modrinth.com/modpack/nouvelle-terre-mod`), en tapant le même numéro de version dans le formulaire
5. Rédiger le changelog en **français puis anglais**, à la suite dans le même champ (voir style plus bas)
6. **Toujours** committer et pousser (`git push`) le bump de version et les changements de mods sur Git — ne jamais laisser ces changements en attente localement, même avant l'upload manuel sur Modrinth

**Délai de propagation** : une fois publiée, la nouvelle version peut mettre **jusqu'à ~30 minutes** à apparaître comme mise à jour disponible dans l'app Modrinth des joueurs — ce n'est pas instantané, prévenir en conséquence si besoin.

### Style de changelog

Toujours écrire deux blocs à la suite : français d'abord, anglais ensuite. Puces courtes groupées sous un titre en gras (ex: `🔧 Correctif` / `🔧 Fix`, `✨ Nouveauté` / `✨ New`). Pour les changelogs de `nouvelle-terre-bridge`, le vrai contenu se trouve dans le message de commit du repo MOD (`gh api repos/0Sacha/Nouvelle-Terre-SMP---MOD/commits/<sha>`), pas dans les notes de release GitHub (auto-générées, sans substance).

## ⚠️ Contrainte de compatibilité WaterMedia

**Rester sur la branche `2.x` de WaterMedia (`watermedia.pw.toml`), jamais `3.x`.**

WaterFrames (dernière release Fabric 1.20.1 : `v2.1.22`, oct. 2025) et WaterVision (dernière release Fabric 1.20.1 : `v0.1.0-alpha`, sept. 2025) sont construits contre l'API WaterMedia 2.x. WaterMedia 3.x (depuis ~janvier 2026) a refactorisé son API/ses packages, et aucun des deux mods compagnons n'a de build Fabric 1.20.1 compatible v3. Combo confirmé fonctionnel : **WaterMedia `2.1.37`** + WaterFrames `2.1.22` + WaterVision `v0.1.0-alpha`, sans jar "binaries" ni "yt-plugin" séparé.

Symptôme si on upgrade par erreur vers WaterMedia 3.x : crash au lancement (`NoClassDefFoundError` sur une classe `org.watermedia.*`).

Pour épingler une version précise d'un mod (ex: éviter que `packwiz modrinth add` prenne la dernière version) :
```powershell
& "$env:USERPROFILE\go\bin\packwiz.exe" modrinth add --project-id <project-id> --version-id <version-id> -y
```
⚠️ La résolution automatique des dépendances de packwiz peut ajouter une dépendance "required" d'une branche majeure différente (ex: elle a ajouté `WATERMeDIA: Youtube Extension 3.0.0-beta.7` en épinglant WaterMedia à `2.1.37`). Toujours vérifier `mods/` après un ajout épinglé et `packwiz remove` ce qui ne correspond pas.

## Commandes utiles

Toujours appeler `packwiz` via son chemin complet : `$env:USERPROFILE\go\bin\packwiz.exe` en PowerShell, ou `"$USERPROFILE/go/bin/packwiz.exe"` en bash/Git Bash (sans l'opérateur `&`, qui est spécifique à PowerShell).

### Mettre à jour tous les mods

```powershell
& "$env:USERPROFILE\go\bin\packwiz.exe" update --all
& "$env:USERPROFILE\go\bin\packwiz.exe" refresh
```
⚠️ Vérifier `mods/watermedia.pw.toml` après un `update --all` — voir contrainte WaterMedia ci-dessus.

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

### Exporter le `.mrpack`

```powershell
& "$env:USERPROFILE\go\bin\packwiz.exe" modrinth export
```

## Outils requis

- **Go** : installer via `winget install GoLang.Go`
- **packwiz** : `go install github.com/packwiz/packwiz@latest` — toujours appeler `$env:USERPROFILE\go\bin\packwiz.exe` (le stub Windows Store dans `AppData\Local\Microsoft\WindowsApps\` est invalide)

## Secrets GitHub nécessaires

- `PACK_UPDATE_TOKEN` — PAT GitHub (scope `repo`) pour recevoir le `repository_dispatch` du repo MOD (utilisé par `auto-update.yml`)

## Repos liés

- Mod : `https://github.com/0Sacha/Nouvelle-Terre-SMP---MOD`
- Site : `https://github.com/0Sacha/Nouvelle-Terre-SMP`
- Bot Discord : `https://github.com/0Sacha/Nouvelle-Terre-SMP---Discord-BOT`
