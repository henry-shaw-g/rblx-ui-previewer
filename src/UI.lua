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

local MAX_STORY_ITEM_CHARS = 20

local HIGHLIGHT_TWEENINFO = TweenInfo.new(0.1)

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
    local STATUS_COLOR_COMPLETE = Color3.fromRGB(21, 255, 0)
    local STATUS_COLOR_FAILED = Color3.fromRGB(236, 14, 14)

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

    --[[
    local function storyListItemText(moduleScript)
        local s = moduleScript.Name
        local i = moduleScript
        local c = s:len()

        while i.Parent and i.Parent ~= game do
            local p = i.Parent
            local name = p.Name

            c += if p and p ~= game then name:len() + 1 else 1
            if c < MAX_STORY_ITEM_CHARS then
                i = p -- i was high when i made this fs
                s = string.format("%s/%s", name, s)
            else
                break
            end
        end

        if i.Parent and i.Parent ~= game then
            s = "../" .. s
        else
            s = "/" .. s
        end

        return s
    end
    ]]

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
            --Text = storyListItemText(props.moduleScript),
            Text = props.path
        } :: TextButton
        props.cleaner:add(item)
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
            Text = props.path
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
        inst:GetPropertyChangedSignal("Name"):Connect(render)
        return {
            inst = inst,
            children = {},
        }
    end

    --[[
    local function addChildNode(pnode, cnode)
        table.insert(pnode.children, cnode)
    end

    local function rmChildNode(pnode, cnode)
        local i = table.find(pnode.children, cnode)
        if i then
            table.remove(pnode.children, cnode)
        end
    end

    local function countChildGuiObjects(pnode)
        local c = 0
        for _, cnode in pnode.children do
            if cnode.storyItem then
                c += 1
            end
            if cnode.parentItem then
                c += 1
            end
        end
        return c
    end
    -- local function findAncestorNode(self, i)
    --     local p = i
    --     local node
    --     repeat
    --         node = self.tree[p]
    --         p = p.Parent
    --     until node or p == game
    -- end

    local function getChildItemNodes(node, parentItemNodes, storyItemNodes)
        -- note: same node may be present in parent and story item nodes
        for _, cnode in node.children do
            if not cnode.parentItem and not cnode.storyItem then
                getChildItemNodes(cnode, parentItemNodes, storyItemNodes)
            else
                if cnode.parentItem then
                    table.insert(parentItemNodes, cnode)
                end
                if cnode.storyItem then
                    table.insert(storyItemNodes, cnode)
                end
            end
        end
    end
    ]]

    local function renderTree(self, root, cursor: Vector2, path: string)
        -- TODO: NOT THIS
        if root.parentItem then
            print("rendering parent item for ", root.inst.Name, " at ", cursor)
            --[[root.parentItem.Position = UDim2.new(0, cursor.X, 0, cursor.Y)
            root.parentItem.Text = path .. root.inst.Name]]
            Mend(root.parentItem) {
                Position = UDim2.new(0, cursor.X, 0, cursor.Y),
                Text = path .. root.inst.Name,
            }
            cursor += Vector2.new(4, 20)
            path = ""
        else
            path ..= root.inst.Name .. "/"
        end

        for _, node in root.children do
            cursor = renderTree(self, node, cursor, path)
        end

        for _, node in root.children do
            if node.storyItem then
                print("rendering story item for", node.inst.Name, " at", cursor, " with path", path)
                --[[node.storyItem.Position = UDim2.new(0, cursor.X, 0, cursor.Y)
                node.storyItem.Text = path .. node.inst.Name]]
                Mend(node.storyItem) {
                    Position = UDim2.new(0, cursor.X, 0, cursor.Y),
                    Text = path .. node.inst.Name,
                }
                cursor += Vector2.new(0, 20)
            end
        end

        -- local parentItemNodes = {}
        -- local storyItemNodes = {}
        -- getChildItemNodes(root, parentItemNodes, storyItemNodes)
        -- for _, node in parentItemNodes do
        --     -- TODO: sort these ...
        --     node.parentItem.Position = UDim2.new(0, cursor.X, 0, cursor.Y)
        --     node.parentItem.Text = node.inst.Name
        --     cursor = cursor + Vector2.new(0, 20)
        --     cursor = renderTree(self, node, cursor + Vector2.new(4, 0)) - Vector2.new(4, 0)
        -- end
        -- for _, node in storyItemNodes do
        --     node.storyItem.Position = UDim2.new(0, cursor.X, 0, cursor.Y)
        --     node.storyItem.Text = node.inst.Name
        --     cursor = cursor + Vector2.new(0, 20)
        -- end

        if root.parentItem then
            cursor -= Vector2.new(4, 0)
        end

        return cursor
    end


    -- tbh this name is no longer descriptive of what this function does ...
    local function renderStoryModules(self, list)
        -- clean tree
        -- for _, node in self.tree do
        --     if node.parentItem then
        --         node.parentItem:Destroy()
        --     end
        --     if node.storyItem then
        --         node.storyItem:Destroy()
        --     end
        -- end
        self.treeCleaner:clean()
        table.clear(self.tree)

        local function doRender()
            renderTree(self, self.tree[game], Vector2.zero, "")
        end

        -- build tree
        self.tree[game] = makeNode(game, self.treeCleaner, doRender)

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
                node = makeNode(moduleScript, self.treeCleaner, doRender)
                node.storyItem = storyListItem({
                    Parent = self.container,
                    moduleScript = moduleScript,
                    path = "story item",
                    cleaner = self.treeCleaner,
                })
                self.tree[moduleScript] = node

                local pnode
                local abort = false
                while node and parent and not abort do
                    pnode = self.tree[parent]
                    if pnode then
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
                    else
                        pnode = makeNode(parent, self.treeCleaner, doRender)
                        self.tree[parent] = pnode
                    end

                    table.insert(pnode.children, node)
                    parent = parent.Parent
                    node = pnode
                end
            end
        end

        -- render tree
        doRender()
        --renderTree(self, self.tree[game], Vector2.zero, "")
    end

    --[[
    local function addStoryModule(self, _, _, list)
        renderStoryModules(self, list)
    end

    local function removeStoryModule(self, _, _, list)
        renderStoryModules(self, list)
    end
    ]]

    --[[
    local function addStoryModule(self, moduleScript, storyData)
        local node = self.tree[moduleScript]
        
        if node then
            node.storyItem = storyListItem({
                Parent = self.container,
                path = "story item ..."
            })

            if countChildGuiObjects(node) > 1 and not node.parentItem then
                node.parentItem = parentListItem({
                    Parent = self.container,
                    path = "parent item ..."
                })
            end

            local p = moduleScript.Parent   -- TODO: handle edge cases where parent isn't in tree ????
            local pnode = self.tree[p]
            
            if countChildGuiObjects(pnode) > 1 and not node.parentItem then
                pnode.parentItem = parentListItem({
                    Parent = self.container,
                    path = "parent item ..."
                })
            end

            -- TODO: push a re-render and re-layout
        else
            node = {
                inst = moduleScript,
                children = {},
                storyItem = storyListItem({
                    Parent = self.container,
                    path = "story path ..."
                }),
                parentItem = nil,
            }
            self.tree[moduleScript] = node

            local p = moduleScript.Parent
            while p do
                local pnode = self.tree[p]
                if pnode then
                    addChildNode(pnode, node)
                    if p ~= game and #pnode.children > 1 and not pnode.parentItem then
                        pnode.parentItem = parentListItem({
                            Parent = self.container,
                            path = "parent path ..."
                        })
                    end
                    break
                else
                    pnode = {
                        inst = p,
                        children = { node }

                    }
                    self.tree[p] = pnode
                end
                node = pnode
                p = p.Parent
            end
        end

        -- self.frames[moduleScript] = storyListItem({
        --     Parent = self.container,
        --     moduleScript = moduleScript,
        --     storyData = storyData,
        -- })
        renderTree(self, self.tree[game], Vector2.zero)
    end

    local function removeStoryModule(self, moduleScript, storyData)
        local frame = self.frames[moduleScript]
        self.frames[moduleScript] = nil
        if frame then
            frame:Destroy()
        end
    end
    ]]

    function StoryListSection:init()
        --[[
        New "UIListLayout" {
            Parent = self.container,
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        }
        ]]

        renderStoryModules(self, State.stories)
        State.storyAdded:connect(function() 
            renderStoryModules(self, State.stories)
        end)
        State.storyRemoved:connect(function() 
            renderStoryModules(self, State.stories)
        end)
        --[[
        for moduleScript, storyData in State.stories do
            addStoryModule(self, moduleScript, storyData)
        end
        State.storyAdded:connect(function(moduleScript, storyData) 
            addStoryModule(self, moduleScript, storyData)
        end)
        State.storyRemoved:connect(function(moduleScript, storyData) 
            removeStoryModule(self, moduleScript, storyData)
        end)
        ]]
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

            [Sub] = {
                StoryListHeader = New "TextLabel" {
                    Size = UDim2.new(0, 150, 0, 24),
                    BackgroundColor3 = Color3.fromHSV(UI_HUE, UI_SAT, 0.25),
                    TextSize = 22,
                    TextColor3 = Color3.fromHSV(0, 0, 0.7),
                    Font = Enum.Font.SourceSans,
                    Text = "Stories",
                },
                StoryList = New "Frame" {
                    Position = UDim2.new(0, 0, 0, 24),
                    Size = UDim2.new(0, 150, 1, -24),
                    BackgroundColor3 = Color3.fromHSV(UI_HUE, UI_SAT, 0.3),
                    ClipsDescendants = true,
                    [Ref "storyListFrame"] = self
                },
                PreviewHeaderFrame = New "Frame" {
                    Position = UDim2.new(0, 150, 0, 0),
                    Size = UDim2.new(1, -150, 0, 24),
                    BackgroundColor3 = Color3.fromHSV(UI_HUE, UI_SAT, 0.2),
                    [Ref "header"] = previewProps
                },
                PreviewContainerFrame = New "Frame" {
                    Position = UDim2.new(0, 150, 0, 24),
                    Size = UDim2.new(1, -150, 1, -2 * 24),
                    BackgroundTransparency = 1,
                    [Ref "container"] = previewProps
                },
                PreviewFooterFrame = New "Frame" {
                    AnchorPoint = Vector2.new(0, 1),
                    Position = UDim2.new(0, 150, 1, 0),
                    Size = UDim2.new(1, -150, 0, 24),
                    BackgroundColor3 = Color3.fromHSV(UI_HUE, UI_SAT, 0.2),
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