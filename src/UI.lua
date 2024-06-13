--[[
    TODO: allow toolbar buttons to be synced with widget visibility (cases when user closes with corner X button)
]]
local TweenService = game:GetService("TweenService")

local Cleaner = require(script.Parent.Util.Cleaner)
local GuiLib = require(script.Parent.Util.GuiLib)
    local Sub = GuiLib.sub
    local New = GuiLib.new
    local Mend = GuiLib.mend
    local Ref = GuiLib.ref
local State = require(script.Parent.State)

--  VARIABLES
local UI_HUE = 0.7
local UI_SAT = 0.1
local UI_FONT = Enum.Font.SourceSans
local UI_FONT1 = Enum.Font.SourceSansItalic

local HIGHLIGHT_TWEENINFO = TweenInfo.new(0.1)

local ZINDEX_BACK = 0
local ZINDEX_PREVIEW = 256
local ZINDEX_LIST = 512

-- PRIVATE
local function tweenProps(i: Instance, goals, tweenInfo)
    TweenService:Create(i, tweenInfo, goals):Play()
end

---------------------------
-- preview section class --
---------------------------

local PreviewSection = {}
do
    local META = {__index = PreviewSection}

    local STATUS_COLOR_RUNNING = Color3.fromRGB(0, 148, 12)
    -- local STATUS_COLOR_COMPLETE = Color3.fromRGB(21, 255, 0)
    -- local STATUS_COLOR_FAILED = Color3.fromRGB(236, 14, 14)

    local function headerButton(props)
        local outProps = {
            BackgroundColor3 = props.buttonColor,
            BackgroundTransparency = 1,
            Position = UDim2.new(props.x, UDim.new(0, 0)),
            Size = UDim2.new(props.w, UDim.new(1, 0)),
            TextSize = 22,
            Font = UI_FONT,
            TextColor3 = Color3.fromHSV(0, 0, 0.7),
            Text = props.text,
        }
        local button = New "TextButton" (GuiLib.inheritRefs(outProps, props))
        
        local hovering = false
        local function updateHighlight()
            if hovering then
                tweenProps(button, {BackgroundTransparency = 0.7}, HIGHLIGHT_TWEENINFO)
            else
                tweenProps(button, {BackgroundTransparency = 1}, HIGHLIGHT_TWEENINFO)
            end
        end
        button.MouseEnter:connect(function() 
            hovering = true
            updateHighlight()
        end)
        button.MouseLeave:connect(function() 
            hovering = false
            updateHighlight()
        end)

        return button
    end

    function PreviewSection.new(props)
        local self = setmetatable({}, META)

        self.header = assert(props.header, "expected header in props")
        self.container = assert(props.container, "expected container in props")
        self.footer = assert(props.footer, "expected footer in props")

        return self
    end

    function PreviewSection:init()
        self.storyTitleLabel = nil
        self.storyStatusLabel = nil

        self.buttonSettings = nil
        self.buttonRefresh = nil
        self.buttonClose = nil

        Mend(self.header) {
            [Sub] = {
                SettingsButton = headerButton({
                    buttonColor = Color3.fromHSV(0, 0, 0.7),
                    x = UDim.new(0, 0),
                    w = UDim.new(0, 100),
                    text = "Settings",
                    [Ref "buttonSettings"] = self,
                }),
                RefreshButton = headerButton({
                    buttonColor = Color3.fromHSV(0.594907, 0.919149, 0.921569),
                    x = UDim.new(0, 100),
                    w = UDim.new(0, 100),
                    text = "Refresh",
                    [Ref "buttonRefresh"] = self, 
                }),
                CloseButton = headerButton({
                    buttonColor = Color3.fromHSV(0.024775, 0.913580, 0.952941),
                    x = UDim.new(0, 200),
                    w = UDim.new(0, 100),
                    text = "Close",
                    [Ref "buttonClose"] = self,
                })
            }
        }

        Mend(self.footer) {
            [Sub] = {
                StoryTitleLabel = New "TextLabel" {
                    Position = UDim2.new(0, 4, 0, 0),
                    Size = UDim2.new(0.25, 0, 1, 0),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextSize = 22,
                    Font = UI_FONT,
                    TextColor3 = Color3.fromHSV(0, 0, 0.6),
                    Text = "story: N/A",
                    [Ref "storyTitleLabel"] = self,
                },

                StoryStatusLabel = New "TextLabel" {
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -4, 0, 0),
                    Size = UDim2.new(0, 100, 1, 0),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextSize = 22,
                    Font = UI_FONT1,
                    TextColor3 = STATUS_COLOR_RUNNING,
                    Text = "running",
                    [Ref "storyStatusLabel"] = self,
                }
            }
        }

        self:_updateFooter(State.getPreview())
        self:_updateMenu(State.getPreview())

        State.startPreview:connect(function(preview) 
            self:_updateFooter(preview) 
            self:_updateMenu(preview)
        end)
        State.finishPreview:connect(function(_) 
            self:_updateFooter(nil)
            self:_updateMenu(nil)
        end)
        State.previewStateChanged:connect(function(preview) 
            self:_updateFooter(preview)
        end)

        self.buttonRefresh.Activated:connect(function() 
            State.inputStoryRefresh:fire()
        end)
        self.buttonClose.Activated:connect(function() 
            State.inputStoryClose:fire()
        end)
    end

    function PreviewSection:getContainer()
        return self.container
    end

    function PreviewSection:_updateFooter(preview)
        if preview then
            local moduleScript = preview.moduleScript
            self.storyTitleLabel.Text = `story: {moduleScript.Name}`
           

            local statusText: string
            local statusColor: Color3
            if preview.state == "running" then
                statusText = "Running"
                statusColor = Color3.fromRGB(98, 255, 0)
            elseif preview.state == "failed" then
                statusText = "Failed"
                statusColor = Color3.fromRGB(255, 64, 64)
            else
                statusText = "----"
                statusColor = Color3.fromRGB(104, 104, 104)
            end
            self.storyStatusLabel.Text = statusText
            self.storyStatusLabel.TextColor3 = statusColor
            self.storyStatusLabel.Visible = true
        else
            self.storyTitleLabel.Text = "story: N/A"
            self.storyStatusLabel.Visible = false
        end
    end

    function PreviewSection:_updateMenu(preview)
        if preview then
            self.buttonRefresh.Visible = true
            self.buttonClose.Visible = true
        else
            self.buttonRefresh.Visible = false
            self.buttonClose.Visible = false
        end
    end
