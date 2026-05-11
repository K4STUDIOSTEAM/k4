# k4_police_system

A standalone police system resource for FiveM.

## Features

- Duty toggle for officers (`/duty`)
- Cuff and uncuff nearby players (`/cuff`, `/uncuff`)
- Escort cuffed players (`/escort`)
- Place/remove cuffed players in vehicles (`/putinveh`, `/removefromveh`)
- Basic search placeholder (`/search`)
- Fine and jail flow (`/fine`, `/jail`, `/unjail`)
- 911 calls with police dispatch blips (`/911`)

## Commands

- `/duty`
- `/cuff`
- `/uncuff`
- `/escort`
- `/putinveh`
- `/removefromveh`
- `/search`
- `/fine [amount] [reason]`
- `/jail [minutes] [reason]`
- `/unjail [serverId]`
- `/911 [message]`

## Install

1. Place `simple_fivem_script` in your server `resources` directory.
2. Add this line to `server.cfg`:

```cfg
ensure simple_fivem_script
```

3. Start/restart your server.

## Permissions setup

Use ACE in `server.cfg` (recommended):

```cfg
add_ace group.admin police.use allow
add_principal identifier.license:YOUR_LICENSE_HERE group.admin
```

Or whitelist specific identifiers in `config.lua` using `Config.PoliceIdentifiers`.

## Configuration

Edit `config.lua` to customize:

- `Config.InteractDistance`
- `Config.MaxFineAmount`
- `Config.MaxJailMinutes`
- `Config.JailSpawnPosition`
- `Config.JailReleasePosition`
- `Config.DispatchBlipDurationMs`

## Notes

- This is standalone and does not withdraw money by default.
- Add economy/framework hooks in `server.lua` where marked.

## GitHub quick start

From this folder:

```bash
git init
git add .
git commit -m "Add standalone police system"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```
