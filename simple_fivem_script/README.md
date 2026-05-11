# simple_fivem_script

A very small standalone FiveM resource you can drop into your `resources` folder.

## What it does

- `/hello` (client command): prints a chat message locally.
- `/hello_server` (server command): sends a server response back to your chat.

## Install

1. Place `simple_fivem_script` in your server `resources` directory.
2. Add this line to `server.cfg`:

```cfg
ensure simple_fivem_script
```

3. Start/restart your server.

## GitHub quick start

From this folder:

```bash
git init
git add .
git commit -m "Initial FiveM script"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```
