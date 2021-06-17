local isPaused, isDead, pickups = false, false, {}

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if NetworkIsPlayerActive(PlayerId()) then
			TriggerServerEvent('esx:onPlayerJoined')
			break
		end
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
	ESX.PlayerLoaded = true
	ESX.PlayerData = playerData

	-- check if player is coming from loading screen
	if GetEntityModel(PlayerPedId()) == GetHashKey('PLAYER_ZERO') then
		local defaultModel = GetHashKey('a_m_y_stbla_02')
		RequestModel(defaultModel)

		while not HasModelLoaded(defaultModel) do
			Citizen.Wait(10)
		end

		SetPlayerModel(PlayerId(), defaultModel)
		SetPedDefaultComponentVariation(PlayerPedId())
		SetPedRandomComponentVariation(PlayerPedId(), true)
		SetModelAsNoLongerNeeded(defaultModel)
	end

	-- freeze the player
	FreezeEntityPosition(PlayerPedId(), true)

	-- enable PVP
	SetCanAttackFriendly(PlayerPedId(), true, false)
	NetworkSetFriendlyFireOption(true)

	-- disable wanted level
	ClearPlayerWantedLevel(PlayerId())
	SetMaxWantedLevel(0)

	if Config.EnableHud then
		for k,v in ipairs(playerData.accounts) do
			local accountTpl = '<div><img src="img/accounts/' .. v.name .. '.png"/>&nbsp;{{money}}</div>'
			ESX.UI.HUD.RegisterElement('account_' .. v.name, k, 0, accountTpl, {money = ESX.Math.GroupDigits(v.money)})
		end

		local jobTpl = '<div>{{job_label}} - {{grade_label}}</div>'

		if playerData.job.grade_label == '' or playerData.job.grade_label == playerData.job.label then
			jobTpl = '<div>{{job_label}}</div>'
		end

		ESX.UI.HUD.RegisterElement('job', #playerData.accounts, 0, jobTpl, {
			job_label = playerData.job.label,
			grade_label = playerData.job.grade_label
		})
		
		---SECONDJOB INCLUDED
		local job2Tpl = '<div>{{job2_label}} - {{grade2_label}}</div>'

		if playerData.job2.grade_label == '' or playerData.job2.grade_label == playerData.job2.label then
			job2Tpl = '<div>{{job2_label}}</div>'
		end

		ESX.UI.HUD.RegisterElement('job2', #playerData.accounts, 0, job2Tpl, {
			job2_label = playerData.job2.label,
			grade2_label = playerData.job2.grade_label
		})
	end

	ESX.Game.Teleport(PlayerPedId(), {
		x = playerData.coords.x,
		y = playerData.coords.y,
		z = playerData.coords.z + 0.25,
		heading = playerData.coords.heading
	}, function()
		TriggerServerEvent('esx:onPlayerSpawn')
		TriggerEvent('esx:onPlayerSpawn')
		TriggerEvent('playerSpawned') -- compatibility with old scripts, will be removed soon
		TriggerEvent('esx:restoreLoadout')

		Citizen.Wait(4000)
		ShutdownLoadingScreen()
		ShutdownLoadingScreenNui()
		FreezeEntityPosition(PlayerPedId(), false)
		DoScreenFadeIn(10000)
		StartServerSyncLoops()
	end)

	TriggerEvent('esx:loadingScreenOff')
end)

RegisterNetEvent('esx:setMaxWeight')
AddEventHandler('esx:setMaxWeight', function(newMaxWeight) ESX.PlayerData.maxWeight = newMaxWeight end)

AddEventHandler('esx:onPlayerSpawn', function() isDead = false end)
AddEventHandler('esx:onPlayerDeath', function() isDead = true end)

AddEventHandler('skinchanger:modelLoaded', function()
	while not ESX.PlayerLoaded do
		Citizen.Wait(100)
	end

	TriggerEvent('esx:restoreLoadout')
end)

