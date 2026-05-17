local SendNUIMessage = SendNUIMessage

local MAX_TRAVERSAL_DEPTH = 128

local RootState = {}
RootState.__index = RootState

local function unwrapProxy(value)
    if type(value) ~= "table" then
        return value
    end

    local mt = getmetatable(value)
    if mt and mt.__isProxy and mt.__raw then
        return mt.__raw()
    end

    return value
end

local function joinPath(path, key)
    local strKey = tostring(key)
    if path == "" then
        return strKey
    end

    return path .. "." .. strKey
end

local function pathContains(parent, child)
    if parent == child then
        return true
    end

    if #parent >= #child then
        return false
    end

    if child:sub(1, #parent) ~= parent then
        return false
    end

    return child:sub(#parent + 1, #parent + 1) == "."
end

local function pathsOverlap(a, b)
    return pathContains(a, b) or pathContains(b, a)
end

local function createIgnoreNode()
    return {
        ignored = false,
        children = {}
    }
end

local function addIgnorePath(root, path)
    local node = root
    for part in path:gmatch("[^%.]+") do
        local children = node.children
        if not children[part] then
            children[part] = createIgnoreNode()
        end
        node = children[part]
    end
    node.ignored = true
end

local function getIgnoreCursor(root, path)
    local node = root
    if not node or path == "" then
        return false, node
    end

    for part in tostring(path):gmatch("[^%.]+") do
        if node.ignored then
            return true, node
        end

        node = node.children[part]
        if not node then
            return false, nil
        end
    end

    return node.ignored, node
end

local function isPayloadPrimitive(valueType)
    return valueType == "string" or valueType == "number" or valueType == "boolean"
end

local function cloneValue(value, options, depth, seen, ignoreNode)
    value = unwrapProxy(value)
    local valueType = type(value)

    if valueType ~= "table" then
        if options.payloadMode then
            if isPayloadPrimitive(valueType) then
                return value
            end
            return nil
        end
        return value
    end

    if depth >= options.maxDepth then
        if options.payloadMode then
            return nil
        end
        return {}
    end

    if seen[value] then
        if options.payloadMode then
            return nil
        end
        return {}
    end

    seen[value] = true
    local out = {}

    for key, child in pairs(value) do
        local childIgnoreNode = nil
        if options.applyIgnore and ignoreNode then
            childIgnoreNode = ignoreNode.children[tostring(key)]
            if childIgnoreNode and childIgnoreNode.ignored then
                goto continue
            end
        end

        local cloned = cloneValue(child, options, depth + 1, seen, childIgnoreNode)
        if cloned ~= nil then
            out[key] = cloned
        end

        ::continue::
    end

    seen[value] = nil
    return out
end

local function deepEqual(a, b, seen, depth)
    a = unwrapProxy(a)
    b = unwrapProxy(b)

    local typeA = type(a)
    local typeB = type(b)
    if typeA ~= typeB then
        return false
    end

    if typeA ~= "table" then
        return a == b
    end

    if a == b then
        return true
    end

    if depth >= MAX_TRAVERSAL_DEPTH then
        return false
    end

    seen = seen or {}
    seen[a] = seen[a] or {}
    if seen[a][b] then
        return true
    end
    seen[a][b] = true

    local keys = {}
    for key, value in pairs(a) do
        keys[key] = true
        if not deepEqual(value, b[key], seen, depth + 1) then
            return false
        end
    end

    for key in pairs(b) do
        if not keys[key] then
            return false
        end
    end

    return true
end

local function ensurePatchPath(root, path)
    local current = root
    local parts = {}
    for part in path:gmatch("[^%.]+") do
        parts[#parts + 1] = part
    end

    for index = 1, #parts - 1 do
        local key = parts[index]
        if type(current[key]) ~= "table" then
            current[key] = {}
        end
        current = current[key]
    end

    return current, parts[#parts]
end

local function removePatchPath(root, path)
    local parts = {}
    for part in path:gmatch("[^%.]+") do
        parts[#parts + 1] = part
    end
    if #parts == 0 then
        return
    end

    local function recurse(node, idx)
        local key = parts[idx]
        local child = node[key]
        if child == nil then
            return false
        end

        if idx == #parts then
            node[key] = nil
        elseif type(child) == "table" then
            local empty = recurse(child, idx + 1)
            if empty then
                node[key] = nil
            end
        end

        for _ in pairs(node) do
            return false
        end
        return true
    end

    recurse(root, 1)
end

local function collectDeleteList(deleteMap)
    local out = {}
    for path in pairs(deleteMap) do
        out[#out + 1] = path
    end
    return out
end

local function clearTable(tbl)
    for key in pairs(tbl) do
        tbl[key] = nil
    end
end

local function isNodeDetached(node)
    while node do
        if node.detached then
            return true
        end
        node = node.parent
    end
    return false
end

local function hasTableInParents(node, tbl)
    while node do
        if node.target == tbl then
            return true
        end
        node = node.parent
    end
    return false
end

local function detachChildren(node)
    for _, child in pairs(node.children) do
        child.detached = true
        detachChildren(child)
    end
    node.children = {}
end

local function resolveNodeTarget(node)
    if node.detached then
        return nil
    end

    if not node.parent then
        return node.target
    end

    local parentTarget = resolveNodeTarget(node.parent)
    if type(parentTarget) ~= "table" then
        node.detached = true
        return nil
    end

    local current = parentTarget[node.key]
    if current ~= node.target then
        node.target = current
        detachChildren(node)
    end

    if type(current) ~= "table" then
        return nil
    end

    return current
end

function RootState:getIgnoreCursor(path)
    return getIgnoreCursor(self._ignoreTree, path)
end

function RootState:isIgnoredPath(path)
    local ignored = self:getIgnoreCursor(path)
    return ignored
end

function RootState:clearBatch()
    clearTable(self._batchPatch)
    clearTable(self._batchDeleteSet)
end

function RootState:queueDelete(path)
    local ignored = self:isIgnoredPath(path)
    if ignored then
        return
    end

    removePatchPath(self._batchPatch, path)

    for existingPath in pairs(self._batchDeleteSet) do
        if pathContains(existingPath, path) then
            return
        end
        if pathContains(path, existingPath) then
            self._batchDeleteSet[existingPath] = nil
        end
    end

    self._batchDeleteSet[path] = true
end

function RootState:queuePatch(path, value)
    local ignored, ignoreNode = self:getIgnoreCursor(path)
    if ignored then
        return
    end

    local payload = cloneValue(value, {
        payloadMode = true,
        applyIgnore = true,
        maxDepth = MAX_TRAVERSAL_DEPTH
    }, 0, {}, ignoreNode)

    if payload == nil then
        self:queueDelete(path)
        return
    end

    for deletePath in pairs(self._batchDeleteSet) do
        if pathsOverlap(deletePath, path) then
            self._batchDeleteSet[deletePath] = nil
        end
    end

    local target, key = ensurePatchPath(self._batchPatch, path)
    target[key] = payload
end

function RootState:scheduleFlush()
    if self._isTicking then
        return
    end

    self._isTicking = true
    SetTimeout(0, function()
        self._isTicking = false

        local hasPatch = next(self._batchPatch) ~= nil
        local deletes = collectDeleteList(self._batchDeleteSet)
        local hasDeletes = #deletes > 0

        if not hasPatch and not hasDeletes then
            return
        end

        SendNUIMessage({
            action = self._action,
            namespace = self._namespace,
            batch = hasPatch and self._batchPatch or {},
            deletes = hasDeletes and deletes or nil
        })

        self:clearBatch()
    end)
end

function RootState:replaceInternal(newInternal)
    local raw = unwrapProxy(newInternal)
    if type(raw) ~= "table" then
        raw = {}
    end

    self._internal = raw
    self._rootNode.target = raw
    detachChildren(self._rootNode)
end

--- Returns a deep-copied version of the current state.
--- This output is safe for logging and debug tools.
--- It does not apply `ignoreList`.
--- @return table
function RootState:raw()
    return cloneValue(self._internal, {
        payloadMode = false,
        applyIgnore = false,
        maxDepth = MAX_TRAVERSAL_DEPTH
    }, 0, {}, nil) or {}
end

--- Returns the serialized state that would be sent to NUI.
--- Paths in `ignoreList` are filtered out.
--- @return table
function RootState:snapshot()
    return cloneValue(self._internal, {
        payloadMode = true,
        applyIgnore = true,
        maxDepth = MAX_TRAVERSAL_DEPTH
    }, 0, {}, self._ignoreTree) or {}
end

--- Sends the full filtered state to NUI.
--- Message action format: `<action>_sync`.
--- @return nil
function RootState:sync()
    SendNUIMessage({
        action = self._action .. "_sync",
        namespace = self._namespace,
        state = self:snapshot()
    })
end

--- Replaces the whole state tree and pushes a full replace payload to NUI.
--- This is not a patch operation.
--- Message action format: `<action>_set`.
--- @param nextState table New root state table.
--- @return nil
function RootState:set(nextState)
    self:replaceInternal(nextState or {})
    self:clearBatch()

    SendNUIMessage({
        action = self._action .. "_set",
        namespace = self._namespace,
        state = self:snapshot()
    })
end

local function updateProxyTable(targetProxy, patch, depth)
    if depth >= MAX_TRAVERSAL_DEPTH then
        return
    end

    for key, value in pairs(patch) do
        if type(value) == "table" then
            local existing = targetProxy[key]
            if type(existing) ~= "table" then
                targetProxy[key] = {}
                existing = targetProxy[key]
            end
            updateProxyTable(existing, value, depth + 1)
        else
            targetProxy[key] = value
        end
    end
end

--- Applies a deep patch on top of the existing state.
--- Missing nested tables are created automatically.
--- Existing keys stay as-is unless patch overrides them.
--- @param patch table Partial state update payload.
--- @return nil
function RootState:update(patch)
    if type(patch) ~= "table" then
        return
    end
    updateProxyTable(self._proxy, patch, 0)
end

local function buildProxy(root, node)
    local proxy = {}
    node.proxy = proxy

    setmetatable(proxy, {
        __isProxy = true,
        __raw = function()
            return resolveNodeTarget(node)
        end,
        __index = function(_, key)
            local target = resolveNodeTarget(node)
            if type(target) ~= "table" then
                return nil
            end

            local value = target[key]

            if node.path == "" and value == nil and RootState[key] then
                return function(_, ...)
                    return RootState[key](root, ...)
                end
            end

            if type(value) ~= "table" then
                return value
            end

            if hasTableInParents(node, value) then
                return value
            end

            local childNode = node.children[key]
            if childNode and childNode.target ~= value then
                childNode.detached = true
                detachChildren(childNode)
                node.children[key] = nil
                childNode = nil
            end

            if not childNode then
                local childPath = joinPath(node.path, key)
                childNode = {
                    root = root,
                    parent = node,
                    key = key,
                    path = childPath,
                    target = value,
                    children = {},
                    detached = false
                }
                node.children[key] = childNode
                buildProxy(root, childNode)
            end

            return childNode.proxy
        end,
        __newindex = function(_, key, value)
            local target = resolveNodeTarget(node)
            if type(target) ~= "table" then
                return
            end

            value = unwrapProxy(value)
            local fullPath = joinPath(node.path, key)
            local ignored = root:isIgnoredPath(fullPath)
            local current = target[key]

            if value == nil then
                if current == nil then
                    return
                end

                target[key] = nil
                local childNode = node.children[key]
                if childNode then
                    childNode.detached = true
                    detachChildren(childNode)
                    node.children[key] = nil
                end

                if not ignored and not isNodeDetached(node) then
                    root:queueDelete(fullPath)
                    root:scheduleFlush()
                end
                return
            end

            if ignored then
                if current == value then
                    return
                end
            elseif deepEqual(current, value, nil, 0) then
                return
            end

            target[key] = value

            local childNode = node.children[key]
            if childNode then
                childNode.detached = true
                detachChildren(childNode)
                node.children[key] = nil
            end

            if ignored or isNodeDetached(node) then
                return
            end

            root:queuePatch(fullPath, value)
            root:scheduleFlush()
        end,
        __pairs = function()
            local target = resolveNodeTarget(node)
            if type(target) ~= "table" then
                local function empty() return nil end
                return empty, {}, nil
            end

            local function iter(_, last)
                local nextKey = next(target, last)
                if nextKey ~= nil then
                    return nextKey, proxy[nextKey]
                end
            end

            return iter, target, nil
        end,
        __len = function()
            local target = resolveNodeTarget(node)
            if type(target) ~= "table" then
                return 0
            end
            return #target
        end
    })

    return proxy
end

--- Creates a reactive state table for NUI.
---
--- The returned proxy behaves like a normal Lua table.
--- Nested writes are tracked and same-tick changes are batched into one NUI message.
--- Assigning `nil` deletes the key and sends the deleted path in `deletes`.
---
--- ```lua
--- local player = LT.NUI.CreateState("Player", {
---     hud = {
---         health = 100,
---         armor = 100
---     },
---     inventory = {
---         items = {
---             { id = 1, name = "Apple", quantity = 1, secret = "123" }
---         }
---     },
---     localOnly = {
---         secret = "123"
---     }
--- }, { "localOnly", "inventory.items.1.secret" }, "UpdatePlayer")
---
--- player.hud.health = 50
--- player.hud.armor = 25
--- player.inventory.items[1].name = nil
--- player:update({ hud = { health = 75 } })
--- player:set({ hud = { health = 100, armor = 100 } })
--- player:sync()
--- ```
---
--- **Pinia / Vue**
--- ```javascript
--- window.addEventListener("message", (event) => {
---   const data = event.data;
---   const store = usePlayerStore();
---
---   if (data.action === "UpdatePlayer") {
---     store.$patch(data.batch || {});
---     for (const path of data.deletes || []) unsetByPath(store.$state, path);
---   }
---
---   if (data.action === "UpdatePlayer_sync" || data.action === "UpdatePlayer_set") {
---     store.$state = data.state;
---   }
--- });
--- ```
---
--- @param namespace string Unique state namespace.
--- @param tbl? table Initial state table.
--- @param ignoreList? string[] Dot-path list that will never be sent to NUI (ignored).
--- @param action? string Base update action. Default is `ltbridge_state_update`.
--- @return table proxy Reactive state proxy (`:sync`, `:set`, `:update`, `:raw`, `:snapshot`).
--- @ltbridge export: CreateState
function CreateNUIState(namespace, tbl, ignoreList, action)
    local ignoreTree = createIgnoreNode()
    if type(ignoreList) == "table" then
        for _, key in ipairs(ignoreList) do
            if type(key) == "string" and key ~= "" then
                addIgnorePath(ignoreTree, key)
            end
        end
    end

    local internal = unwrapProxy(tbl)
    if type(internal) ~= "table" then
        internal = {}
    end

    local root = setmetatable({
        _internal = internal,
        _namespace = namespace,
        _action = action or "ltbridge_state_update",
        _ignoreTree = ignoreTree,
        _batchPatch = {},
        _batchDeleteSet = {},
        _isTicking = false
    }, RootState)

    local rootNode = {
        root = root,
        parent = nil,
        key = nil,
        path = "",
        target = root._internal,
        children = {},
        detached = false
    }

    root._rootNode = rootNode
    root._proxy = buildProxy(root, rootNode)
    return root._proxy
end
