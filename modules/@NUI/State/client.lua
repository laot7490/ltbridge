local SendNUIMessage <const> = SendNUIMessage

local MAX_TRAVERSAL_DEPTH <const> = 128
local JSON_OBJECT_MT <const> = { __jsontype = "object" }
local JSON_ARRAY_MT <const> = { __jsontype = "array" }
local PAYLOAD_OPTS <const> = {
    payloadMode = true,
    applyIgnore = true,
    maxDepth = MAX_TRAVERSAL_DEPTH
}

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

local function createTypeNode()
    return {
        jsonType = nil,
        children = {},
        star = nil
    }
end

local function addTypePath(root, path, jsonType)
    local node = root
    for part in path:gmatch("[^%.]+") do
        if part == "*" then
            if not node.star then
                node.star = createTypeNode()
            end
            node = node.star
        else
            local children = node.children
            if not children[part] then
                children[part] = createTypeNode()
            end
            node = children[part]
        end
    end
    node.jsonType = jsonType
end

local function getTypeCursor(root, path)
    if not root then
        return nil
    end
    if path == "" then
        return root
    end

    local node = root
    for part in tostring(path):gmatch("[^%.]+") do
        local nextNode = node.children[part]
        if not nextNode then
            nextNode = node.star
        end
        if not nextNode then
            return nil
        end
        node = nextNode
    end
    return node
end

local function getTypeChild(typeNode, key)
    if not typeNode then
        return nil
    end
    local strKey = tostring(key)
    return typeNode.children[strKey] or typeNode.star
end

local function isPayloadPrimitive(valueType)
    return valueType == "string" or valueType == "number" or valueType == "boolean"
end

local function cloneValue(value, options, depth, seen, ignoreNode, typeNode)
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

        local cloned = cloneValue(child, options, depth + 1, seen, childIgnoreNode, getTypeChild(typeNode, key))
        if cloned ~= nil then
            out[key] = cloned
        end

        ::continue::
    end

    seen[value] = nil

    if options.payloadMode and typeNode then
        local jsonType = typeNode.jsonType
        if jsonType == "object" then
            setmetatable(out, JSON_OBJECT_MT)
        elseif jsonType == "array" then
            setmetatable(out, JSON_ARRAY_MT)
        end
    end

    return out
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

    local payload = cloneValue(value, PAYLOAD_OPTS, 0, {}, ignoreNode, getTypeCursor(self._typeTree, path))

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

function RootState:flush()
    local hasPatch = next(self._batchPatch) ~= nil
    local deletes = collectDeleteList(self._batchDeleteSet)
    local hasDeletes = #deletes > 0

    if not hasPatch and not hasDeletes then
        return
    end

    SendNUIMessage({
        action = self._action,
        batch = hasPatch and self._batchPatch or {},
        deletes = hasDeletes and deletes or nil
    })

    self:clearBatch()
end

function RootState:invalidateScheduledFlush()
    self._flushGen = self._flushGen + 1
    self._isTicking = false
end

function RootState:scheduleFlush()
    if self._isTicking then
        return
    end

    self._isTicking = true
    self._flushGen = self._flushGen + 1
    local gen = self._flushGen
    SetTimeout(0, function()
        if gen ~= self._flushGen then
            return
        end
        self._isTicking = false
        self:flush()
    end)
end

function RootState:requestFlush(async)
    if self._updateDepth > 0 then
        return
    end

    if async then
        self:scheduleFlush()
        return
    end

    self:invalidateScheduledFlush()
    self:flush()
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

local function payloadState(root)
    return cloneValue(root._internal, PAYLOAD_OPTS, 0, {}, root._ignoreTree, root._typeTree) or {}
end

--- Raw table underneath. Writing here doesn't go to NUI.
--- @return table
function RootState:asTable()
    return self._internal
end

--- Push full state. Action becomes `<action>_sync`.
function RootState:sync()
    self:invalidateScheduledFlush()
    self:clearBatch()

    SendNUIMessage({
        action = self._action .. "_sync",
        state = payloadState(self)
    })
end

