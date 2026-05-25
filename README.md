# LTBridge

[![npm version](https://img.shields.io/npm/v/@laot/bridge?style=flat&colorA=18181B&colorB=28CF8D&logo=npm)](https://www.npmjs.com/package/@laot/bridge)
[![npm downloads](https://img.shields.io/npm/dt/@laot/bridge?style=flat&colorA=18181B&colorB=28CF8D&logo=npm)](https://www.npmjs.com/package/@laot/bridge)
[![GitHub Release Date](https://img.shields.io/github/release-date/laot7490/ltbridge?style=flat&colorA=18181B&colorB=a855f7)](https://github.com/laot7490/ltbridge/releases)
[![GitHub contributors](https://img.shields.io/github/contributors/laot7490/ltbridge?style=flat&colorA=18181B&colorB=f59e0b)](https://github.com/laot7490/ltbridge/graphs/contributors)
[![GitHub License](https://img.shields.io/github/license/laot7490/ltbridge?style=flat&colorA=18181B&colorB=white)](https://github.com/laot7490/ltbridge/blob/main/LICENSE)

A next-generation **FiveM Script Bridge & Module Manager** designed to be incredibly fast, clean, and bloat-free.

Unlike traditional monolithic libraries that force every script to load hundreds of unused functions into memory, **LTBridge** acts as a smart build tool. It lets you maintain a central repository of your favorite utilities (like Inventory, Framework, Notify) and compiles **only the exact code you actually use** right into your FiveM resource. 

By eliminating slow cross-resource exports and memory bloat, LTBridge helps you build highly independent, lightning-fast scripts with a perfect development experience.

## ✨ Why LTBridge?

- **AOT Compilation:** Our Ahead-of-Time compiler bundles everything in under ~200 milliseconds, meaning zero waiting.
- **Instant Intellisense:** Generates an `api.lua` stub file automatically. You get full autocomplete for everything as you type (`LT.Inventory.AddItem`).
- **Smart Dependencies:** If a module needs another module, LTBridge automatically brings it in. No more missing functions.
- **Live Watcher:** Just run `ltbridge build -w` and start coding. It detects what you type, bundles the necessary modules instantly, and updates your `fxmanifest.lua` on the fly.

## 📦 Installation

Install the CLI tool globally using npm:

```bash
npm install -g @laot/bridge
```

Or run it directly via npx:

```bash
npx @laot/bridge [command]
```

## 🚀 Quick Start

1. **Initialize** your project:
   ```bash
   ltbridge init
   ```
   *Follow the quick prompts to set up your preferences.*

2. **Start the Watcher**:
   ```bash
   ltbridge build -w
   ```
   *The watcher will run silently in the background and do all the heavy lifting.*

3. **Just Code**:
   Use it in your script immediately. Everything else is automatic.
   ```lua
   local name, lastname = LT.Framework.GetPlayerName()
   ```

## ⚙️ Configuration (`ltbridge/ltbridge.config.json`)

When you run `init`, LTBridge creates a simple JSON config.

| Setting | Default | Description |
| --- | --- | --- |
| `buildAsBundle`| `false` (non-interactive `init`) / prompt on interactive `init` | Combine everything into 3 clean files (`shared`, `client`, `server`). Set to `true` for bundle mode. |
| `debug` | `false` | Turn this on if you want to see internal debug prints from the modules. |
| `minify` | `true` | Enables code optimization and global variable randomization for maximum performance. |
| `modules` | `[]` | List of installed modules. The tool manages this automatically! |

## 🛠️ Commands

| Command | Alias | Description |
| --- | --- | --- |
| `ltbridge` | - | **Interactive Menu**: Manage your modules visually. |
| `ltbridge init` | - | Set up LTBridge in a new project (runs an initial build unless `--no-build`). |
| `ltbridge api` | - | Regenerate `ltbridge/api.lua` IDE stubs only. |
| `ltbridge build` | `sync` | Build the project manually (use `-w` for live auto-build). |
| `ltbridge add <name>` | - | Add a specific module manually (e.g., `Target/*`). |
| `ltbridge remove <name>`| - | Remove a module. |
| `ltbridge why <name>` | `explain` | See exactly why a module was automatically included. |
| `ltbridge list` | - | View installed and available modules. |
| `ltbridge prune` | - | Clean up unused modules from your code. |

## 🤝 Contributing

Got a cool function or utility? We'd love to have it! The system is designed so anyone can easily add new modules without touching complex configs.

1. **Fork** the repository.
2. **Create a folder** in `modules/` (e.g., `modules/@MyCategory/MyFunction`).
3. **Write your code**:
   - Put your code in `client.lua`, `server.lua`, or `shared.lua`.
   - Write standard EmmyLua comments (`--- @param`, `--- @return`) for intellisense.
4. **Submit a Pull Request**: We will review and merge it.

### 🧠 Smart Annotations (`@ltbridge`)

If you are developing modules, you can use special comments to tell the compiler what to do. The compiler reads these, applies them, and then completely deletes the comments from the final build.

- `--- @ltbridge export: CustomName` - Change the exported name of the function.
- `--- @ltbridge alias: AnotherName` - Create an alternative name for the same function.
- `--- @ltbridge global` - Expose the function directly to the root `LT` object (e.g., `LT.SetResource`).
- `--- @ltbridge internal` - Marks the module as a "Ghost Module". It runs silently in the background when needed, but doesn't show up in the API or menus.

## 🙏 Credits

A huge thanks to the **[community_bridge](https://github.com/TheOrderFivem)** project for the inspiration behind some core concepts, and **[luamin.js](https://github.com/Herrtt/luamin.js/)** for the minification engine.

---
> **💡 Tip:** To stop your IDE from trying to read the bundled output files (which can cause duplicate intellisense warnings), add this to your VSCode settings (`.vscode/settings.json`):
> ```json
> "Lua.workspace.ignoreDir": ["**/ltbridge/modules/**"]
> ```