end

-----------------------------
-- story list secton class --
-----------------------------

local StoryListSection = {}
do
    local META = {__index = StoryListSection}

    local function parentListItem(props)
        local item = New "TextButton" {
            Parent = props.Parent,
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundColor3 = Color3.fromHSV(UI_HUE, UI_SAT, 0.75),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextSize = 16,
            Font = Enum.Font.SourceSans,
            TextColor3 = Color3.fromHSV(0, 0, 0.65),
            ClipsDescendants = true,
            --Text = storyListItemText(props.moduleScript),
            Text = props.path
        } :: TextButton
        props.cleaner:add(item)

        local hovering = false
        local function updateItemHighlight()
            if hovering then
                item.ClipsDescendants = false
            else
                item.ClipsDescendants = true
            end
        end
        item.MouseEnter:Connect(function() 
            hovering = true
            updateItemHighlight()
        end)
        item.MouseLeave:Connect(function()
            hovering = false
            updateItemHighlight()
        end)

        return item
    end

    local function storyListItem(props)
        local item = New "TextButton" {
            Parent = props.Parent,
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundColor3 = Color3.fromHSV(UI_HUE, UI_SAT, 1),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextSize = 16,
            Font = Enum.Font.SourceSans,
            TextColor3 = Color3.fromHSV(0, 0, 0.9),
            --Text = storyListItemText(props.moduleScript),
            Text = props.path,
            ClipsDescendants = true,
        } :: TextButton

        -- TODO: handle this on data / collector side
        --[[
        props.storyData.cleaner:add(props.moduleScript:GetPropertyChangedSignal("Name"):Connect(function() 
            item.Text = storyListItemText(props.moduleScript)
        end))
        props.storyData.cleaner:add(props.moduleScript.AncestryChanged:Connect(function() 
            item.Text = storyListItemText(props.moduleScript)
        end))
        ]]
        local hovering = false
        local function updateItemHighlight()
            local selected = false
            if hovering or selected then
                tweenProps(item, {BackgroundTransparency = 0.75}, HIGHLIGHT_TWEENINFO)
            else
                tweenProps(item, {BackgroundTransparency = 1,}, HIGHLIGHT_TWEENINFO)
            end
            if hovering then
                item.ClipsDescendants = false
            else
                item.ClipsDescendants = true
            end
        end

        item.MouseEnter:Connect(function() 
            hovering = true
            updateItemHighlight()
        end)
        item.MouseLeave:Connect(function()
            hovering = false
            updateItemHighlight()
        end)
        item.Activated:Connect(function() 
            State.inputStorySelected:fire(props.moduleScript)
        end)

        props.cleaner:add(item)

        return item
    end

    function StoryListSection.new(container)
        local self = setmetatable({}, META)
        self.container = container
        self.frames = {}
        self.treeCleaner = Cleaner.new()
        self.tree = {
            [game] = {
                story = false,
                parenting = true, -- dont really care about this ...
            }
        }
        return self
    end

    local function makeNode(inst: Instance, cleaner, render)
        cleaner:add(inst:GetPropertyChangedSignal("Name"):Connect(render))
        return {
            inst = inst,
            children = {},
        }
    end

    local function isParentNode(node)
        return node.parentItem or node.inst == game
    end

    local function renderTree(self, root, cursor: Vector2, path: string, descedants, excludeFromPath)
        -- TODO: NOT THIS
        if not excludeFromPath then
            path ..= root.inst.Name .. "/"
        end
        if root.parentItem then
            Mend(root.parentItem) {
                Position = UDim2.new(0, cursor.X, 0, cursor.Y),
                Size = UDim2.new(1, -cursor.X, 0, 20),
                Text = path,
            }
            cursor += Vector2.new(8, 20)
        end

        if isParentNode(root) then
            path = ""
            descedants = {}
        end

        for _, node in root.children do
            cursor = renderTree(self, node, cursor, path, descedants)
        end

        if isParentNode(root) then
            for _, node in descedants do
                if node.storyItem then
                    Mend(node.storyItem) {
                        Position = UDim2.new(0, cursor.X, 0, cursor.Y),
                        Size = UDim2.new(1, -cursor.X, 0, 20),
                        --Text = path .. node.inst.Name,
                    }
                    cursor += Vector2.new(0, 20)
                end
            end

            for _, node in root.children do
                if node.storyItem then
                    --[[node.storyItem.Position = UDim2.new(0, cursor.X, 0, cursor.Y)
                    node.storyItem.Text = path .. node.inst.Name]]
                    Mend(node.storyItem) {
                        Position = UDim2.new(0, cursor.X, 0, cursor.Y),
                        Text = path .. node.inst.Name,
                    }
                    cursor += Vector2.new(0, 20)
                end
            end

            
        else
            for _, node in root.children do
                if node.storyItem then
                    table.insert(descedants, node)
                    Mend(node.storyItem) {
                        Text = path .. node.inst.Name
                    }
                end
            end
        end

        if root.parentItem then
            cursor -= Vector2.new(8, 0)
        end
        return cursor
    end

    local function renderRoot(self)
        renderTree(self, self.tree[game], Vector2.zero, "", {}, true)
    end

    -- tbh this name is no longer descriptive of what this function does ...
    local function renderStoryModules(self, list)
        -- clean tree
        self.treeCleaner:clean()
        table.clear(self.tree)

        -- build tree
        self.tree[game] = makeNode(game, self.treeCleaner, function() renderRoot(self) end)

        for moduleScript: ModuleScript, storyData in list do

            local node = self.tree[moduleScript]
            local parent = moduleScript.Parent
            
            if not parent then
                continue
            end

            if node then
                if not node.parentItem then
                    node.parentItem = parentListItem({
                        Parent = self.container,
                        path = "story parent item",
                        cleaner = self.treeCleaner,
                    })
                end
                if not node.storyItem then
                    node.storyItem = storyListItem({
                      Parent = self.container,
                      path = "story item",
                      cleaner = self.treeCleaner, 
                    })
                end

                node = self.tree[parent]
                if node and parent ~= game and not node.parentItem then
                    node.parentItem = parentListItem({
                        Parent = self.container,
                        path = "story item",
                        cleaner = self.treeCleaner,                    
                    })
                end
            else
                node = makeNode(moduleScript, self.treeCleaner, function() renderRoot(self) end)
                node.storyItem = storyListItem({
                    Parent = self.container,
                    moduleScript = moduleScript,
                    path = "story item",
                    cleaner = self.treeCleaner,
                })
                self.tree[moduleScript] = node

                -- build tree for missing nodes up
                local pnode = self.tree[parent]
                while parent and not pnode do
                    pnode = makeNode(parent, self.treeCleaner, function() renderRoot(self) end)
                    self.tree[parent] = pnode

                    table.insert(pnode.children, node)

                    parent = parent.Parent
                    node = pnode
                    pnode = self.tree[parent]
                end
                if pnode then
                    table.insert(pnode.children, node)
                end
                -- update parent nodes for existing upwards
                local abort = false
                while pnode and not abort do
                    if parent ~= game and not pnode.parentItem then
                        pnode.parentItem = parentListItem({
                            Parent = self.container,
                            path = "parent item",
                            cleaner = self.treeCleaner,
                        })
                    end
                    if not pnode.storyItem then
                        abort = true
                    end
                    parent = parent.Parent
                    pnode = self.tree[parent]
                end
            end
        end

        -- render tree
        renderRoot(self)
        --renderTree(self, self.tree[game], Vector2.zero, "")
    end

    function StoryListSection:init()

        renderStoryModules(self, State.stories)
        State.storyAdded:connect(function() 
            renderStoryModules(self, State.stories)
        end)
        State.storyRemoved:connect(function() 
            renderStoryModules(self, State.stories)
        end)
        State.storyAncestryChanged:connect(function() 
            renderStoryModules(self, State.stories)
        end)
        State.storyRenamed:connect(function() 
            renderRoot(self)
        end)
    end