--- Replace the whole state. Action becomes `<action>_set`.
--- @param nextState table
function RootState:set(nextState)
    self:replaceInternal(nextState or {})
    self:invalidateScheduledFlush()
    self:clearBatch()

    SendNUIMessage({
        action = self._action .. "_set",
        state = payloadState(self)
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

--- Merge `patch` into state, one flush at the end.
--- @param patch table
--- @param async? boolean true = SetTimeout(0) flush. default is sync.
function RootState:update(patch, async)
    ltassert(type(patch) == "table", "patch must be a table, got %s instead.", type(patch))

    self._updateDepth = self._updateDepth + 1
    local ok, err = pcall(updateProxyTable, self._proxy, patch, 0)
    self._updateDepth = self._updateDepth - 1

    if not ok then
        error(err)
    end

    if self._updateDepth > 0 then
        return
    end

    self:requestFlush(async and true or false)
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
                    root:requestFlush(false)
                end
                return
            end

            if current == value then
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
            root:requestFlush(false)
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

--- Reactive proxy from `LT.NUI.CreateState`. Methods are typed; state keys are dynamic (`[any] any`)
--- @class NuiState
--- @field [any] any
--- @field update fun(self: NuiState, patch: table, async?: boolean) Merge `patch` into state; one flush at the end. `async` = SetTimeout(0).
--- @field set fun(self: NuiState, nextState: table) Replace the whole state (`<action>_set`).
--- @field sync fun(self: NuiState) Push current state as-is (`<action>_sync`).
--- @field asTable fun(self: NuiState): table Raw table underneath; writes here do not go to NUI.

--- Reactive NUI state. Writes on the proxy send a patch to NUI.
--- Empty tables encode as JSON arrays (`[]`) unless listed in `types` as `"object"`.
---
--- ```lua
--- local player = LT.NUI.CreateState("UpdatePlayer", {
---     hud = { health = 100, armor = 100 },
---     items = {},
---     meta = {},
---     localOnly = { secret = "x" },
--- }, { "localOnly" }, {
---     ["meta"] = "object",
---     ["items.*.metadata"] = "object",
--- })
---
--- -- single field, message goes out now
--- player.hud.health = 50
---
--- -- several fields, one message
--- player:update({
---     hud = { health = 75, armor = 20 },
--- })
---
--- -- same, but flush via SetTimeout(0)
--- player:update({ hud = { health = 80 } }, true)
---
--- -- replace the whole state
--- player:set({ hud = { health = 100, armor = 100 } })
---
--- -- push current state as-is
--- player:sync()
---
--- -- raw table (won't hit NUI)
--- local t = player:asTable()
--- ```
---
--- **Vue + Pinia** (`@laot/nuix`)
--- ```ts
--- import { defineStore } from "pinia";
--- import { onNuiAction, applyLtBatch, replaceLtState } from "@laot/nuix";
---
--- export const usePlayerStore = defineStore("player", {
---   state: () => ({
---     hud: { health: 100, armor: 100 },
---   }),
--- });
---
--- const store = usePlayerStore();
---
--- onNuiAction("UpdatePlayer", (data) => {
---   applyLtBatch(store.$state, data);
--- });
---
--- onNuiAction("UpdatePlayer_sync", (data) => {
---   replaceLtState(store.$state, data.state ?? {});
--- });
---
--- onNuiAction("UpdatePlayer_set", (data) => {
---   replaceLtState(store.$state, data.state ?? {});
--- });
--- ```
---
--- @generic T : table
--- @param action string e.g. `UpdatePlayer`
--- @param initialTable? T
--- @param ignoreList? string[] paths that never leave Lua
--- @param types? table<string, "object"|"array"> dot paths; `*` = any segment; unmarked empty tables stay `[]`
--- @return T|NuiState Reactive proxy; field writes and :update / :set / :sync push to NUI.
--- @ltbridge export: CreateState
function CreateNUIState(action, initialTable, ignoreList, types)
    ltassert(action and type(action) == "string", "action must be a non-empty string")

    local ignoreTree = createIgnoreNode()
    if type(ignoreList) == "table" then
        for _, key in ipairs(ignoreList) do
            if type(key) == "string" and key ~= "" then
                addIgnorePath(ignoreTree, key)
            end
        end
    end

    local typeTree = nil
    if type(types) == "table" then
        for path, jsonType in pairs(types) do
            if type(path) == "string" and path ~= "" and (jsonType == "object" or jsonType == "array") then
                if not typeTree then
                    typeTree = createTypeNode()
                end
                addTypePath(typeTree, path, jsonType)
            end
        end
    end

    local internal = unwrapProxy(initialTable)
    if type(internal) ~= "table" then
        internal = {}
    end

    local root = setmetatable({
        _internal = internal,
        _action = action,
        _ignoreTree = ignoreTree,
        _typeTree = typeTree,
        _batchPatch = {},
        _batchDeleteSet = {},
        _isTicking = false,
        _flushGen = 0,
        _updateDepth = 0
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
