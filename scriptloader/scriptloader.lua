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

local config = ac.configValues({ url = "" })
local codeFunctions = nil

if config.url == "" then return false end

web.get(config.url, {}, function (err, response)
    if err ~= nil or response.status ~= 200 then
        ac.debug("WEB ERROR:", err)
        ac.debug("Response Status: ", response.status)
        return
     end

    try(function ()
        local code = assert(loadstring(response.body))
        codeFunctions = code()
    end, function (err)
        ac.debug("Script execution error:", err)
    end)
end)

function script.update(dt)
    if codeFunctions and codeFunctions[1] then
        codeFunctions[1](dt)
    end
end

function script.draw3D()
    if codeFunctions and codeFunctions[2] then
        codeFunctions[2]()
    end
end
