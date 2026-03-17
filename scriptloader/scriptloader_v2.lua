--[[
Copyright (c) Pivot Point Labs

This program is free software; you can redistribute it and/or modify it
under the terms and conditions of the GNU General Public License,
version 2, as published by the Free Software Foundation.

This program is distributed in the hope it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]--

local config = ac.configValues({ online_url = "" })
local hooks = {}

if config.online_url == "" then
    ac.log("scriptloader: no URL configured — add 'online_url=\"...\"' to config")
    return
end

web.get(config.online_url, {}, function(err, response)
    if err ~= nil or response.status ~= 200 then
        ac.log("scriptloader: fetch failed — " .. tostring(err or response.status))
        return
    end

    local fn, compileErr = loadstring(response.body)
    if not fn then
        ac.log("scriptloader: compile error — " .. tostring(compileErr))
        return
    end

    -- Snapshot our proxies so we can detect if the loaded script overwrites them
    local proxyUpdate = script.update
    local proxyDraw3D = script.draw3D

    local ok, runErr = pcall(fn) -- This runs all code outside of update/draw3D
    if not ok then
        ac.log("scriptloader: runtime error — " .. tostring(runErr))
        return
    end

    -- Script set script.update/draw3D directly (overwrote our proxies)
    if script.update ~= proxyUpdate and type(script.update) == "function" then
        hooks.update = script.update
        script.update = proxyUpdate
    end
    if script.draw3D ~= proxyDraw3D and type(script.draw3D) == "function" then
        hooks.draw3D = script.draw3D
        script.draw3D = proxyDraw3D
    end

    -- Script defined plain globals update/draw3D
    if not hooks.update and type(_G["update"]) == "function" then
        hooks.update = _G["update"]
    end
    if not hooks.draw3D and type(_G["draw3D"]) == "function" then
        hooks.draw3D = _G["draw3D"]
    end

    
end)

function script.update(dt)
    if hooks.update then hooks.update(dt) end
    return 0, 0
end

function script.draw3D()
    if hooks.draw3D then hooks.draw3D() end
end
