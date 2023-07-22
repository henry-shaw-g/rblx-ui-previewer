-- VARIABLES
local SUB = {}
local REF = {}

local propDefaults

-- PRIVATE
local function checkMeta(keyOrValue, against: {[any]: any})
    return typeof(keyOrValue) == "table" and getmetatable(keyOrValue) == against
end

-- MODULE
local GuiLib = {}

local function applySub(instance, sub)
    local kind = typeof(sub)
    if kind == "Instance" then
        sub.Parent = instance
    elseif kind == "table" then
        for k, subsub in sub do
            if typeof(subsub) == "Instance" and typeof(k) == "string" then
                subsub.Name = k
            end
            applySub(instance, subsub)
        end
    else
        error(`[GuiLib]: Invalid sub member type. Type: {kind}`)
    end
end

local function applyRef(instance, refInData, t)
    t[refInData._atKey] = instance
end

local function applyInstanceDefaults(props, class)
    local classDefaults = propDefaults[class]
    if not classDefaults then
        return
    end

    for prop, value in classDefaults do
        if not props[prop] then
            props[prop] = value
        end
    end
end

local specialKeyHandlers = {
    [SUB] = applySub,
}
local specialMetaHandlers = {
    [REF] = applyRef,
}

local function applyInstanceProps(i: Instance, props)
    local special = {}
        local specialMeta = {}

        applyInstanceDefaults(props, i.ClassName)

        for prop, value in props do
            if prop == "Parent" then
                continue
            end
            if typeof(prop) == "table" then
                if specialKeyHandlers[prop] then
                    table.insert(special, {prop, value})
                elseif specialMetaHandlers[getmetatable(prop)] then
                    table.insert(specialMeta, {prop, value})
                end
            else
                (i::any)[prop] = value -- stinky type checker
            end
        end

        for _, propAndValue in special do
            specialKeyHandlers[propAndValue[1]](i, propAndValue[2])
        end

        for _, propAndValue in specialMeta do
            specialMetaHandlers[getmetatable(propAndValue[1])](i, propAndValue[1], propAndValue[2])
        end

        if props.Parent then
            i.Parent = props.Parent
        end
end

function GuiLib.mend(instance)
    return function(props)
        applyInstanceProps(instance, props)
    end
end

function GuiLib.new(class: string)
    return function(props)
        local i = Instance.new(class)
        applyInstanceProps(i, props)
        return i
    end
end

function GuiLib.ref(atKey: string)
    return setmetatable({
        _atKey = atKey
    }, REF)
end

function GuiLib.inheritRefs(into, from)
    for prop, val in from do
        if checkMeta(prop, REF) then
            into[prop] = val
        end
    end
    return into
end

GuiLib.sub = SUB

do
    propDefaults = {
        Frame = {
            BorderSizePixel = 0,
        },
        ScrollingFrame = {
            BorderSizePixel = 0,
        },
        TextLabel = {
            BorderSizePixel = 0,
        },
        TextBox = {
            BorderSizePixel = 0,
        },
        TextButton = {
            BorderSizePixel = 0,
        },
        ImageLabel = {
            BorderSizePixel = 0,
        },
        ImageButton = {
            BorderSizePixel = 0,
        },
    }
end

return GuiLib