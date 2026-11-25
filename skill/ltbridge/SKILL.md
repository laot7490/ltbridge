---
name: ltbridge
description: >-
  Work with LTBridge in FiveM resources: use LT.* APIs from ltbridge/api.lua,
  respect CLIENT/SERVER/SHARED stubs, avoid duplicate utilities and direct
  framework/inventory/ox calls, and manage it with the @laot/bridge CLI (global
  install or npx). Use when a resource has an ltbridge/ folder, api.lua,
  ltbridge/config.json, or uses the LT namespace.
---

# LTBridge

LTBridge is a build tool, not a dependency resource. The CLI compiles only the modules a resource uses into `ltbridge/modules/` and updates the resource manifest.

## When this applies

Any of these:

1. The resource has an `ltbridge/` folder (`ltbridge/config.json`, `ltbridge/api.lua`).
2. `fxmanifest.lua` or `__resource.lua` loads `ltbridge/modules/*.lua`.
3. Code uses the `LT.` namespace.

If none match, don't assume LTBridge.

## CLI installation

LTBridge is the `@laot/bridge` npm package, requires Node.js 22.14.0 or later, and can be installed globally or run with `npx`.

```bash
npm install -g @laot/bridge     # recommended
ltbridge --version
npx @laot/bridge <command>      # without a global install
```

- Use the global `ltbridge` command when installed; prefix commands with `npx @laot/bridge` otherwise.
- Never add `@laot/bridge` as a project dependency. Never create a `package.json`, lockfile or npm scripts inside a FiveM resource for LTBridge.
- Run every command from the resource root (the folder with `fxmanifest.lua` or `__resource.lua`).

## Documentation and API lookup

