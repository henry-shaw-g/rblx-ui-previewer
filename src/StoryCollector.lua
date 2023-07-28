local Cleaner = require(script.Parent.Util.Cleaner)

local function canBeStory(candidate: Instance)
    if candidate:IsA("ModuleScript") and candidate.Name:match("%.story$") then
        return true
    else
        return false
    end
end

local function isStory(list, moduleScript)
    return list[moduleScript] ~= nil
end

local function isTracking(tracked, candidate)
    return tracked[candidate] ~= nil
end

-- MODULE
local StoryCollector = {}
local META = {__index = StoryCollector}

function StoryCollector.new(props)
    local self = setmetatable({}, META)

    self.targets = {
        workspace,
        game:GetService("ServerStorage"),
        game:GetService("ServerScriptService"),
        game:GetService("StarterPlayer"),
        game:GetService("ReplicatedStorage"),
        game:GetService("StarterGui"),
    }

    self.cleaner = Cleaner.new()
    self.tracked = {}
    self.list = props.stories
    self.events = props.events

    return self
end

local function addStory(self, moduleScript)
    print("[ui-previewer]: adding story", moduleScript:GetFullName())
    local storyData = {
        cleaner = Cleaner.new(),
    }
    self.list[moduleScript] = storyData
    self.events.added:fire(moduleScript, storyData)
end

local function removeStory(self, moduleScript)
    print("[ui-previewer]: removing story", moduleScript:GetFullName())
    local storyData = self.list[moduleScript]
    self.list[moduleScript] = nil
    if storyData then
        storyData.cleaner:clean()
    end

    self.events.removed:fire(moduleScript, storyData)
end

local function startTracking(self, candidate: ModuleScript)
    local trackData = {
        cleaner = Cleaner.new()
    }

    local function updateIsStory()
        if isStory(self.list, candidate) then
            if not canBeStory(candidate) then
                removeStory(self, candidate)
            end
        else
            if canBeStory(candidate) then
                addStory(self, candidate)
            end
        end
    end
    updateIsStory()
    trackData.cleaner:add(candidate:GetPropertyChangedSignal("Name"):Connect(updateIsStory))

    self.tracked[candidate] = trackData
end

local function stopTracking(self, candidate: ModuleScript)
    local trackData = self.tracked[candidate]
    trackData.cleaner:clean()
    if isStory(self.list, candidate) then
        removeStory(self, candidate)
    end
    self.tracked[candidate] = nil
end

function StoryCollector:init()
    local function onDescendant(descendant: Instance)
        if not isTracking(self.tracked, descendant) and descendant:IsA("ModuleScript") then
            startTracking(self, descendant)
        end
    end

    local function onDescendantRemoving(descendant)
        if isTracking(self.tracked, descendant) then
            stopTracking(self, descendant)
        end
    end

    for _, target: Instance in self.targets do
        for _, descendant in target:GetDescendants() do
            onDescendant(descendant)
        end
        self.cleaner:add(target.DescendantAdded:Connect(onDescendant))
        self.cleaner:add(target.DescendantRemoving:Connect(onDescendantRemoving))
    end
end

function StoryCollector:destroy()
    for moduleScript, trackData in self.tracked do
        stopTracking(self, moduleScript)
    end
    self.cleaner:clean()
end

return StoryCollector