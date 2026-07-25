local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

local _dThread = false

function StartDashboardThread()
    if _dThread then return; end
    _dThread = true

    CreateThread(function()
        GlobalState.AdminPlayerHistory = {}
        Wait(5000)
        while true do
            local t = GlobalState.AdminPlayerHistory or {}
            if #t >= config.Dashboard.maxSamples then
                table.remove(t, 1)
            end

            table.insert(t, {
                count = plsr.Fetch:Count(),
                time = os.time(),
            })

            GlobalState.AdminPlayerHistory = t

            Wait((1000 * 60) * 30)
        end
    end)
end