AddEventHandler('esx:restoreLoadout', function()
	local playerPed = PlayerPedId()
	local ammoTypes = {}
	RemoveAllPedWeapons(playerPed, true)

	for k,v in ipairs(ESX.PlayerData.loadout) do
		local weaponName = v.name
		local weaponHash = GetHashKey(weaponName)

		GiveWeaponToPed(playerPed, weaponHash, 0, false, false)
		SetPedWeaponTintIndex(playerPed, weaponHash, v.tintIndex)

		local ammoType = GetPedAmmoTypeFromWeapon(playerPed, weaponHash)

		for k2,v2 in ipairs(v.components) do
			local componentHash = ESX.GetWeaponComponent(weaponName, v2).hash
			GiveWeaponComponentToPed(playerPed, weaponHash, componentHash)
		end

		if not ammoTypes[ammoType] then
			AddAmmoToPed(playerPed, weaponHash, v.ammo)
			ammoTypes[ammoType] = true
		end
	end
end)

RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function(account)
	for k,v in ipairs(ESX.PlayerData.accounts) do
		if v.name == account.name then
			ESX.PlayerData.accounts[k] = account
			break
		end
	end

	if Config.EnableHud then
		ESX.UI.HUD.UpdateElement('account_' .. account.name, {
			money = ESX.Math.GroupDigits(account.money)
		})
	end
end)

RegisterNetEvent('esx:addInventoryItem')
AddEventHandler('esx:addInventoryItem', function(item, count, showNotification)
	for k,v in ipairs(ESX.PlayerData.inventory) do
		if v.name == item then
			ESX.UI.ShowInventoryItemNotification(true, v.label, count - v.count)
			ESX.PlayerData.inventory[k].count = count
			break
		end
	end

	if showNotification then
		ESX.UI.ShowInventoryItemNotification(true, item, count)
	end

	if ESX.UI.Menu.IsOpen('default', 'es_extended', 'inventory') then
		ESX.ShowInventory()
	end
end)

RegisterNetEvent('esx:removeInventoryItem')
AddEventHandler('esx:removeInventoryItem', function(item, count, showNotification)
	for k,v in ipairs(ESX.PlayerData.inventory) do
		if v.name == item then
			ESX.UI.ShowInventoryItemNotification(false, v.label, v.count - count)
			ESX.PlayerData.inventory[k].count = count
			break
		end
	end

	if showNotification then
		ESX.UI.ShowInventoryItemNotification(false, item, count)
	end

	if ESX.UI.Menu.IsOpen('default', 'es_extended', 'inventory') then
		ESX.ShowInventory()
	end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

---SECONDJOB INCLUDED
RegisterNetEvent('esx:setJob2')
AddEventHandler('esx:setJob2', function(job2)
  ESX.PlayerData.job2 = job2
end)

RegisterNetEvent('esx:addWeapon')
AddEventHandler('esx:addWeapon', function(weaponName, ammo)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)

	GiveWeaponToPed(playerPed, weaponHash, ammo, false, false)
end)

RegisterNetEvent('esx:addWeaponComponent')
AddEventHandler('esx:addWeaponComponent', function(weaponName, weaponComponent)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)
	local componentHash = ESX.GetWeaponComponent(weaponName, weaponComponent).hash

	GiveWeaponComponentToPed(playerPed, weaponHash, componentHash)
end)

RegisterNetEvent('esx:setWeaponAmmo')
AddEventHandler('esx:setWeaponAmmo', function(weaponName, weaponAmmo)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)

	SetPedAmmo(playerPed, weaponHash, weaponAmmo)
end)

RegisterNetEvent('esx:setWeaponTint')
AddEventHandler('esx:setWeaponTint', function(weaponName, weaponTintIndex)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)

	SetPedWeaponTintIndex(playerPed, weaponHash, weaponTintIndex)
end)

RegisterNetEvent('esx:removeWeapon')
AddEventHandler('esx:removeWeapon', function(weaponName)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)

	RemoveWeaponFromPed(playerPed, weaponHash)
	SetPedAmmo(playerPed, weaponHash, 0) -- remove leftover ammo
