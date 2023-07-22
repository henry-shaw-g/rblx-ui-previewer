local Cleaner = {}

--[[
	Cleaner: Class that handles cleaning up data after some kind of session, similar to Maid and Janitor
	author: Wafflechad
	date: December 2022
	todo:
		* cleaner chaining
		* class destruction
		* protected class
]]

-- TYPES
type CASCallback = (string, Enum.UserInputState, InputObject)->(Enum.ContextActionResult?)

export type Cleanable = Instance | RBXScriptConnection | () -> (...any) | {[any]: any} | typeof(setmetatable({}, {} :: any)) | Cleaner
export type Linkable = () -> (...any) | Cleaner

export type Cleaner = {
	-- fields
	cleanables: {[any]: Cleanable},
	linked: {[any]: Linkable},
	contextActionBindings: {[any]: string},
	renderStepBindings: {[any]: string},
	-- methods
	clean: (Cleaner) -> (),
	add: (Cleaner, any?) -> (),
	addMethod: <T>(Cleaner, T, (T, ...any?) -> ()) -> (),
	addContextActionBinding: (Cleaner, string) -> (),
	makeContextActionBinding: (Cleaner, string, CASCallback, boolean, ...any) -> (),
	addRenderStepBinding: (Cleaner, string) -> (),
	makeRenderStepBinding: (Cleaner, string, number, (number) -> ()) -> (),
}

-- SERVICES
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

-- PRIVATE
local CLEANER_META = {
	__index = Cleaner
}

local METHOD_META = {
	__call = function(self, ...)
		return self._method(self._obj, ...)
	end
}

local function cleanThing(thing: Cleanable)
	local typeOfThing = typeof(thing)
	if typeOfThing == "RBXScriptConnection" then
		(thing::RBXScriptConnection):Disconnect()
	elseif typeOfThing == "Instance" then
		(thing::Instance):Destroy()
	elseif typeOfThing == "function" then
		(thing::()->())()
	elseif typeOfThing == "table" then
		local meta = getmetatable(thing :: any)
		if meta == CLEANER_META then
			(thing :: any):clean()
		elseif meta == METHOD_META then
			(thing :: any)()	
		end
	end
end

-- PUBLIC
Cleaner.__index = Cleaner
function Cleaner.new(): Cleaner
	local self = setmetatable({
		cleanables = {},
		linked = {},
		contextActionBindings = {},
		renderStepBindings = {},
	}, CLEANER_META)

	return self
end

function Cleaner:clean()
	for _, thing in self.linked do
		cleanThing(thing)
	end
	for _, thing in self.cleanables do
		cleanThing(thing)
	end
	table.clear(self.cleanables)
	for _, binding in self.contextActionBindings do
		ContextActionService:UnbindAction(binding)
	end
	table.clear(self.contextActionBindings)
	for _, binding in self.renderStepBindings do
		RunService:UnbindFromRenderStep(binding)
	end
	table.clear(self.renderStepBindings)
end

-- instances (and connections)
function Cleaner:add(thing: Cleanable)
	table.insert(self.cleanables, thing)
end

function Cleaner:link(thing: Linkable)
	table.insert(self.linked, thing)
end

-- utility adder which adds a method (object and function)
function Cleaner:addMethod<T>(thing: T, method: (T, ...any?) -> ())
	table.insert(self.cleanables, setmetatable({
		_obj = thing,
		_method = method,
	}, METHOD_META))
end

-- CAS bindings
function Cleaner:addContextActionBinding(binding: string)
	table.insert(self.contextActionBindings, binding)
end

--(Cleaner, string, CASCallback, boolean, ...any)
function Cleaner:makeContextActionBinding(binding: string, callback: CASCallback, touchButton: boolean, ...)
	ContextActionService:BindAction(binding, callback, touchButton, ...)
	table.insert(self.contextActionBindings, binding)
end

-- RunService bindings
function Cleaner:addRenderStepBinding(binding: string)
	table.insert(self.renderStepBindings, binding)
end

function Cleaner:makeRenderStepBinding(binding: string, priority: number, callback)
	RunService:BindToRenderStep(binding, priority, callback)
	table.insert(self.renderStepBindings, binding)
end

return Cleaner