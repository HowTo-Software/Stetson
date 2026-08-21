-- STETSON Mod: Cowboy Hard Hat (Server authority for MP)

local DEBUG_STETSON = true

local function debugLog(message)
    if DEBUG_STETSON then
        print("[STETSON][Server] " .. tostring(message))
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

    -- Compatibility path for older API signatures.
    return player:getWornItem("Hat")
end

local function updateCowboyHardHat(player)
    if not player then return end

    local hat = getWornHat(player)
    local hatFullType = hat and hat.getFullType and hat:getFullType() or "nil"
    local traits = player:getTraits()
    local modData = player:getModData()
    local wearingHat = isStetsonHat(hat)

    local username = player.getUsername and player:getUsername() or "unknown"
    debugLog("Update for " .. tostring(username) .. ". Hat=" .. tostring(hatFullType) .. " wearingHat=" .. tostring(wearingHat))

    for _, traitSpec in ipairs(GRANTED_TRAITS) do
        if wearingHat then
            if not traits:contains(traitSpec.id) then
                traits:add(traitSpec.id)
                modData[traitSpec.key] = true
                debugLog("Added trait " .. traitSpec.id)
            end
        elseif modData[traitSpec.key] then
            if traits:contains(traitSpec.id) then
                traits:remove(traitSpec.id)
                debugLog("Removed trait " .. traitSpec.id)
            end
            modData[traitSpec.key] = nil
        end
    end
end

Events.OnClientCommand.Add(function(module, command, player, args)
    debugLog("OnClientCommand module=" .. tostring(module) .. " command=" .. tostring(command))
    if module == "STETSON" and command == "clothingUpdated" then
        updateCowboyHardHat(player)
    end
end)