end)

RegisterNetEvent('esx:removeWeaponComponent')
AddEventHandler('esx:removeWeaponComponent', function(weaponName, weaponComponent)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)
	local componentHash = ESX.GetWeaponComponent(weaponName, weaponComponent).hash

	RemoveWeaponComponentFromPed(playerPed, weaponHash, componentHash)
end)

RegisterNetEvent('esx:teleport')
AddEventHandler('esx:teleport', function(coords)
	local playerPed = PlayerPedId()

	-- ensure decmial number
	coords.x = coords.x + 0.0
	coords.y = coords.y + 0.0
	coords.z = coords.z + 0.0

	ESX.Game.Teleport(playerPed, coords)
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	if Config.EnableHud then
		ESX.UI.HUD.UpdateElement('job', {
			job_label = job.label,
			grade_label = job.grade_label
		})
	end
end)

---SECONDJOB INCLUDED
RegisterNetEvent('esx:setJob2')
AddEventHandler('esx:setJob2', function(job2)
	if Config.EnableHud then
		ESX.UI.HUD.UpdateElement('job2', {
			job2_label   = job2.label,
			grade2_label = job2.grade_label
		})
	end
end)

RegisterNetEvent('esx:spawnVehicle')
AddEventHandler('esx:spawnVehicle', function(vehicleName)
	local model = (type(vehicleName) == 'number' and vehicleName or GetHashKey(vehicleName))

	if IsModelInCdimage(model) then
		local playerPed = PlayerPedId()
		local playerCoords, playerHeading = GetEntityCoords(playerPed), GetEntityHeading(playerPed)

		ESX.Game.SpawnVehicle(model, playerCoords, playerHeading, function(vehicle)
			TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
		end)
	else
		TriggerEvent('chat:addMessage', {args = {'^1SYSTEM', 'Invalid vehicle model.'}})
	end
end)

RegisterNetEvent('esx:createPickup')
AddEventHandler('esx:createPickup', function(pickupId, label, coords, type, name, components, tintIndex)
	local function setObjectProperties(object)
		SetEntityAsMissionEntity(object, true, false)
		PlaceObjectOnGroundProperly(object)
		FreezeEntityPosition(object, true)
		SetEntityCollision(object, false, true)

		pickups[pickupId] = {
			obj = object,
			label = label,
			inRange = false,
			coords = vector3(coords.x, coords.y, coords.z)
		}
	end

	if type == 'item_weapon' then
		local weaponHash = GetHashKey(name)
		ESX.Streaming.RequestWeaponAsset(weaponHash)
		local pickupObject = CreateWeaponObject(weaponHash, 50, coords.x, coords.y, coords.z, true, 1.0, 0)
		SetWeaponObjectTintIndex(pickupObject, tintIndex)

		for k,v in ipairs(components) do
			local component = ESX.GetWeaponComponent(name, v)
			GiveWeaponComponentToWeaponObject(pickupObject, component.hash)
		end

		setObjectProperties(pickupObject)
	else
		ESX.Game.SpawnLocalObject('prop_money_bag_01', coords, setObjectProperties)
	end
end)

RegisterNetEvent('esx:createMissingPickups')
AddEventHandler('esx:createMissingPickups', function(missingPickups)
	for pickupId,pickup in pairs(missingPickups) do
		TriggerEvent('esx:createPickup', pickupId, pickup.label, pickup.coords, pickup.type, pickup.name, pickup.components, pickup.tintIndex)
	end
end)

RegisterNetEvent('esx:registerSuggestions')
AddEventHandler('esx:registerSuggestions', function(registeredCommands)
	for name,command in pairs(registeredCommands) do
		if command.suggestion then
			TriggerEvent('chat:addSuggestion', ('/%s'):format(name), command.suggestion.help, command.suggestion.arguments)
		end
	end
end)

RegisterNetEvent('esx:removePickup')
AddEventHandler('esx:removePickup', function(pickupId)
	if pickups[pickupId] and pickups[pickupId].obj then
		ESX.Game.DeleteObject(pickups[pickupId].obj)
		pickups[pickupId] = nil
	end
end)

