# LTBridge

[![npm version](https://img.shields.io/npm/v/@laot/bridge?style=flat&colorA=18181B&colorB=28CF8D&logo=npm)](https://www.npmjs.com/package/@laot/bridge)
[![npm downloads](https://img.shields.io/npm/dt/@laot/bridge?style=flat&colorA=18181B&colorB=28CF8D&logo=npm)](https://www.npmjs.com/package/@laot/bridge)
[![GitHub Release Date](https://img.shields.io/github/release-date/laot7490/ltbridge?style=flat&colorA=18181B&colorB=a855f7)](https://github.com/laot7490/ltbridge/releases)
[![GitHub contributors](https://img.shields.io/github/contributors/laot7490/ltbridge?style=flat&colorA=18181B&colorB=f59e0b)](https://github.com/laot7490/ltbridge/graphs/contributors)
[![GitHub License](https://img.shields.io/github/license/laot7490/ltbridge?style=flat&colorA=18181B&colorB=white)](https://github.com/laot7490/ltbridge/blob/main/LICENSE)
[![Documentation](https://img.shields.io/badge/docs-GitBook-3884FF?style=flat&logo=gitbook&logoColor=white&colorA=18181B)](https://laot7490.gitbook.io/ltbridge)

LTBridge is a command-line tool for FiveM scripts. You call `LT.*` in a resource, and it copies only the modules those calls need into that resource. It is not a server resource you `ensure`.

[Overview](#overview) · [Getting started](#getting-started) · [Commands](#commands) · [Docs](#docs)

## Overview

A shared library loads every helper into each script, including functions the script never calls. LTBridge copies in only the modules behind the `LT.*` calls you write. While you code, the watcher also pulls in anything those modules need and updates `fxmanifest.lua`.

A longer explanation is in [What is LTBridge?](https://laot7490.gitbook.io/ltbridge/how-it-works/what-is-ltbridge).

## What it covers

The same calls work with the framework and resources already running on your server. LTBridge detects which one is started and uses it.

- **Framework** — player data, jobs, and money on ESX, QBCore, and QBX
- **Inventory** — add, remove, and check items
- **Target** — zones and entity options
- **Interface** — notify, menus, input, and progress bars
- **World** — fuel, vehicle keys, dispatch, and phone

See [Supported Resources](https://laot7490.gitbook.io/ltbridge/how-it-works/supported-resources) and the [Module Index](https://laot7490.gitbook.io/ltbridge/module-reference/module-index).

## Getting started

You need [Node.js](https://nodejs.org/) 18 or newer. From the resource folder (the one with `fxmanifest.lua`):

```bash
npm install -g @laot/bridge
ltbridge init
ltbridge build -w
```

`ltbridge init` asks a few questions and creates `ltbridge/config.json`. Leave the watcher running, then write your script:

```lua
local firstname, lastname = LT.Framework.GetPlayerName()
LT.Notify.Send('Welcome', 'Hello ' .. firstname .. ' ' .. lastname, 'success')
```

The watcher sees those calls, adds the modules, and updates the manifest. Build settings live in `ltbridge/config.json`. See [Configuration](https://laot7490.gitbook.io/ltbridge/daily-use/config).

To run a command without installing the CLI, use `npx @laot/bridge`.

The [Quick Start](https://laot7490.gitbook.io/ltbridge/getting-started/quick-start) walks through a first project from an empty resource to a working call.

## Commands

Run these from the resource folder. Flags and aliases are in [CLI Commands](https://laot7490.gitbook.io/ltbridge/cli/commands).

| Command | What it does |
| --- | --- |
| `ltbridge init` | Set up LTBridge in this resource |
| `ltbridge build -w` | Watch your scripts and update the build as you save |
| `ltbridge build` | Rebuild once from the current config |
| `ltbridge add <name>` | Add a module, such as `Notify` or `Target/*` |
| `ltbridge remove <name>` | Remove a module |
| `ltbridge list` | Show installed and available modules |
| `ltbridge prune` | Remove modules your code no longer calls |
| `ltbridge why <name>` | Show why a module is included |
| `ltbridge api` | Regenerate the `ltbridge/api.lua` autocomplete stubs |
| `ltbridge` | Open the module picker |

## Docs

Documentation: [laot7490.gitbook.io/ltbridge](https://laot7490.gitbook.io/ltbridge)

- [Installation](https://laot7490.gitbook.io/ltbridge/getting-started/installation)
- [Quick Start](https://laot7490.gitbook.io/ltbridge/getting-started/quick-start)
- [IDE Setup](https://laot7490.gitbook.io/ltbridge/getting-started/ide-setup)
- [CLI Commands](https://laot7490.gitbook.io/ltbridge/cli/commands)
- [Configuration](https://laot7490.gitbook.io/ltbridge/daily-use/config)
- [Troubleshooting](https://laot7490.gitbook.io/ltbridge/daily-use/troubleshooting)
- [Module Index](https://laot7490.gitbook.io/ltbridge/module-reference/module-index)

`ltbridge init` can add `ltbridge/modules` to the Lua language server ignore list. You can also add it yourself. See [IDE Setup](https://laot7490.gitbook.io/ltbridge/getting-started/ide-setup).

```json
"Lua.workspace.ignoreDir": ["**/ltbridge/modules/**"]
```

## Using it with an AI assistant

This repo ships an agent skill at [`skill/ltbridge`](skill/ltbridge/SKILL.md). Copy that folder into `.cursor/skills`, `.claude/skills`, or `.agents/skills`.

## Credits

Thanks to [community_bridge](https://github.com/TheOrderFivem) for some of the ideas behind LTBridge, and to [luamin.js](https://github.com/Herrtt/luamin.js) for the minifier.
