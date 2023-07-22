--!nonstrict
--[[
    Signal: Lua sided script signal.
    Author: Wafflechad (hs747)
]]

-- Types --
type Callback = (...any) -> ()

export type Connection = {
    disconnect: () -> ();
}

export type Signal<Args...> = {
    fire: (Signal<Args...>, Args...) -> (),
    connect: (Signal<Args...>, Callback) -> Connection,
    once: (Signal<Args...>, Callback) -> (),
    wait: () -> (Args...)
}

-- Private --
local Connection = {}
Connection.__index = Connection

function Connection.new(signal, callback): Connection
    local self = setmetatable({}, Connection)
    self._callback = callback
    self._signal = signal
    self._index = 0 -- gets set by signal class

    self._disconnected = false

    return self
end

function Connection:disconnect()
    -- prevent multiple disconnectings (would be problematic)
    if self._disconnected then return end
    self._disconnected = true

    local last = self._signal._numConnections

    self._signal._connections[self._index] = self._signal._connections[last]
    self._signal._connections[last] = nil

    self._signal._numConnections -= 1
end


-- more virtual aliases
Connection.Disconnect = Connection.disconnect
Connection.destroy = Connection.disconnect
Connection.Destroy = Connection.disconnect

-- Public --
local Signal = {}
Signal.__index = Signal

function Signal.new<T...>(): Signal<T...>
    local self = setmetatable({}, Signal)
    self._onceCallbacks = {}
    self._connections = {}
    self._numConnections = 0
    return self
end

function Signal:destroy()
    -- clear all listeners
    table.clear(self._onceCallbacks)
    table.clear(self._connections)
    self._numConnections = 0
end

function Signal:fire(...: any?)
    for i = self._numConnections, 1, -1 do -- iterate backwards in case any connections disconnect themselves
        local callback = self._connections[i]._callback
        task.spawn(callback, ...)
    end

    for i = #self._onceCallbacks, 1, -1 do
        local callback = self._onceCallbacks[i]
        task.spawn(callback, ...)
    end
    table.clear(self._onceCallbacks)
end

function Signal:connect(callback: Callback): Connection
    if not (type(callback) == "function") then
        error("Invalid callback.")
    end

    local connection = Connection.new(self, callback)
    self._numConnections += 1
    connection._index = self._numConnections
    self._connections[self._numConnections] = connection

    return connection
end

function Signal:once(callback: Callback)
    if not (type(callback) == "function") then
        error("Invalid callback.")
    end

    self._onceCallbacks[#self._onceCallbacks+1] = callback
end

function Signal:wait()
    local running = coroutine.running()

    self:connect(function(...)
        coroutine.resume(running, ...)
    end)

    return coroutine.yield(running)
end

Signal.Destroy = Signal.destroy
Signal.Fire = Signal.fire
Signal.Connect = Signal.connect
Signal.Once = Signal.once
Signal.Wait = Signal.wait

return Signal