RegisterNetEvent('esx:deleteVehicle')
AddEventHandler('esx:deleteVehicle', function(radius)
	local playerPed = PlayerPedId()

	if radius and tonumber(radius) then
		radius = tonumber(radius) + 0.01
		local vehicles = ESX.Game.GetVehiclesInArea(GetEntityCoords(playerPed), radius)

		for k,entity in ipairs(vehicles) do
			local attempt = 0

			while not NetworkHasControlOfEntity(entity) and attempt < 100 and DoesEntityExist(entity) do
				Citizen.Wait(100)
				NetworkRequestControlOfEntity(entity)
				attempt = attempt + 1
			end

			if DoesEntityExist(entity) and NetworkHasControlOfEntity(entity) then
				ESX.Game.DeleteVehicle(entity)
			end
		end
	else
		local vehicle, attempt = ESX.Game.GetVehicleInDirection(), 0

		if IsPedInAnyVehicle(playerPed, true) then
			vehicle = GetVehiclePedIsIn(playerPed, false)
		end

		while not NetworkHasControlOfEntity(vehicle) and attempt < 100 and DoesEntityExist(vehicle) do
			Citizen.Wait(100)
			NetworkRequestControlOfEntity(vehicle)
			attempt = attempt + 1
		end

		if DoesEntityExist(vehicle) and NetworkHasControlOfEntity(vehicle) then
			ESX.Game.DeleteVehicle(vehicle)
		end
	end
end)

-- Pause menu disables HUD display
if Config.EnableHud then
	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(300)

			if IsPauseMenuActive() and not isPaused then
				isPaused = true
				ESX.UI.HUD.SetDisplay(0.0)
			elseif not IsPauseMenuActive() and isPaused then
				isPaused = false
				ESX.UI.HUD.SetDisplay(1.0)
			end
		end
	end)

	AddEventHandler('esx:loadingScreenOff', function()
		ESX.UI.HUD.SetDisplay(1.0)
	end)
end

function StartServerSyncLoops()
	-- keep track of ammo
	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(0)

			if isDead then
				Citizen.Wait(500)
			else
				local playerPed = PlayerPedId()

				if IsPedShooting(playerPed) then
					local _,weaponHash = GetCurrentPedWeapon(playerPed, true)
					local weapon = ESX.GetWeaponFromHash(weaponHash)

					if weapon then
						local ammoCount = GetAmmoInPedWeapon(playerPed, weaponHash)
						TriggerServerEvent('esx:updateWeaponAmmo', weapon.name, ammoCount)
					end
				end
			end
		end
	end)

	-- sync current player coords with server
	Citizen.CreateThread(function()
		local previousCoords = vector3(ESX.PlayerData.coords.x, ESX.PlayerData.coords.y, ESX.PlayerData.coords.z)

		while true do
			Citizen.Wait(1000)
			local playerPed = PlayerPedId()

			if DoesEntityExist(playerPed) then
				local playerCoords = GetEntityCoords(playerPed)
				local distance = #(playerCoords - previousCoords)

				if distance > 1 then
					previousCoords = playerCoords
					local playerHeading = ESX.Math.Round(GetEntityHeading(playerPed), 1)
					local formattedCoords = {x = ESX.Math.Round(playerCoords.x, 1), y = ESX.Math.Round(playerCoords.y, 1), z = ESX.Math.Round(playerCoords.z, 1), heading = playerHeading}
					TriggerServerEvent('esx:updateCoords', formattedCoords)
				end
			end
		end
	end)
end



