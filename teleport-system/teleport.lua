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

-- Version: 1.2

ac.storageSetPath("slx_teleportconfig")

local Teleport = class("Teleport")

function Teleport:initialize()
    self.triggerRange = 1.5
    self.spawnRange = 3.1
    self.teleportWindowOpen = false
    self.teleportBlocked = false
    self.teleports = nil

    if ac.getServerIP() == nil then
        if io.fileExists(ac.getFolder(ac.FolderID.CurrentTrack) .. "/extension/teleports.json") then
            
            local teleport = io.load(ac.getFolder(ac.FolderID.CurrentTrack) .. "/extension/teleports.json") or nil
            if teleport then self.teleports = JSON.parse(teleport) else 
                ac.setMessage("Teleports", "Could not load local teleports file")
            end

        else
            self:DownloadConfig()
        end
    else
        self:DownloadConfig()
    end
end

function Teleport:LoadLocalConfig()
    if self.teleports then return end
    if not ac.storage[ac.getTrackID()] then
        ac.setMessage("Teleports", "Local config does not exist. Please make sure you are connected to the internet and try again.")
    else
        self.teleports = JSON.parse(ac.storage[ac.getTrackID()])
    end
    
end

function Teleport:DownloadConfig()
    local onlineConfigUrl = "https://raw.githubusercontent.com/Pivot-Point-Labs/script-configs/refs/heads/main/online/tracks/"..ac.getTrackID().."/teleports.json"
    web.get(onlineConfigUrl, {}, function (err, response)
        if err ~= nil or response.status ~= 200 then self:LoadLocalConfig(); return end
        ac.storage[ac.getTrackID()] = response.body
        self.teleports = JSON.parse(response.body)
    end)
end

function Teleport:CheckCarWithin(carIndex, position, range)
    return ac.getCar(carIndex).position:closerToThan(position, range)
end

function Teleport:GetBlockedSpawns(spawns)
    local blocked = 0
    for spawn_index, spawn in ipairs(spawns) do
        for car_index, car in ac.iterateCars.ordered() do
            if car.position:closerToThan(vec3.new(spawn["position"]), self.spawnRange) then
                blocked = blocked + 1
            end
        end
    end
    return blocked or 0
end

function Teleport:GetUnblockedSpawns(spawns)
    local unblockedSpawns = {}
    for spawn_index, spawn in ipairs(spawns) do
        local isBlocked = false
        for car_index, car in ac.iterateCars.ordered() do
            if car.position:closerToThan(vec3.new(spawn["position"]), self.spawnRange) then
                isBlocked = true
            end
        end
        if isBlocked == false then
            table.insert(unblockedSpawns, spawn)
        end
    end
    return unblockedSpawns
end

function Teleport:GetRandomSpawn(spawns)
    return spawns[math.random(#spawns)]
end

function Teleport:TeleportToLocation(location)
    local name = location[1]
    local positions = location[2].spawns
    local position = positions[math.random(#positions)]

    local unblocked = self:GetUnblockedSpawns(positions)
    local random = self:GetRandomSpawn(unblocked)

    physics.setCarPosition(0, vec3.new(random["position"]), vec3.new(random["heading"]))
end

function Teleport:update(dt)
    if self.teleports == nil then return end
    local selfInsideTrigger = false

    for index, tp_trigger_pos in ipairs(self.teleports["triggers"]) do
        if self:CheckCarWithin(0, vec3.new(tp_trigger_pos), self.triggerRange) then
            selfInsideTrigger = true
            break
        end
    end

    if selfInsideTrigger == true and self.teleportBlocked == false and self.teleportWindowOpen == false then
        self.teleportBlocked = true
        physics.forceUserBrakesFor(3, 0.5)
        self:DrawTeleportWindow()
    end

    if selfInsideTrigger == false and self.teleportBlocked == true then
        self.teleportBlocked = false
    end

end

function Teleport:DrawTeleportWindow()
    self.teleportWindowOpen = true
    ui.modalDialog("Teleport Menu", function()

        local teleported = false
        ui.childWindow("tp_menu_sub", vec2(1050, 440), true, ui.WindowFlags.ThinScrollbar, function ()

            local count = 1
            for index, location in pairs(self.teleports["locations"]) do

                local imageId = string.replace(tostring(index)," ", "") .. tostring(count)
                local imageurl = location["img"] .. "##"..imageId

                if ui.iconButton(imageurl, vec2(256, 144), 5, false, ui.ButtonFlags.None) then
                    self:TeleportToLocation({index, location})
                    teleported = true
                    break
                end

                if ui.itemHovered() then
                    ui.tooltip(vec2(20, 8), function()
                        ui.setNextTextBold()
                        ui.text(index)
                        ui.text("Spawns occupied: " .. self:GetBlockedSpawns(location["spawns"]) .. "/" .. tostring(#location["spawns"]))
                    end)
                end

                if count % 4 ~= 0 and count ~= table.nkeys(self.teleports["locations"]) then
                    ui.sameLine()
                end

                count = count+1
            end
        end)
        
        local CancelClicked = ui.modernButton("Cancel", vec2(-0.1, 40), ui.ButtonFlags.Cancel, ui.Icons.Cancel)
        local discordBtnClicked = ui.smallButton("Created by SLX")
        if ui.itemHovered() then
            ui.tooltip(vec2(20, 8), function()
                ui.text("Click to copy discord invite to clipboard")
            end)
        end

        if discordBtnClicked then
            ac.setClipboardText("https://discord.gg/UXf78EQ8yC")
            ui.toast(ui.Icons.Clipboard, "Discord invite copied to clipboard!")
        end

        return CancelClicked or teleported
    end, true, function()
        self.teleportWindowOpen = false
    end)
end

function Teleport:drawDebug()
    if ac.configValues({debug = true}).debug == false then return end
    if self.teleports == nil then return end

    ac.debug("Car position", ac.getCar(0).position)
    ac.debug("Camera look", -ac.getSim().cameraLook)

    for index, trigger in ipairs(self.teleports["triggers"]) do
        render.debugBox(vec3.new(trigger), vec3.new(self.triggerRange))
        render.debugText(vec3.new(trigger), "TP trigger", rgbm.colors.black, 1.0)
    end
    
    for iL, location in pairs(self.teleports["locations"]) do
        for iS, spawn in ipairs(location["spawns"]) do
            local pos = vec3.new(spawn["position"])
            local range = vec3.new(self.spawnRange)
            local heading = -vec3.new(spawn["heading"])

            local arrowFrom = pos-(heading*1.5)
            arrowFrom.y = pos.y
            local arrowTo = pos + (heading*1.5)
            arrowTo.y = pos.y
            render.debugBox(pos, range, rgbm.colors.blue)
            render.debugArrow(arrowFrom, arrowTo, 0.2, rgbm.colors.cyan)
            render.debugText(pos, iL, rgbm.colors.black, 1.0)
        end
    end
end

local tpInstance = Teleport()

function script.update(dt)
    tpInstance:update(dt)
end

function script.draw3D()
    tpInstance:drawDebug()
end
