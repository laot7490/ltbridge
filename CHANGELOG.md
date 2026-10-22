### CLI / Watcher

- **Fixed:** Watch mode no longer drops file-change events while a rebuild is running.
- **Changed:** Watch mode is add-only — unused modules are no longer removed automatically; use `ltbridge prune` or `ltbridge remove`.
- **Improved:** `LT.*` scanning ignores Lua comments and string literals (fewer false-positive module adds).
- **Fixed:** Module dependency analysis no longer re-seeds from previous `module.json` deps (sticky false dependencies).

### `@Helpers`

- **Improved:** `DetectResource` prefers `started` resources, sorts candidates for a stable pick, and falls back to present (`~= missing`) with a warning.

### `@Framework`

- **Fixed:** `SetPlayerJob` now accepts grade `0` (was rejected by a truthy grade check).

### `@Inventory`

- **Fixed:** qb-inventory `GetPlayerInventory` reads `PlayerData.items` (was `item`).
- **Fixed:** tgiann `GetItemInfo` reads fields from the item entry instead of the full item list.
- **Added:** `OpenInventory(source, invType, data?)` — server.
- **Added:** `RegisterStash(id, label, slots, maxWeight, owner?)` — server.

### `@Fuel`

- **Fixed:** ox_fuel `SetFuel` assigns an absolute fuel level (was incorrectly adding to the current level).

### `@Callback`

- **Fixed:** Pending callback handler is registered before the net trigger (race on fast responses).

### `@Logger`

- **Fixed:** `Init('txt')` no longer crashes when `data` is nil; default folder is always applied.

### `@Dispatch`

- **Fixed:** Nil-safe `blipData` / `jobs` / `coords` on cd, tk, qs, emergencydispatch, and wasabi adapters.

### `@Phone`

- **Added:** Support for `yseries` (`GetNumber` / `SendMail`).

**Full Changelog**: https://github.com/laot7490/ltbridge/compare/v1.3.6...v1.3.7