-- Pickups
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()
		local playerCoords, letSleep = GetEntityCoords(playerPed), true
		local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer(playerCoords)

		for pickupId,pickup in pairs(pickups) do
			local distance = #(playerCoords - pickup.coords)

			if distance < 5 then
				local label = pickup.label
				letSleep = false

				if distance < 1 then
					if IsControlJustReleased(0, 38) then
						if IsPedOnFoot(playerPed) and (closestDistance == -1 or closestDistance > 3) and not pickup.inRange then
							pickup.inRange = true

							local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
							ESX.Streaming.RequestAnimDict(dict)
							TaskPlayAnim(playerPed, dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
							Citizen.Wait(1000)

							TriggerServerEvent('esx:onPickup', pickupId)
							PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
						end
					end

					label = ('%s~n~%s'):format(label, _U('threw_pickup_prompt'))
				end

				ESX.Game.Utils.DrawText3D({
					x = pickup.coords.x,
					y = pickup.coords.y,
					z = pickup.coords.z + 0.25
				}, label, 1.2, 1)
			elseif pickup.inRange then
				pickup.inRange = false
			end
		end

		if letSleep then
			Citizen.Wait(500)
		end
	end
end)

local requestedIpl = {
"h4_mph4_terrain_01_grass_0",
"h4_mph4_terrain_01_grass_1",
"h4_mph4_terrain_02_grass_0",
"h4_mph4_terrain_02_grass_1",
"h4_mph4_terrain_02_grass_2",
"h4_mph4_terrain_02_grass_3",
"h4_mph4_terrain_04_grass_0",
"h4_mph4_terrain_04_grass_1",
"h4_mph4_terrain_05_grass_0",
"h4_mph4_terrain_06_grass_0",
"h4_islandx_terrain_01",
"h4_islandx_terrain_01_lod",
"h4_islandx_terrain_01_slod",
"h4_islandx_terrain_02",
"h4_islandx_terrain_02_lod",
"h4_islandx_terrain_02_slod",
"h4_islandx_terrain_03",
"h4_islandx_terrain_03_lod",
"h4_islandx_terrain_04",
"h4_islandx_terrain_04_lod",
"h4_islandx_terrain_04_slod",
"h4_islandx_terrain_05",
"h4_islandx_terrain_05_lod",
"h4_islandx_terrain_05_slod",
"h4_islandx_terrain_06",
"h4_islandx_terrain_06_lod",
"h4_islandx_terrain_06_slod",
"h4_islandx_terrain_props_05_a",
"h4_islandx_terrain_props_05_a_lod",
"h4_islandx_terrain_props_05_b",
"h4_islandx_terrain_props_05_b_lod",
"h4_islandx_terrain_props_05_c",
"h4_islandx_terrain_props_05_c_lod",
"h4_islandx_terrain_props_05_d",
"h4_islandx_terrain_props_05_d_lod",
"h4_islandx_terrain_props_05_d_slod",
"h4_islandx_terrain_props_05_e",
"h4_islandx_terrain_props_05_e_lod",
"h4_islandx_terrain_props_05_e_slod",
"h4_islandx_terrain_props_05_f",
"h4_islandx_terrain_props_05_f_lod",
"h4_islandx_terrain_props_05_f_slod",
"h4_islandx_terrain_props_06_a",
"h4_islandx_terrain_props_06_a_lod",
"h4_islandx_terrain_props_06_a_slod",
"h4_islandx_terrain_props_06_b",
"h4_islandx_terrain_props_06_b_lod",
"h4_islandx_terrain_props_06_b_slod",
"h4_islandx_terrain_props_06_c",
"h4_islandx_terrain_props_06_c_lod",
"h4_islandx_terrain_props_06_c_slod",
"h4_mph4_terrain_01",
"h4_mph4_terrain_01_long_0",
"h4_mph4_terrain_02",
"h4_mph4_terrain_03",
"h4_mph4_terrain_04",
"h4_mph4_terrain_05",
"h4_mph4_terrain_06",
"h4_mph4_terrain_06_strm_0",
"h4_mph4_terrain_lod",
"h4_mph4_terrain_occ_00",
"h4_mph4_terrain_occ_01",
"h4_mph4_terrain_occ_02",
"h4_mph4_terrain_occ_03",
"h4_mph4_terrain_occ_04",
"h4_mph4_terrain_occ_05",
"h4_mph4_terrain_occ_06",
"h4_mph4_terrain_occ_07",
"h4_mph4_terrain_occ_08",
"h4_mph4_terrain_occ_09",
"h4_boatblockers",
"h4_islandx",
"h4_islandx_disc_strandedshark",
"h4_islandx_disc_strandedshark_lod",
"h4_islandx_disc_strandedwhale",
"h4_islandx_disc_strandedwhale_lod",
"h4_islandx_props",
"h4_islandx_props_lod",
"h4_islandx_sea_mines",
"h4_mph4_island",
"h4_mph4_island_long_0",
"h4_mph4_island_strm_0",
"h4_aa_guns",
"h4_aa_guns_lod",
"h4_beach",
"h4_beach_bar_props",
"h4_beach_lod",
"h4_beach_party",
"h4_beach_party_lod",
"h4_beach_props",
"h4_beach_props_lod",
"h4_beach_props_party",
"h4_beach_props_slod",
"h4_beach_slod",
"h4_islandairstrip",
"h4_islandairstrip_doorsclosed",
"h4_islandairstrip_doorsclosed_lod",
"h4_islandairstrip_doorsopen",
"h4_islandairstrip_doorsopen_lod",
"h4_islandairstrip_hangar_props",
"h4_islandairstrip_hangar_props_lod",
"h4_islandairstrip_hangar_props_slod",
"h4_islandairstrip_lod",
"h4_islandairstrip_props",
"h4_islandairstrip_propsb",
"h4_islandairstrip_propsb_lod",
"h4_islandairstrip_propsb_slod",
"h4_islandairstrip_props_lod",
"h4_islandairstrip_props_slod",
"h4_islandairstrip_slod",
"h4_islandxcanal_props",
"h4_islandxcanal_props_lod",
"h4_islandxcanal_props_slod",
"h4_islandxdock",
"h4_islandxdock_lod",
"h4_islandxdock_props",
"h4_islandxdock_props_2",
"h4_islandxdock_props_2_lod",
"h4_islandxdock_props_2_slod",
"h4_islandxdock_props_lod",
"h4_islandxdock_props_slod",
"h4_islandxdock_slod",
"h4_islandxdock_water_hatch",
"h4_islandxtower",
"h4_islandxtower_lod",
"h4_islandxtower_slod",
"h4_islandxtower_veg",
"h4_islandxtower_veg_lod",
"h4_islandxtower_veg_slod",
"h4_islandx_barrack_hatch",
"h4_islandx_barrack_props",
"h4_islandx_barrack_props_lod",
"h4_islandx_barrack_props_slod",
"h4_islandx_checkpoint",
"h4_islandx_checkpoint_lod",
"h4_islandx_checkpoint_props",
"h4_islandx_checkpoint_props_lod",
"h4_islandx_checkpoint_props_slod",
"h4_islandx_maindock",
"h4_islandx_maindock_lod",
"h4_islandx_maindock_props",
"h4_islandx_maindock_props_2",
"h4_islandx_maindock_props_2_lod",
"h4_islandx_maindock_props_2_slod",
"h4_islandx_maindock_props_lod",
"h4_islandx_maindock_props_slod",
"h4_islandx_maindock_slod",
"h4_islandx_mansion",
"h4_islandx_mansion_b",
"h4_islandx_mansion_b_lod",
"h4_islandx_mansion_b_side_fence",
"h4_islandx_mansion_b_slod",
"h4_islandx_mansion_entrance_fence",
"h4_islandx_mansion_guardfence",
"h4_islandx_mansion_lights",
"h4_islandx_mansion_lockup_01",
"h4_islandx_mansion_lockup_01_lod",
"h4_islandx_mansion_lockup_02",
"h4_islandx_mansion_lockup_02_lod",
"h4_islandx_mansion_lockup_03",
"h4_islandx_mansion_lockup_03_lod",
"h4_islandx_mansion_lod",
"h4_islandx_mansion_office",
"h4_islandx_mansion_office_lod",
"h4_islandx_mansion_props",
"h4_islandx_mansion_props_lod",
"h4_islandx_mansion_props_slod",
"h4_islandx_mansion_slod",
"h4_islandx_mansion_vault",
"h4_islandx_mansion_vault_lod",
"h4_island_padlock_props",
-- "h4_mansion_gate_broken",
"h4_mansion_gate_closed",
"h4_mansion_remains_cage",
"h4_mph4_airstrip",
"h4_mph4_airstrip_interior_0_airstrip_hanger",
"h4_mph4_beach",
"h4_mph4_dock",
"h4_mph4_island_lod",
"h4_mph4_island_ne_placement",
"h4_mph4_island_nw_placement",
"h4_mph4_island_se_placement",
"h4_mph4_island_sw_placement",
"h4_mph4_mansion",
"h4_mph4_mansion_b",
"h4_mph4_mansion_b_strm_0",
"h4_mph4_mansion_strm_0",
"h4_mph4_wtowers",
"h4_ne_ipl_00",
"h4_ne_ipl_00_lod",
"h4_ne_ipl_00_slod",
"h4_ne_ipl_01",
"h4_ne_ipl_01_lod",
"h4_ne_ipl_01_slod",
"h4_ne_ipl_02",
"h4_ne_ipl_02_lod",
"h4_ne_ipl_02_slod",
"h4_ne_ipl_03",
"h4_ne_ipl_03_lod",
"h4_ne_ipl_03_slod",
"h4_ne_ipl_04",
"h4_ne_ipl_04_lod",
"h4_ne_ipl_04_slod",
"h4_ne_ipl_05",
"h4_ne_ipl_05_lod",
"h4_ne_ipl_05_slod",
"h4_ne_ipl_06",
"h4_ne_ipl_06_lod",
"h4_ne_ipl_06_slod",
"h4_ne_ipl_07",
"h4_ne_ipl_07_lod",
"h4_ne_ipl_07_slod",
"h4_ne_ipl_08",
"h4_ne_ipl_08_lod",
"h4_ne_ipl_08_slod",
"h4_ne_ipl_09",
"h4_ne_ipl_09_lod",
"h4_ne_ipl_09_slod",
"h4_nw_ipl_00",
"h4_nw_ipl_00_lod",
"h4_nw_ipl_00_slod",
"h4_nw_ipl_01",
"h4_nw_ipl_01_lod",
"h4_nw_ipl_01_slod",
"h4_nw_ipl_02",
"h4_nw_ipl_02_lod",
"h4_nw_ipl_02_slod",
"h4_nw_ipl_03",
"h4_nw_ipl_03_lod",
"h4_nw_ipl_03_slod",
"h4_nw_ipl_04",
"h4_nw_ipl_04_lod",
"h4_nw_ipl_04_slod",
"h4_nw_ipl_05",
"h4_nw_ipl_05_lod",
"h4_nw_ipl_05_slod",
"h4_nw_ipl_06",
"h4_nw_ipl_06_lod",
"h4_nw_ipl_06_slod",
"h4_nw_ipl_07",
"h4_nw_ipl_07_lod",
"h4_nw_ipl_07_slod",
"h4_nw_ipl_08",
"h4_nw_ipl_08_lod",
"h4_nw_ipl_08_slod",
"h4_nw_ipl_09",
"h4_nw_ipl_09_lod",
"h4_nw_ipl_09_slod",
"h4_se_ipl_00",
"h4_se_ipl_00_lod",
"h4_se_ipl_00_slod",
"h4_se_ipl_01",
"h4_se_ipl_01_lod",
"h4_se_ipl_01_slod",
"h4_se_ipl_02",
"h4_se_ipl_02_lod",
"h4_se_ipl_02_slod",
"h4_se_ipl_03",
"h4_se_ipl_03_lod",
"h4_se_ipl_03_slod",
"h4_se_ipl_04",
"h4_se_ipl_04_lod",
"h4_se_ipl_04_slod",
"h4_se_ipl_05",
"h4_se_ipl_05_lod",
"h4_se_ipl_05_slod",
"h4_se_ipl_06",
"h4_se_ipl_06_lod",
"h4_se_ipl_06_slod",
"h4_se_ipl_07",
"h4_se_ipl_07_lod",
"h4_se_ipl_07_slod",
"h4_se_ipl_08",
"h4_se_ipl_08_lod",
"h4_se_ipl_08_slod",
"h4_se_ipl_09",
"h4_se_ipl_09_lod",
"h4_se_ipl_09_slod",
"h4_sw_ipl_00",
"h4_sw_ipl_00_lod",
"h4_sw_ipl_00_slod",
"h4_sw_ipl_01",
"h4_sw_ipl_01_lod",
"h4_sw_ipl_01_slod",
"h4_sw_ipl_02",
"h4_sw_ipl_02_lod",
"h4_sw_ipl_02_slod",
"h4_sw_ipl_03",
"h4_sw_ipl_03_lod",
"h4_sw_ipl_03_slod",
"h4_sw_ipl_04",
"h4_sw_ipl_04_lod",
"h4_sw_ipl_04_slod",
"h4_sw_ipl_05",
"h4_sw_ipl_05_lod",
"h4_sw_ipl_05_slod",
"h4_sw_ipl_06",
"h4_sw_ipl_06_lod",
"h4_sw_ipl_06_slod",
"h4_sw_ipl_07",
"h4_sw_ipl_07_lod",
"h4_sw_ipl_07_slod",
"h4_sw_ipl_08",
"h4_sw_ipl_08_lod",
"h4_sw_ipl_08_slod",
"h4_sw_ipl_09",
"h4_sw_ipl_09_lod",
"h4_sw_ipl_09_slod",
"h4_underwater_gate_closed",
"h4_islandx_placement_01",
"h4_islandx_placement_02",
"h4_islandx_placement_03",
"h4_islandx_placement_04",
"h4_islandx_placement_05",
"h4_islandx_placement_06",
"h4_islandx_placement_07",
"h4_islandx_placement_08",
"h4_islandx_placement_09",
"h4_islandx_placement_10",
"h4_mph4_island_placement"
}



