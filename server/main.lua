local KGCore = exports['kg-core']:GetCoreObject()
local availableJobs = Config.AvailableJobs

-- Exports

local function AddCityJob(jobName, toCH)
    if availableJobs[jobName] then return false, 'already added' end
    availableJobs[jobName] = {
        ['label'] = toCH.label,
        ['isManaged'] = toCH.isManaged
    }
    return true, 'success'
end

exports('AddCityJob', AddCityJob)

-- Functions

local function giveStarterItems()
    local Player = KGCore.Functions.GetPlayer(source)
    if not Player then return end
    for _, v in pairs(KGCore.Shared.StarterItems) do
        local info = {}
        if v.item == 'id_card' then
            info.citizenid = Player.PlayerData.citizenid
            info.firstname = Player.PlayerData.charinfo.firstname
            info.lastname = Player.PlayerData.charinfo.lastname
            info.birthdate = Player.PlayerData.charinfo.birthdate
            info.gender = Player.PlayerData.charinfo.gender
            info.nationality = Player.PlayerData.charinfo.nationality
        elseif v.item == 'driver_license' then
            info.firstname = Player.PlayerData.charinfo.firstname
            info.lastname = Player.PlayerData.charinfo.lastname
            info.birthdate = Player.PlayerData.charinfo.birthdate
            info.type = 'Class C Driver License'
        end
        exports['kg-inventory']:AddItem(source, v.item, 1, false, info, 'kg-cityhall:giveStarterItems')
    end
end

-- Callbacks

KGCore.Functions.CreateCallback('kg-cityhall:server:receiveJobs', function(_, cb)
    cb(availableJobs)
end)

-- Events

RegisterNetEvent('kg-cityhall:server:requestId', function(item, hall)
    local src = source
    local Player = KGCore.Functions.GetPlayer(src)
    if not Player then return end
    local itemInfo = Config.Cityhalls[hall].licenses[item]
    if not Player.Functions.RemoveMoney('cash', itemInfo.cost, 'cityhall id') then return TriggerClientEvent('KGCore:Notify', src, ('You don\'t have enough money on you, you need %s cash'):format(itemInfo.cost), 'error') end
    local info = {}
    if item == 'id_card' then
        info.citizenid = Player.PlayerData.citizenid
        info.firstname = Player.PlayerData.charinfo.firstname
        info.lastname = Player.PlayerData.charinfo.lastname
        info.birthdate = Player.PlayerData.charinfo.birthdate
        info.gender = Player.PlayerData.charinfo.gender
        info.nationality = Player.PlayerData.charinfo.nationality
    elseif item == 'driver_license' then
        info.firstname = Player.PlayerData.charinfo.firstname
        info.lastname = Player.PlayerData.charinfo.lastname
        info.birthdate = Player.PlayerData.charinfo.birthdate
        info.type = 'Class C Driver License'
    elseif item == 'weaponlicense' then
        info.firstname = Player.PlayerData.charinfo.firstname
        info.lastname = Player.PlayerData.charinfo.lastname
        info.birthdate = Player.PlayerData.charinfo.birthdate
    else
        return false -- DropPlayer(src, 'Attempted exploit abuse')
    end
    if not exports['kg-inventory']:AddItem(source, item, 1, false, info, 'kg-cityhall:server:requestId') then return end
    TriggerClientEvent('kg-inventory:client:ItemBox', src, KGCore.Shared.Items[item], 'add')
end)

RegisterNetEvent('kg-cityhall:server:sendDriverTest', function(instructors)
    local src = source
    local Player = KGCore.Functions.GetPlayer(src)
    if not Player then return end
    for i = 1, #instructors do
        local citizenid = instructors[i]
        local SchoolPlayer = KGCore.Functions.GetPlayerByCitizenId(citizenid)
        if SchoolPlayer then
            TriggerClientEvent('kg-cityhall:client:sendDriverEmail', SchoolPlayer.PlayerData.source, Player.PlayerData.charinfo)
        else
            local mailData = {
                sender = 'Township',
                subject = 'Driving lessons request',
                message = 'Hello,<br><br>We have just received a message that someone wants to take driving lessons.<br>If you are willing to teach, please contact them:<br>Name: <strong>' .. Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. '<br />Phone Number: <strong>' .. Player.PlayerData.charinfo.phone .. '</strong><br><br>Kind regards,<br>Township Los Santos',
                button = {}
            }
            exports['kg-phone']:sendNewMailToOffline(citizenid, mailData)
        end
    end
    TriggerClientEvent('KGCore:Notify', src, 'An email has been sent to driving schools, and you will be contacted automatically', 'success', 5000)
end)

RegisterNetEvent('kg-cityhall:server:ApplyJob', function(job, cityhallCoords)
    local src = source
    local Player = KGCore.Functions.GetPlayer(src)
    if not Player then return end
    local ped = GetPlayerPed(src)
    local pedCoords = GetEntityCoords(ped)

    local data = {
        ['src'] = src,
        ['job'] = job
    }
    if #(pedCoords - cityhallCoords) >= 20.0 or not availableJobs[job] then
        return false -- DropPlayer(source, "Attempted exploit abuse")
    end
    local JobInfo = KGCore.Shared.Jobs[job]
    Player.Functions.SetJob(data.job, 0)
    TriggerClientEvent('KGCore:Notify', data.src, Lang:t('info.new_job', { job = JobInfo.label }))
end)

RegisterNetEvent('kg-cityhall:server:getIDs', giveStarterItems)

RegisterNetEvent('KGCore:Client:UpdateObject', function()
    KGCore = exports['kg-core']:GetCoreObject()
end)

-- Commands

KGCore.Commands.Add('drivinglicense', 'Give a drivers license to someone', { { 'id', 'ID of a person' } }, true, function(source, args)
    local Player = KGCore.Functions.GetPlayer(source)
    local SearchedPlayer = KGCore.Functions.GetPlayer(tonumber(args[1]))
    if SearchedPlayer then
        if not SearchedPlayer.PlayerData.metadata['licences']['driver'] then
            for i = 1, #Config.DrivingSchools do
                for id = 1, #Config.DrivingSchools[i].instructors do
                    if Config.DrivingSchools[i].instructors[id] == Player.PlayerData.citizenid then
                        SearchedPlayer.PlayerData.metadata['licences']['driver'] = true
                        SearchedPlayer.Functions.SetMetaData('licences', SearchedPlayer.PlayerData.metadata['licences'])
                        TriggerClientEvent('KGCore:Notify', SearchedPlayer.PlayerData.source, 'You have passed! Pick up your drivers license at the town hall', 'success', 5000)
                        TriggerClientEvent('KGCore:Notify', source, ('Player with ID %s has been granted access to a driving license'):format(SearchedPlayer.PlayerData.source), 'success', 5000)
                        break
                    end
                end
            end
        else
            TriggerClientEvent('KGCore:Notify', source, "Can't give permission for a drivers license, this person already has permission", 'error')
        end
    else
        TriggerClientEvent('KGCore:Notify', source, 'Player Not Online', 'error')
    end
end)
