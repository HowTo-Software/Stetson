-- STETSON Mod: notify server when local clothing changes

local DEBUG_STETSON = true

local function debugLog(message)
    if DEBUG_STETSON then
        print("[STETSON][Client] " .. tostring(message))
    end
end

local HATS = {
    ["STETSON.CowboyHat_Black"] = true,
    ["STETSON.CowboyHat_White"] = true,
    ["STETSON.CowboyHat_Brown"] = true,
    ["STETSON.CowboyHat_Pink"] = true,
}

local GRANTED_TRAITS = {
    { id = "Hunter", key = "STETSON_TraitGranted_Hunter" },
    { id = "Formerscout", key = "STETSON_TraitGranted_Formerscout" },
    { id = "Outdoorsman", key = "STETSON_TraitGranted_Outdoorsman" },
}

local function isStetsonHat(item)
    if not item or not item.getFullType then
        return false
    end

    return HATS[item:getFullType()] == true
end

local function getWornHat(player)
    if not player then
        return nil
    end

    if player.getBodyLocationGroup then
        local group = player:getBodyLocationGroup()
        if group and group.getLocation then
            local hatLocation = group:getLocation("Hat")
            if hatLocation then
                return player:getWornItem(hatLocation)
            end
        end
    end

    return player:getWornItem("Hat")
end

local function updateCowboyHardHatLocal(player)
    if not player then return end

    local hat = getWornHat(player)
    local hatFullType = hat and hat.getFullType and hat:getFullType() or "nil"
    local traits = player:getTraits()
    local modData = player:getModData()
    local wearingHat = isStetsonHat(hat)

    debugLog("Local update. Hat=" .. tostring(hatFullType) .. " wearingHat=" .. tostring(wearingHat))

    for _, traitSpec in ipairs(GRANTED_TRAITS) do
        if wearingHat then
            if not traits:contains(traitSpec.id) then
                traits:add(traitSpec.id)
                modData[traitSpec.key] = true
            end
        elseif modData[traitSpec.key] then
            if traits:contains(traitSpec.id) then
                traits:remove(traitSpec.id)
            end
            modData[traitSpec.key] = nil
        end
    end
end

local function shouldSyncForHatState(player, force)
    local modData = player:getModData()
    if force then
        modData.STETSON_LastWearingHat = nil
    end

    local hat = getWornHat(player)
    local wearingHat = isStetsonHat(hat)
    local last = modData.STETSON_LastWearingHat

    if last == nil or last ~= wearingHat then
        modData.STETSON_LastWearingHat = wearingHat
        debugLog("Hat state changed. last=" .. tostring(last) .. " new=" .. tostring(wearingHat) .. " force=" .. tostring(force))
        return true
    end

    debugLog("Hat state unchanged. value=" .. tostring(wearingHat))

    return false
end

local function syncCowboyHardHatState()
    local player = getPlayer()
    if not player then
        return
    end

    if isClient() then
        debugLog("Sending client command STETSON/clothingUpdated")
        sendClientCommand("STETSON", "clothingUpdated", nil)
        return
    end

    -- Singleplayer path: no client->server command pipeline.
    debugLog("Singleplayer local update")
    updateCowboyHardHatLocal(player)
end

Events.OnClothingUpdated.Add(function(character)
    local player = getPlayer()
    if character ~= player then
        return
    end

    debugLog("OnClothingUpdated fired for local player")

    if shouldSyncForHatState(player, false) then
        syncCowboyHardHatState()
    end
end)

-- Ensure trait state is synced immediately when the local player spawns/loads.
Events.OnCreatePlayer.Add(function(playerIndex, player)
    if player ~= getPlayer() then
        return
    end

    debugLog("OnCreatePlayer fired for local player index=" .. tostring(playerIndex))

    if shouldSyncForHatState(player, true) then
        syncCowboyHardHatState()
    end
end)
