--[[
    module: Previewer
    note: it is vital that everything is 
]]

local Cleaner = require(script.Parent.Util.Cleaner)
local GuiLib = require(script.Parent.Util.GuiLib)
local New = GuiLib.new

-- MODULE
local Previewer = {}
local META = {__index = Previewer}

function Previewer.new(props)
    local self = setmetatable({}, META)
    self._targetFrame = props.targetFrame
    self._events = props.events
    self._previewing = nil

    return self
end

local function runPreview(self, data)
    local moduleScript = data.moduleScript
    local temp = {
        moduleCache = {},
        envGlobals = {},
        envMeta = {__index = getfenv(0)},
        cleaner = Cleaner.new(),
        require = nil,
    }
    data.temp = temp

    function temp.require(moduleScript: ModuleScript)
        assert(moduleScript ~= nil, "cannot pass nil to require.")
        assert(typeof(moduleScript) == "Instance" and moduleScript:IsA("ModuleScript"), "expected modulescript for require.")

        if temp.moduleCache[moduleScript] then
            return
        end

        temp.cleaner:add(moduleScript.Changed:Connect(function()
            -- clean
            -- refresh
        end))
        
        local loader, loadStringErr = loadstring(moduleScript.Source, moduleScript:GetFullName())
        if not loader then
            error("error loading module script.\n" .. loadStringErr)
        end

        local succ, moduleOrErr = pcall(loader)
        if not succ then
            error("error requiring module script.\n" .. moduleOrErr)
        end
        if not moduleOrErr then
            error(`module returned no values. module: {moduleScript:GetFullName()}`)
        end

        setfenv(moduleOrErr, setmetatable({
            _G = temp.envGlobals,
            shared = temp.envGlobals,
            script = moduleScript,
            require = temp.require,
        }, temp.envMeta) :: any)
        temp.moduleCache[moduleScript] = moduleOrErr

        return moduleOrErr
    end

    local tempTargetFrame = New "Frame" {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = self._targetFrame,
    }
    temp.cleaner:add(tempTargetFrame)

    local module = temp.require(moduleScript)
    if typeof(module) ~= "function" then
        error(`ui-previewer: story did not return a function. story: {moduleScript:GetFullName()}`)
    end

    temp.cleaner:add(module(tempTargetFrame)) -- todo: make this in a task.defer?
end

function Previewer:preview(moduleScript)
    assert(self._previewing == nil, script.Name .. ": attempted to start preview, already has current preview.")
    assert(moduleScript and moduleScript:IsA("ModuleScript"), script.Name .. ": given invalid moduleScript parameter.")

    local data = {
        moduleScript = moduleScript,
        state = nil,
        err = nil,
        cleaner = Cleaner.new(),
        temp = nil,
    }
    self._previewing = data
    self._events.startPreview:fire(data)
    runPreview(self, data)
end

function Previewer:refresh()
    local data = assert(self._previewing, script.Name .. ": attempted to refresh, no current preview.")
    local temp = data.temp
    data.temp = nil
    if temp then
        temp.cleaner:clean()
    end
    runPreview(self, data)
end

function Previewer:finish()
    local data = self._previewing
    self._previewing = nil
    if not data then
        return
    end
    data.state = nil
    data.cleaner:clean()

    local temp = data.temp
    data.temp = nil
    if not temp then
        return
    end
    temp.cleaner:clean()
    self._events.finishPreview:fire(data)
end

function Previewer:getPreview()
    return self._previewing
end

return Previewer