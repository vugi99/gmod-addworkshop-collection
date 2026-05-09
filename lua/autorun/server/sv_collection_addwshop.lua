if not SERVER then return end

AWC_VERSION = "0.1.1"

local download_collection_cvar = CreateConVar("sv_collection_clients_download", "", FCVAR_ARCHIVE, "Adds a workshop collection to be downloaded by clients")

local collections_cache_cvar = CreateConVar("sv_collections_cached", "1", FCVAR_ARCHIVE, "Cache responses to use them in case steam api doesn't respond")

local addworkshop_collections = {
    --"3244986374",
}



local api_url = "https://api.steampowered.com/ISteamRemoteStorage/GetCollectionDetails/v1/"

local cache_dir = "collections_cache"
if not file.IsDir( cache_dir, "DATA" ) then
    file.CreateDir(cache_dir)
end

local function CachePath(Collection_ID)
   return  cache_dir .. "/" .. tostring(Collection_ID) .. ".json"
end

local function AddWorkshopResourcesList(Collection_ID, list)
    list = list or {}
    for i, v in ipairs(list) do
        resource.AddWorkshop(tostring(v))
    end

    print("[AWC] AddWorkshopCollection(" .. tostring(Collection_ID) .. ") added " .. tostring(#list) .. " addons to the download list!" )
    --PrintTable(list)
end

local function SaveResourcesList(Collection_ID, list)
    if not list then return end

    local success = file.Write( CachePath(Collection_ID), util.TableToJSON(list) )
    if success then
        print("[AWC] Saved workshop collection '" .. tostring(Collection_ID) .. "' addons ids")
    else
        error("[AWC] Failed to save workshop collection '" .. tostring(Collection_ID) .. "' addons ids")
    end
end

local function AttemptLoadCachedResourcesList(Collection_ID)
    if not collections_cache_cvar:GetBool() then return end

    local data = file.Read(CachePath(Collection_ID), "DATA")
    if data then
        local tbl = util.JSONToTable(data)
        return tbl
    end
end

local function SteamAPIProblemAttemptUseCache(Collection_ID, error_message)
    local addons = AttemptLoadCachedResourcesList(Collection_ID)
    if not addons then
        error(error_message)
        return
    end
    AddWorkshopResourcesList(Collection_ID, addons)
end


function Resource_AddWorkshopCollection(Collection_ID)
    if not tonumber(Collection_ID) then return error("[AWC] Resource_AddWorkshopCollection invalid Collection_ID: " .. tostring(Collection_ID)) end

    --SteamAPIProblemAttemptUseCache(Collection_ID, "[AWC] test use cache")

    --error("stop")
    http.Post( api_url, {collectioncount = "1", ["publishedfileids[0]"] = tostring(Collection_ID)}, function(body, length, headers, code)
        if code ~= 200 then
            SteamAPIProblemAttemptUseCache(Collection_ID, "[AWC] AddWorkshopCollection(" .. tostring(Collection_ID) .. ") http response error: " .. tostring(body))
            return
        end

        local res_data = util.JSONToTable(body)

        --PrintTable(res_data)

        if (res_data.response and res_data.response.result == 1 and res_data.response.resultcount == 1 and res_data.response.collectiondetails and res_data.response.collectiondetails[1] and res_data.response.collectiondetails[1].result == 1) then
            local addons = res_data.response.collectiondetails[1].children

            local added = {}
            for i, v in ipairs(addons or {}) do
                if v.publishedfileid then
                    table.insert(added, tostring(v.publishedfileid))
                end
            end

            AddWorkshopResourcesList(Collection_ID, added)

            if collections_cache_cvar:GetBool() then
                SaveResourcesList(Collection_ID, added)
            end
        else
            SteamAPIProblemAttemptUseCache(Collection_ID, "[AWC] AddWorkshopCollection(" .. tostring(Collection_ID) .. ") steam response invalid")
        end
    end, function (message)
        SteamAPIProblemAttemptUseCache(Collection_ID, "[AWC] AddWorkshopCollection(" .. tostring(Collection_ID) .. ") http error: " .. tostring(message))
    end)
end

for i, v in ipairs(addworkshop_collections) do
    Resource_AddWorkshopCollection(v)
end

local ipe_cvar_val = download_collection_cvar:GetString()
if ipe_cvar_val ~= "" then
    Resource_AddWorkshopCollection(ipe_cvar_val)
else
    --print("download_collection_cvar is invalid")
end

cvars.AddChangeCallback("sv_collection_clients_download", function(convar, oldValue, newValue)
    if oldValue ~= newValue then
        Resource_AddWorkshopCollection(newValue)
    end
end, "addworkshopcollection_callback")

print("[AWC] loaded " .. tostring(AWC_VERSION))