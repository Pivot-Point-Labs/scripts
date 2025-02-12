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

if config.url == "" then return false end

web.get(config.url, {}, function (err, response)
    if err ~= nil or response.status ~= 200 then
        ac.debug("WEB ERROR:", err)
        ac.debug("Response Status: ", response.status)
        return
     end

    try(function ()
        loadstring(response.body)()
    end, function (err)
        ac.debug("Script execution error:", err)
    end)
end)

