<div align="center">

<picture>
  <source
    srcset="logos/ltbridge-white.png"
    media="(prefers-color-scheme: dark)"
  />
  <source
    srcset="logos/ltbridge-dark.png"
    media="(prefers-color-scheme: light), (prefers-color-scheme: no-preference)"
  />
  <img src="logos/ltbridge-dark.png" height="128" />
</picture>

A simpler way to use framework and resource APIs in your FiveM scripts.

[![npm version](https://img.shields.io/npm/v/@laot/bridge?style=flat-square&color=blue&logo=npm)](https://www.npmjs.com/package/@laot/bridge)
[![npm downloads](https://img.shields.io/npm/dt/@laot/bridge?style=flat-square&color=emerald&logo=npm)](https://www.npmjs.com/package/@laot/bridge)
[![Documentation](https://img.shields.io/badge/docs-GitBook-orange?style=flat-square&logo=gitbook&logoColor=white)](https://laot7490.gitbook.io/ltbridge)
![GitHub Stars](https://img.shields.io/github/stars/laot7490/LTBridge?style=flat-square&logo=github&color=eab308)

[Quick Start](https://laot7490.gitbook.io/ltbridge/getting-started/quick-start) · [Documentation](https://laot7490.gitbook.io/ltbridge) · [Report an issue](https://github.com/laot7490/ltbridge/issues)

</div>

## Get started

Install the CLI, then run it from your resource folder (the folder containing `fxmanifest.lua`):

```bash
npm install -g @laot/bridge
```

```bash
# Init LTBridge
ltbridge init

# Start the watcher
ltbridge build -w
```

The setup wizard creates the project configuration and builds the initial files. Keep the watcher running as you work. It detects LTBridge calls in your Lua scripts and updates the generated files when needed.

For a detailed walkthrough, see the [Quick Start](https://laot7490.gitbook.io/ltbridge/getting-started/quick-start).

## Example

Call an API from your Lua script:

```lua
local firstname, lastname = LT.Framework.GetPlayerName()
LT.Notify.Send('Welcome', 'Hello ' .. firstname .. ' ' .. lastname, 'success')
```

LTBridge detects the calls and includes the required modules in your resource. The same API can work across supported frameworks and resources.

## Commands

Run commands from the resource folder:

| Command                  | Description                                                                     |
| ------------------------ | ------------------------------------------------------------------------------- |
| `ltbridge init`          | Set up LTBridge and create the project configuration                            |
| `ltbridge build`         | Rebuild the resource files and API stubs from the current configuration         |
| `ltbridge build -w`      | Keep watching Lua scripts and rebuild when LTBridge calls change                |
| `ltbridge add <name>`    | Add a module to the project, such as `Notify` or `Target/*`                     |
| `ltbridge remove <name>` | Remove a module from the project                                                |
| `ltbridge list`          | Opens interactive module selection menu                                         |
| `ltbridge prune`         | Scan scripts and remove configured modules that are no longer used              |
| `ltbridge why <name>`    | Explain whether a module is included directly or as another module's dependency |
| `ltbridge api`           | Regenerate Lua API stubs for editor autocomplete                                |

For command options and aliases, see [CLI Commands](https://laot7490.gitbook.io/ltbridge/cli/commands). For setup and configuration details, see the [documentation](https://laot7490.gitbook.io/ltbridge).

## Integrations

Use a common API for framework data, inventory, targets, notifications, menus, input, progress bars, fuel, vehicle keys, dispatch, and phone integrations.

Browse [supported resources](https://laot7490.gitbook.io/ltbridge/how-it-works/supported-resources) and the [module index](https://laot7490.gitbook.io/ltbridge/module-reference/module-index).

## Documentation

Read the [LTBridge documentation](https://laot7490.gitbook.io/ltbridge) for installation, configuration, IDE setup, and troubleshooting.

## Use with AI

This repository includes an [LTBridge skill](skill/ltbridge/SKILL.md) for AI coding assistants. Copy the `skill/ltbridge` folder into your assistant's skills directory to use it.

## Credits

Thanks to [community_bridge](https://github.com/TheOrderFivem) for some of the ideas behind LTBridge, and to [luamin.js](https://github.com/Herrtt/luamin.js) for the minifier.

## License

LTBridge is available under the [MIT License](LICENSE).

<sub>LTBridge is not affiliated with, endorsed by, or sponsored by FiveM, Cfx.re, or Rockstar Games.</sub>