end

-- MODULE

local UI = {}
do
    local META = {__index = UI}

    local function makeWidget(pluginAPI)
        local info = DockWidgetPluginGuiInfo.new(
            Enum.InitialDockState.Float,
            false,
            false,
            512,
            384,
            512,
            384
        )

        local widget = pluginAPI:CreateDockWidgetPluginGui("ui-previewer-widget", info) :: DockWidgetPluginGui
        widget.Title = "ui-previewer"
        widget.Name = "UIPreviewer"
        widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        return widget
    end

    function UI.new(pluginAPI, toolbarButton: PluginToolbarButton)
        local self = setmetatable({}, META)

        self.enabled = false
        self.widget = makeWidget(pluginAPI)
        self.widget:BindToClose(function() 
            self:disable()
        end)
        self.toolbarButton = toolbarButton

        return self
    end

    function UI:init()
        self.frame = nil
        local previewProps = {}

        New "Frame" {
            Parent = self.widget,
            Name = "UIExplorerFrame",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromHSV(UI_HUE, UI_SAT, 0.15),
            ZIndex = ZINDEX_BACK,

            [Sub] = {
                StoryListHeader = New "TextLabel" {
                    Size = UDim2.new(0, 150, 0, 24),
                    BackgroundColor3 = Color3.fromHSV(UI_HUE, UI_SAT, 0.25),
                    TextSize = 22,
                    TextColor3 = Color3.fromHSV(0, 0, 0.7),
                    Font = Enum.Font.SourceSans,
                    ZIndex = ZINDEX_LIST,
                    Text = "Stories",
                },
                StoryList = New "Frame" {
                    Position = UDim2.new(0, 0, 0, 24),
                    Size = UDim2.new(0, 150, 1, -24),
                    BackgroundColor3 = Color3.fromHSV(UI_HUE, UI_SAT, 0.3),
                    ClipsDescendants = false,
                    ZIndex = ZINDEX_LIST,
                    [Ref "storyListFrame"] = self
                },
                PreviewHeaderFrame = New "Frame" {
                    Position = UDim2.new(0, 150, 0, 0),
                    Size = UDim2.new(1, -150, 0, 24),
                    BackgroundColor3 = Color3.fromHSV(UI_HUE, UI_SAT, 0.2),
                    ZIndex = ZINDEX_PREVIEW,
                    [Ref "header"] = previewProps
                },
                PreviewContainerFrame = New "Frame" {
                    Position = UDim2.new(0, 150, 0, 24),
                    Size = UDim2.new(1, -150, 1, -2 * 24),
                    BackgroundTransparency = 1,
                    ZIndex = ZINDEX_PREVIEW,
                    [Ref "container"] = previewProps
                },
                PreviewFooterFrame = New "Frame" {
                    AnchorPoint = Vector2.new(0, 1),
                    Position = UDim2.new(0, 150, 1, 0),
                    Size = UDim2.new(1, -150, 0, 24),
                    BackgroundColor3 = Color3.fromHSV(UI_HUE, UI_SAT, 0.2),
                    ZIndex = ZINDEX_PREVIEW,
                    [Ref "footer"] = previewProps
                }
            },
            [Ref "frame"] = self,
        }

        self.storyListSection = StoryListSection.new(self.storyListFrame)
        self.storyListSection:init()

        self.previewSection = PreviewSection.new(previewProps)
        self.previewSection:init()
    end

    function UI:toggle()
        if self.enabled then
            self:disable()
            return false
        else
            self:enable()
            return true
        end
    end

    function UI:enable()
        self.enabled = true
        self.widget.Enabled = true
        if self.toolbarButton then
            self.toolbarButton:SetActive(true)
        end
    end

    function UI:disable()
        self.enabled = false
        self.widget.Enabled = false
        if self.toolbarButton then
            self.toolbarButton:SetActive(false)
        end
    end

    function UI:getPreviewFrame()
        return self.previewSection:getContainer()
    end
end

return UI