CreateThread(function()
	for i = #requestedIpl, 1, -1 do
		RequestIpl(requestedIpl[i])
		requestedIpl[i] = nil
	end

	requestedIpl = nil
end)

CreateThread(function()
	while true do
		SetRadarAsExteriorThisFrame()
		SetRadarAsInteriorThisFrame(`h4_fake_islandx`, vec(4700.0, -5145.0), 0, 0)
		Wait(0)
	end
end)

CreateThread(function()
	SetDeepOceanScaler(0.0)
	local islandLoaded = false
	local islandCoords = vector3(4840.571, -5174.425, 2.0)

	while true do
		local pCoords = GetEntityCoords(PlayerPedId())

		if #(pCoords - islandCoords) < 2000.0 then
			if not islandLoaded then
				islandLoaded = true
				Citizen.InvokeNative(0x9A9D1BA639675CF1, "HeistIsland", 1)
				Citizen.InvokeNative(0xF74B1FFA4A15FBEA, 1) -- island path nodes (from Disquse)
				SetScenarioGroupEnabled('Heist_Island_Peds', 1)
				-- SetAudioFlag('PlayerOnDLCHeist4Island', 1)
				SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Zones', 1, 1)
				SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Disabled_Zones', 0, 1)
			end
		else
			if islandLoaded then
				islandLoaded = false
				Citizen.InvokeNative(0x9A9D1BA639675CF1, "HeistIsland", 0)
				Citizen.InvokeNative(0xF74B1FFA4A15FBEA, 0)
				SetScenarioGroupEnabled('Heist_Island_Peds', 0)
				-- SetAudioFlag('PlayerOnDLCHeist4Island', 0)
				SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Zones', 0, 0)
				SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Disabled_Zones', 1, 0)
			end
		end

		Wait(5000)
	end
end)

Citizen.CreateThread(function()
  SetDeepOceanScaler(0.0)
end)