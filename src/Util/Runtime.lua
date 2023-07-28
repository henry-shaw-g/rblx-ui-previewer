local Errors = {}

local function pcallSpawnRun(f, state, errFmt, ...)
    state.results = table.pack(xpcall(f, function(err)
        warn(errFmt:format(err, debug.traceback(nil, 2)))
        return err
    end, ...))
    if state.race then
        coroutine.resume(state.thread)
    else
        state.race = true
    end
end

local function pcallSpawnRecieve(state, ...)
    if not state.race then
        state.race = true
        coroutine.yield(state.thread)
    end
    return table.unpack(state.results)
end

function Errors.pcallSpawn<Args...>(f: (Args...) -> (), errFmt, ...: Args...)
    local state = {
        thread = coroutine.running(),
        race = false,
        returned = nil,
    }
    task.spawn(pcallSpawnRun, f, state, errFmt, ...)
    return pcallSpawnRecieve(state)
end

return Errors