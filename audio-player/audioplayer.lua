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

local config = ac.configValues({
    filename = '',
    use3D = false,
    use2DAudioFade = true,
    useOcclusion = false,
    loop = true,
    insideConeAngle = 360,
    outsideConeAngle = 360,
    outsideVolume = 1,
    minDistance = 1,
    maxDistance = 100,
    dopplerEffect = 0,
    volume = 1,
    reverbResponse = false,
    position = vec3(0, 0, 0),
    direction = vec3(1, 0, 0),
    up = vec3(0, 1, 0),
    velocity = vec3(0, 0, 0)
})

local volume = config.volume
local use2DAudioFade = config.use2DAudioFade
local reverb = config.reverbResponse
local position = config.position
local direction = config.direction
local up = config.up
local velocity = config.velocity;

table.removeItem(config, volume)
table.removeItem(config, use2DAudioFade)
table.removeItem(config, reverb)
table.removeItem(config, position)
table.removeItem(config, direction)
table.removeItem(config, up)
table.removeItem(config, velocity);

local e = ac.AudioEvent.fromFile(config, reverb)
if volume then
    e.volume = volume
end
if config.filename == '' then
    ac.setMessage("ERROR", "Please set the audio-player filename")
else
    e:setPosition(position, direction, up, velocity)
    e:start()
end


function script.update(dt)
    local distance = ac.getCameraPosition():distance(position)     -- distance between camera and audio source
    if distance >= config.maxDistance then                         -- if distance is creater than configured max, stop audio
        e:stop()
    else
        if use2DAudioFade == true then     -- 2D audio has no fade by default
            local distancePercentage = distance / config.maxDistance
            local distancePercentageInvert = 1 - distancePercentage
            local volumeFromDistance = distancePercentageInvert * volume
            e.volume = volumeFromDistance
        end

        if distance < config.maxDistance then     -- if distance is smaller than configured max, start audio.
            if e:isPaused() then                  -- dont resume anything already playing
                e:resume()
            end
        end
    end
end
