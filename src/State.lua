local Signal = require(script.Parent.Util.Signal)
local Empties = require(script.Parent.Util.Empties)

-- TYPES
type Signal<Args...> = Signal.Signal<Args...>

-- MODULE
return {
    stories = {},
    storyAdded = Signal.new() :: Signal<ModuleScript, any>,
    storyRemoved = Signal.new() :: Signal<ModuleScript, any>,
    storyAncestryChanged = Signal.new() :: Signal<ModuleScript, any>,
    storyRenamed = Signal.new() :: Signal<ModuleScript, any>,               -- currently not used ...

    getPreview = Empties.funcNil :: () -> any,
    startPreview = Signal.new(),
    finishPreview = Signal.new(),
    previewStateChanged = Signal.new(),

    inputStorySelected = Signal.new() :: Signal<ModuleScript, any>,
    inputStoryRefresh = Signal.new(),
    inputStoryClose = Signal.new(),
}