local function deepEqual(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= 'table' then return a == b end
    if a == b then return true end
    
    local keys = {}
    for k, v in pairs(a) do
        keys[k] = true
        if not deepEqual(v, b[k]) then return false end
    end
    for k in pairs(b) do
        if not keys[k] then return false end
    end
    return true
end

--- @class NUIStateRoot
--- @field _internal table
--- @field _proxy table
--- @field _namespace string
--- @field _action string
--- @field _ignore table
--- @field _batch table
--- @field _isTicking boolean

local RootState = {}
RootState.__index = RootState

function RootState:queueUpdate(key, value)
    local current = self._batch
    local parts = {}
    
    for part in key:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    
    for i = 1, #parts - 1 do
        local part = parts[i]
        if type(current[part]) ~= 'table' then
            current[part] = {}
        end
        current = current[part]
    end
    
    current[parts[#parts]] = value

    if not self._isTicking then
        self._isTicking = true
        SetTimeout(0, function()
            self._isTicking = false
            
            SendNUIMessage({
                action = self._action,
                namespace = self._namespace,
                batch = self._batch
            })
            
            self._batch = {}
        end)
    end
end

function RootState:sync()
    SendNUIMessage({
        action = self._action .. '_sync',
        namespace = self._namespace,
        state = self._internal
    })
end

function RootState:update(changes)
    if type(changes) ~= 'table' then return end
    for k, v in pairs(changes) do
        self._proxy[k] = v
    end
end

local function isDetached(ctx)
    while ctx do
        if ctx.detached then return true end
        ctx = ctx.parent
    end
    return false
end

local function buildProxy(tbl, path, root, ctx)
    local proxy = {}
    local internal = tbl
    local childProxies = {}
    ctx = ctx or { detached = false, parent = nil }
    
    setmetatable(proxy, {
        __isProxy = true,
        __raw = internal,
        __index = function(_, k)
            local v = internal[k]
            
            if v == nil and path == "" and RootState[k] then
                return function(_, ...)
                    return RootState[k](root, ...)
                end
            end
            
            if type(v) == 'table' then
                local cached = childProxies[k]
                
                if cached and cached.ref ~= v then
                    cached.ctx.detached = true
                    childProxies[k] = nil
                    cached = nil
                end
                
                if not cached then
                    local newPath = path == "" and k or (path .. "." .. k)
                    local newCtx = { detached = false, parent = ctx }
                    childProxies[k] = {
                        ref = v,
                        ctx = newCtx,
                        proxy = buildProxy(v, newPath, root, newCtx)
                    }
                end
                
                return childProxies[k].proxy
            end
            
            return v
        end,
        __newindex = function(_, k, v)
            local mt = getmetatable(v)
            if type(v) == 'table' and mt and mt.__isProxy then
                v = mt.__raw
            end

            if deepEqual(internal[k], v) then return end
            internal[k] = v
            
            if isDetached(ctx) then
                return
            end
            
            local fullKey = path == "" and k or (path .. "." .. k)
            
            if type(v) ~= 'function' and not root._ignore[fullKey] then
                root:queueUpdate(fullKey, v)
            end
            
            if childProxies[k] then
                childProxies[k].ctx.detached = true
                childProxies[k] = nil
            end
        end,
        __pairs = function()
            local function proxy_iter(_, k)
                local next_k = next(internal, k)
                if next_k ~= nil then
                    return next_k, proxy[next_k]
                end
            end
            return proxy_iter, internal, nil
        end,
        __len = function() return #internal end
    })
    
    return proxy
end

--- Creates a reactive Lua table proxy that automatically triggers a NUI message when updated.
--- Features Deep Reactivity, Batching, and full state Syncing.
---
--- **Lua Example:**
--- ```lua
--- local Hud = LT.NUI.CreateState('hud', { health = 100, stats = { stamina = 50 } })
---
--- Hud.health = 85 -- Triggers NUI update: { health: 85 }
--- Hud.stats.stamina = 20 -- Deep reactivity, triggers NUI update: { stats: { stamina: 20 } }
--- 
--- Hud:sync() -- Sends { action = '..._sync', state = { full_state } }
--- Hud:update({ health = 100, armor = 50 }) -- Batch update
--- ```
---
--- **NUI (Pinia / Vue) Example:**
--- ```javascript
--- import { useHudStore } from '@/stores/hud'
---
--- window.addEventListener('message', (event) => {
---     const data = event.data;
---     const hudStore = useHudStore();
---
---     // 1. Standard Event (Batched nested payload)
---     if (data.action === 'ltbridge_state_update') {
---         // data.batch = { health: 100, stats: { stamina: 20 } }
---         // Pinia's $patch automatically performs a Deep Merge!
---         hudStore.$patch(data.batch);
---     }
---     // 2. Sync Event (Triggered by Hud:sync())
---     else if (data.action === 'ltbridge_state_update_sync') {
---         hudStore.$state = data.state;
---     }
--- });
--- ```
--- @param namespace string Unique namespace for this state
--- @param tbl table Initial table data
--- @param ignoreList? table|string Keys to ignore when sending NUI messages (e.g. {'health', 'stats.stamina'})
--- @param action? string Action to send NUI (defaults to: 'ltbridge_state_update')
--- @return table proxy The proxy table with methods (:sync, :update)
--- @ltbridge export: CreateState
function CreateNUIState(namespace, tbl, ignoreList, action)
    local ignoreHash = {}
    if type(ignoreList) == 'table' then
        for _, key in ipairs(ignoreList) do
            ignoreHash[key] = true
        end
    end

    local root = setmetatable({
        _internal = tbl or {},
        _namespace = namespace,
        _action = action or 'ltbridge_state_update',
        _ignore = ignoreHash,
        _batch = {},
        _isTicking = false
    }, RootState)
    
    root._proxy = buildProxy(root._internal, "", root)
    return root._proxy
end