Use the [LTBridge documentation](https://laot7490.gitbook.io/ltbridge) for current setup and behavior. Read the relevant page for [quick start](https://laot7490.gitbook.io/ltbridge/getting-started/quick-start), [commands](https://laot7490.gitbook.io/ltbridge/daily-use/commands), [configuration](https://laot7490.gitbook.io/ltbridge/daily-use/config), [IDE setup](https://laot7490.gitbook.io/ltbridge/getting-started/ide-setup), [supported resources](https://laot7490.gitbook.io/ltbridge/how-it-works/supported-resources), or the [module index](https://laot7490.gitbook.io/ltbridge/module-reference/modules). For exact signatures and side-specific availability in a resource, use that resource's generated `ltbridge/api.lua`, which matches its installed CLI version.

## Commands

| Command | What it does |
|---------|--------------|
| `ltbridge init` | Interactive setup (build mode, minify, debug, VS Code Lua ignoreDir). Creates `ltbridge/config.json`, `ltbridge/api.lua`, runs first build. |
| `ltbridge build -w` | Watcher. Scans `.lua` files for `LT.*` calls, **adds** missing modules automatically, rebuilds and updates the manifest on save. Does **not** remove unused modules — use `ltbridge prune` for that. |
| `ltbridge build` | One-off rebuild from `config.json`. Aliases: `sync`, `install`, `refresh`. `-d` shows details. Does **not** scan code. |
| `ltbridge add <name>` | Add a module and rebuild. Accepts `Notify`, `Framework/GetPlayerName`, `LT.Notify.Send`, wildcards like `Target/*`. |
| `ltbridge remove <name>` | Remove a module and rebuild. Same name formats. |
| `ltbridge prune` | Remove modules no longer used in code, then rebuild. |
| `ltbridge why <name>` | Show why a module is included (manual or dependency). Alias: `explain`. |
| `ltbridge list` | Interactive picker to select or deselect modules. |
| `ltbridge api` | Regenerate `ltbridge/api.lua` only. |
| `ltbridge` | Interactive module picker. |

### Rules for agents

- `ltbridge init` and bare `ltbridge` are interactive prompts. Ask the user to run them; don't try to drive the prompts.
- `ltbridge build -w` is long-running. If the user already has it running, just write code and let it pick up `LT.*` calls. Never start a second watcher; if you start one, run it in the background.
- No watcher running? After adding new `LT.*` calls run `ltbridge add <name>` for each new module. After removing usages run `ltbridge prune`.
- Plain `ltbridge build` won't pick up new `LT.*` calls on its own.
- The watcher and `prune` detect static `LT.*` references, not dynamic indexing such as `LT.Inventory[method]`. Add dynamically accessed modules explicitly and retain them when pruning.
- Use `ltbridge why <name>` / `ltbridge list` instead of guessing what's installed.

## Generated files (don't edit by hand)

| Path | Notes |
|------|-------|
| `ltbridge/modules/**` | Build output. Never edit; changes are overwritten. |
| `ltbridge/config.json` | `bundle`, `minify`, `debug` can be edited. `modules` and `version` are managed by the CLI. |
| `ltbridge/api.lua` | IDE stubs for **all** available modules, not just installed ones. Never load it in the resource manifest. |

The CLI updates these manifest entries itself, so don't add or remove them manually:

- `shared_scripts` / `client_scripts` / `server_scripts` → `'ltbridge/modules/shared.lua'`, `client.lua`, `server.lua`
- `files` → `'ltbridge/modules/imports/**/*.lua'` (individual build mode)
- `escrow_ignore` → `'ltbridge/**/*.lua'`

Never add `dependency 'ltbridge'`. The bridge is embedded in the resource.

## Finding an API

Use the generated `ltbridge/api.lua` as the source of truth for the resource's installed LTBridge version; use the [module index](https://laot7490.gitbook.io/ltbridge/module-reference/modules) to discover categories and the GitBook module pages for usage details.

1. Figure out the script side: `client/**`, `server/**` or shared.
2. Find a likely module category in the linked module index.
3. Grep `api.lua` for `LT.<Module>.<Method>`.
4. Read the stub: the tag `` **`MODULE` `CLIENT|SERVER|SHARED`** ``, `@param` / `@return`, and the embedded ```` ```lua ```` example.
5. Call it with the documented signature. Prefer the stub example over inventing usage.

If something isn't in `api.lua`, say so. Don't build a local replacement in the consumer script.

### CLIENT / SERVER / SHARED

| Tag | Use in |
|-----|--------|
| `CLIENT` | Client scripts only |
| `SERVER` | Server scripts only |
| `SHARED` | Either side |

- Never call a `SERVER` stub from client code or vice versa.
- Server stubs targeting a player usually take `source` first, e.g. `LT.Notify.Send(source, title, message, variant)`.
- The same method can have two stubs with different tags. Pick the one matching your file.

## Events

Use `LT.Events.Emit`, `LT.Events.EmitNet` and `LT.Events.Register` (see the `EVENTS` stubs) instead of raw `TriggerEvent` / `TriggerServerEvent` / `TriggerClientEvent` / `RegisterNetEvent`. Event names are namespaced per resource automatically.

If the resource defines global aliases once in a shared init file (e.g. `emit = LT.Events.Emit`, `emitNet = LT.Events.EmitNet`, `register = LT.Events.Register`), use those everywhere and don't re-alias per file.

```lua
-- client
LT.Events.EmitNet('buyItem', itemName)

-- server
LT.Events.Register('buyItem', function(itemName)
    local src = source
end)
LT.Events.EmitNet('buyResult', src, true)
```

Supported adapters are detected at runtime. Make sure the relevant framework or provider resource starts before the resource using LTBridge; see [Supported Resources](https://laot7490.gitbook.io/ltbridge/how-it-works/supported-resources) for the current list.

## Don't

- Call framework/inventory/UI resources directly (`exports['qb-core']`, `ESX`, `exports.ox_inventory`, `lib.notify`, `lib.progressBar`, ...) when `LT.*` covers it.
- Write local helpers that duplicate stubs (closest player, notify wrappers, progress helpers, model loaders, ...).
- Add new `LT.*` APIs inside the resource or edit anything under `ltbridge/modules/`.
- Hand-edit the LTBridge manifest entries or add `api.lua` to the manifest.
- Install the CLI per project or add npm tooling to the resource.

## Examples

```lua
-- client
LT.Notify.Send('Title', 'Message', 'success', 5000)

-- server (source first)
LT.Notify.Send(source, 'Title', 'Message', 'error')
LT.Framework.AddMoney(source, 'cash', 100)
```

Avoid:

```lua
local function GetClosestPlayer() ... end  -- use LT.Utils
exports.ox_lib:notify({ ... })            -- use LT.Notify
```

## Checklist

- [ ] LTBridge confirmed (`ltbridge/` folder or `LT.` usage), no `dependency 'ltbridge'`.
- [ ] Every `LT.*` symbol used was checked in `ltbridge/api.lua`.
- [ ] Stub tag (CLIENT / SERVER / SHARED) matches the file side.
- [ ] New modules picked up: watcher running, or `ltbridge add <name>` run.
- [ ] Removed usages cleaned up with `ltbridge prune` (watcher does not auto-remove).
- [ ] No manual edits under `ltbridge/modules/` or to LTBridge manifest entries.
- [ ] No duplicate helpers, no direct third-party calls where `LT.*` exists.
- [ ] CLI run globally or through `npx`; no `package.json` / npm deps added to the resource.
