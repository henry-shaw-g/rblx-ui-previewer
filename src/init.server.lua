local RunService = game:GetService("RunService")

local State = require(script.State)
local UI = require(script.UI)
local StoryCollector = require(script.StoryCollector)
local Previewer = require(script.Previewer)

-- SCRIPT
local function makeToolbar()
    local toolbar = plugin:CreateToolbar("ui-previewer")

    local buttonToggle = toolbar:CreateButton("ToggleUIPreviewer", "toggle ui-previewer", "", "toggle ui-previewer")
    buttonToggle.ClickableWhenViewportHidden = true

    return {
        toolbar = toolbar,
        buttonToggle = buttonToggle,
    }
end

local function makeUI(toolbar)
    local ui = UI.new(plugin)

    toolbar.buttonToggle.Click:Connect(function() 
        ui:toggle()        
    end)

    return ui
end

local function init()
    local toolbar = makeToolbar()
    
    local collector = StoryCollector.new({
        stories = State.stories,
        events = {
            added = State.storyAdded,
            removed = State.storyRemoved,
            changed = State.storyChanged,
        }
    })
    collector:init()

    local ui = makeUI(toolbar)
    ui:init()

    local previewer = Previewer.new({
        targetFrame = ui:getPreviewFrame(),
        events = {
            startPreview = State.startPreview,
            finishPreview = State.finishPreview,
            stateChanged = State.previewStateChanged,
        },
    })
    State.getPreview = function()
        return previewer:getPreview()
    end

    -- bind modules
    State.inputStorySelected:connect(function(moduleScript)
        local preview = previewer:getPreview()
        if preview then
            previewer:finish()
        end
        if not preview or preview.moduleScript ~= moduleScript then
            previewer:preview(moduleScript)
        end
    end)

    State.inputStoryRefresh:connect(function() 
        if previewer:getPreview() then
            previewer:refresh()
        end
    end)

    State.inputStoryClose:connect(function() 
        if previewer:getPreview() then
            previewer:finish()
        end
    end)
end

if RunService:IsStudio() and not RunService:IsRunMode() then
    init()
end