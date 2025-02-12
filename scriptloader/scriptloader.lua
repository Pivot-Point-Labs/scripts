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

local config = ac.configValues({ url = "", autofix = false })
local codeFunctions = nil

if config.url == "" then return false end

web.get(config.url, {}, function (err, response)
    if err ~= nil or response.status ~= 200 then
        ac.debug("WEB ERROR:", err)
        ac.debug("Response Status: ", response.status)
        return
    end

    local codeString = response.body

    if config.autofix == true then
        if not string.match(codeString, "^%s*return%s*{.*[Uu]pdate.*}") or not string.match(codeString, "return%s*{.*[Dd]raw3D.*}") then
            
            local retfixCode = [[
local rtable = {}
if type(script.update) == "function" then table.insert(rtable, script.update) elseif type(update) == "function" then table.insert(rtable, update) else table.insert(rtable, nil) end
if type(script.draw3D) == "function" then table.insert(rtable, script.draw3D) elseif type(draw3D) == "function" then table.insert(rtable, draw3D) else table.insert(rtable, nil) end
return rtable
            ]]

            codeString = codeString .. "\n".. retfixCode
            ac.debug("code", codeString)
        end
    end

    

    try(function ()
        local code = assert(loadstring(codeString))
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
