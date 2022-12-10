local QBCore = exports['qb-core']:GetCoreObject()

-- Blip Creation

Citizen.CreateThread(function()
for k,v in pairs(Config.traderNPCS) do
    local blip = AddBlipForCoord(v.location)
    SetBlipSprite(blip, 214)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.6)
    SetBlipColour(blip, 59)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Christmas Gift Shop")
    EndTextCommandSetBlipName(blip)
    end
end)

Citizen.CreateThread(function()
    TriggerServerEvent("canes:getCanes")

    local shopData = {}
    shopData[1] = {
        header = Config.text.shopTitle,
        isMenuHeader = true
    }
    
    for i=1, #Config.giftBoxes do
        table.insert(shopData, {
            header = Config.giftBoxes[i].name,
            txt = Config.text.shopItem .. tostring(Config.giftBoxes[i].cost),
            params = {
                event = "canes:client:buyBox",
                args = i
            }
        })
    end
    
    shopData[#shopData+1] = {
        header = Config.text.shopClose,
        txt = "",
        params = {
            event = "qb-menu:closeMenu"
        }
    }
    
    for i, traderNPC in pairs(Config.traderNPCS) do
        local hash = GetHashKey(traderNPC.model)
        RequestModel(hash)
        while not HasModelLoaded(hash) do
            Citizen.Wait(100)
        end
    
        traderNPC.ped = CreatePed(0, hash, traderNPC.location, false, false)
        SetEntityAsMissionEntity(traderNPC.ped, true, true)
        FreezeEntityPosition(traderNPC.ped, true)
        SetEntityInvincible(traderNPC.ped, true)
        SetBlockingOfNonTemporaryEvents(traderNPC.ped, true)
        SetEntityHeading(traderNPC.ped, traderNPC.heading)
        exports['qb-target']:AddTargetEntity(Config.traderNPCS[i].ped, {
            options = {
                {
                    icon = "fas fa-hand",
                    label = Config.text.shopCane,
                    canInteract = function()
                        return true
                    end,
                    action = function()
                        exports['qb-menu']:openMenu(shopData)
                    end
                }
            },
            distance = 3.0
        })
    end
end)


RegisterNetEvent("canes:syncModels")
AddEventHandler("canes:syncModels", function(data)
    for i=1, #Config.candyCanes do
        if Config.candyCanes[i].obj then
            DeleteEntity(Config.candyCanes[i].obj)
            SetEntityAsNoLongerNeeded(Config.candyCanes[i].obj)
        end
    end

    Config.candyCanes = data

    for i, candyCane in pairs(Config.candyCanes) do
    
        if not candyCane.taken then
            local hash = GetHashKey(candyCane.model)
            RequestModel(hash)
            while not HasModelLoaded(hash) do
                Citizen.Wait(100)
            end
    
            candyCane.obj = CreateObject(hash, candyCane.location, false, true, true)
            SetEntityAsMissionEntity(candyCane.obj, true, true)
            FreezeEntityPosition(candyCane.obj, true)
            SetEntityHeading(candyCane.obj, candyCane.heading)
            PlaceObjectOnGroundProperly(candyCane.obj)
    

            exports['qb-target']:AddTargetEntity(Config.candyCanes[i].obj, {
                options = {
                    {
                        icon = "fas fa-hand",
                        label = Config.text.pickupCane,
                        canInteract = function()
                            return true
                        end,
                        action = function()
                            QBCore.Functions.Progressbar("pick_cane", Config.text.actionCane, 2000, false, true, {
                                disableMovement = true,
                                disableCarMovement = true,
                                disableMouse = false,
                                disableCombat = true,
                            }, {
                                animDict = 'amb@prop_human_bum_bin@idle_a',
                                anim = 'idle_a',
                                flags = 47,
                            }, {}, {}, function() -- Done
                                TriggerServerEvent("canes:pickupCane", i)
                                ClearPedTasks(PlayerPedId())
                            end, function() -- Cancel
                                ClearPedTasks(PlayerPedId())
                            end)
                        end
                    }
                },
                distance = 3.0
            })
        end
    end
end)

RegisterNetEvent("canes:client:buyBox")
AddEventHandler("canes:client:buyBox", function(item)
    TriggerServerEvent("canes:server:buyBox", item)
end)

RegisterNetEvent("canes:client:openBox")
AddEventHandler("canes:client:openBox", function(item)
    QBCore.Functions.Progressbar("open_box", Config.text.openBox, math.random(2000,3500), false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
		animDict = 'anim@gangops@facility@servers@',
		anim = 'hotwire',
		flags = 16,
	}, {}, {}, function() -- Done
        TriggerServerEvent("canes:server:openBox", item)
        ClearPedTasks(PlayerPedId())
    end, function() -- Cancel
        ClearPedTasks(PlayerPedId())
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for i=1, #Config.candyCanes do
            if Config.candyCanes[i].obj then
                DeleteEntity(Config.candyCanes[i].obj)
                SetEntityAsNoLongerNeeded(Config.candyCanes[i].obj)
            end
        end
    end
end)