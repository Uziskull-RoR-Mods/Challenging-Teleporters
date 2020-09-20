local connectedPlayerList

local dcCB = callback.create("onPlayerDisconnect")

callback.register("onStep", function()
    if net.online and net.host then
        if not connectedPlayerList then
            connectedPlayerList = {}
        end
        if #connectedPlayerList == 0 then
            for _, p in ipairs(misc.players) do
                connectedPlayerList[#connectedPlayerList + 1] = {p=p, x=p.x, y=p.y}
            end
        end
        for i, pinf in ipairs(connectedPlayerList) do
            if pinf then
                if not pinf.p:isValid() then
                    connectedPlayerList[i] = false
                    dcCB(i, pinf.x, pinf.y)
                else
                    pinf.x, pinf.y = pinf.p.x, pinf.p.y
                end
            end
        end
    end
end)