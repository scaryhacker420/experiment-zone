



local ReplicatedStorage = game:GetService("ReplicatedStorage")
local growabledata = require(ReplicatedStorage.Data.GrowableData):GetAllPlantData()
local traitsdata = require(ReplicatedStorage.Modules.PlantTraitsData).Traits
local trees = {}
local fruits = {}
local sorted_fruits = {}
local sorted_fruits_map = {}
for i,v in pairs(growabledata) do
  fruits[i] = {}
  sorted_fruits[i] = {}
	if v.PlantData.GrowFruitTime and i ~= 'Mandrake' then
      trees[i] = {}
	end
end

local InventoryEnums = require(ReplicatedStorage.Data.EnumRegistry.InventoryServiceEnums)
local ItemTypeEnums = require( ReplicatedStorage.Data.EnumRegistry.ItemTypeEnums)
local PetMutationRegistry = require(ReplicatedStorage.Data.PetRegistry.PetMutationRegistry)



local DataService = require(ReplicatedStorage.Modules.DataService)
local data = DataService:GetData()
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local user = Players.LocalPlayer
local character = user.Character or user.CharacterAdded:Wait()
local player_farm
for _,farm in pairs(workspace.Farm:GetChildren()) do
	if farm.Important.Data.Owner.Value == user.Name then
		player_farm = farm
		break
	end
end
local theplants = player_farm.Important.Plants_Physical 


function getddsize(dicdic,keys)
  local size = 0
  for _,v in ipairs(keys) do
    for _ in pairs(dicdic[v]) do
      size = size + 1
    end
  end
  return size
end

local function unequip_tools()
	for i,v in ipairs(character:GetChildren()) do
		if v.ClassName == 'Tool' then 
			v.Parent = user.Backpack
		end
	end
end

local holding_tool
local hold_tool_timeout = 0
local function hold_tool(tool,timeout_time)
	holding_tool = tool
	hold_tool_timeout = os.clock() + (timeout_time or 3)
	local hold
	hold = tool.AncestryChanged:Connect(function(child, parent)
		if (os.clock() > hold_tool_timeout) or (holding_tool ~= tool) then
			holding_tool = nil
			hold:Disconnect()
			return
		end
		if parent == user.Backpack then
			child.Parent = character
		elseif parent ~= character then
			holding_tool = nil
			hold:Disconnect()
		end
  	end)
	local unequip_other_tools
	unequip_other_tools = character.ChildAdded:Connect(function(child)
		if (os.clock() > hold_tool_timeout) or (holding_tool ~= tool) then
			unequip_other_tools:Disconnect()
			return
		end
		if child ~= tool and child.ClassName == 'Tool' then 
				child.Parent = user.Backpack
		end
	end)
	unequip_tools()
	tool.Parent = character
end



local function remove_fruit_from_sorted_list(fruit)
  if sorted_fruits_map[fruit] then
    for _,v in ipairs(sorted_fruits_map[fruit]) do
      sorted_fruits[v][fruit] = nil
    end
    sorted_fruits_map[fruit] = nil
  end
end

local function sort_fruit(fruit) 
  remove_fruit_from_sorted_list(fruit)
  sorted_fruits_map[fruit] = {}
  table.insert(sorted_fruits_map[fruit],fruit.Name)
  sorted_fruits[fruit.Name][fruit] = true
end
  
local function addfruit(fruit)
	fruits[fruit.Name][fruit] = {} 
	fruits[fruit.Name][fruit].dc = fruit.AncestryChanged:Connect(function(child, parent)
	    if not parent then
	      remove_fruit_from_sorted_list(child)
				for _,v in pairs(fruits[child.Name][child]) do
					v:Disconnect()
				end
	      fruits[child.Name][child] = nil
	    end
  	end)
	fruits[fruit.Name][fruit].fav = fruit:GetAttributeChangedSignal('Favorited'):Connect(function()
		if fruit:GetAttribute('Favorited') == true then remove_fruit_from_sorted_list(fruit) return 
		end
		if fruit:GetAttribute('DoneGrowTime') then
			sort_fruit(fruit)
		end
	end)
	if not fruit:GetAttribute('DoneGrowTime') then
		fruits[fruit.Name][fruit].grown = fruit:GetAttributeChangedSignal('DoneGrowTime'):Connect(function()
			fruits[fruit.Name][fruit].grown:Disconnect()
			if fruit:GetAttribute('Favorited') == true then return 
			end
			sort_fruit(fruit)
		end)
	elseif fruit:GetAttribute('Favorited') ~= true then
		sort_fruit(fruit) 
	end
end

local function addtree(tree)
	if not trees[tree.Name] then trees[tree.Name] = {} end
	trees[tree.Name][tree] = {}
	trees[tree.Name][tree].dc = tree.AncestryChanged:Connect(function(child, parent)
        if not parent then
			for _,v in pairs(trees[child.Name][child]) do
				v:Disconnect()
			end
          	trees[child.Name][child] = nil
        end
    end) 
	trees[tree.Name][tree].newfruit = tree.Fruits.ChildAdded:Connect(function(frut)
		addfruit(frut)
  end) 
  for _,frut in ipairs(tree.Fruits:GetChildren()) do
    addfruit(frut)
  end
end

local farmlistener

function start_farm_listener()
	diconec_farm_listener()
	farmlistener = theplants.ChildAdded:Connect(function(child)
		if trees[child.Name] then 
			addtree(child) 
		elseif fruits[child.Name] then 
			addfruit(child)
		end
	end) 
	for _,child in ipairs(theplants:GetChildren()) do
		if trees[child.Name] then 
			addtree(child)
		elseif fruits[child.Name] then 
			addfruit(child)
		end 
	end
end

function diconec_farm_listener()
	if farmlistener then
		farmlistener:Disconnect()
		farmlistener = nil
	end
	for _,t in pairs(trees) do
		for obj,l in pairs(t) do
			for _,v in pairs(l) do
				v:Disconnect()
			end
			t[obj] = nil
		end
	end
	for _,t in pairs(fruits) do
		for obj,l in pairs(t) do
			for _,v in pairs(l) do
				v:Disconnect()
			end
			t[obj] = nil
			remove_fruit_from_sorted_list(obj)
		end
	end
end 

local inventory_listener
local held_item_listener
local item_parent_listeners = {}
local inventory_items = {}
local inventory_items_map = {}
local inv_listeners = {}
local inv_group_to_listener_names = {}

local function add_item_to_group(item,group)
	inventory_items[group][item] = true
	if not inventory_items_map[item] then
		inventory_items_map[item] = {}
	end
	inventory_items_map[item][group] = true
end

local function rm_item_from_group(item,group)
	inventory_items[group][item] = nil
	if inventory_items_map[item] then
		inventory_items_map[item][group] = nil
	end
end

local function remove_item_from_all_groups(item)
	if not inventory_items_map[item] then return end
	for group in pairs(inventory_items_map[item]) do
		inventory_items[group][item] = nil
	end
	inventory_items_map[item] = nil
end
	

local function diconec_inventory_listener()
	inventory_listener:Disconnect()
	held_item_listener:Disconnect()
	inventory_listener = nil
	held_item_listener = nil
	for _,v in pairs(item_parent_listeners) do
		v:Disconnect()
	end
	inventory_items = {}
	inventory_items_map = {}
	inv_listeners = {}
	inv_group_to_listener_names = {}
end

local function create_item_parent_listener(item)
	item_parent_listeners[item] = item.AncestryChanged:Connect(function(child, parent)
		if parent ~= character and parent ~= user.Backpack then
			item_parent_listeners[child]:Disconnect()
			item_parent_listeners[child] = nil
			remove_item_from_all_groups(child)
		end
  	end)
end

local function add_item(item)
	local type = item:GetAttribute('b')
	if type == nil or inventory_items[type] == nil then
		type = 'other'
	end
	add_item_to_group(item,type)
	for i in pairs(inv_group_to_listener_names[type]) do
		inv_listeners[i].f(item)
	end
end

local function start_inventry_listener()
	if inventory_listener then diconec_inventory_listener() end
	for _,v in pairs(ItemTypeEnums) do 
		inventory_items[v] = {}
		inv_group_to_listener_names[v] = {}
	end
	inventory_items['other'] = {}
	inv_group_to_listener_names['other'] = {}
	inventory_listener = user.Backpack.ChildAdded:Connect(function(item)
		if not item_parent_listeners[item] then
			create_item_parent_listener(item)
			add_item(item)
		end
	end)
	held_item_listener = character.ChildAdded:Connect(function(item)
		if item_parent_listeners[item] then
			item_parent_listeners[item]:Disconnect()
			item_parent_listeners[item] = nil
			remove_item_from_all_groups(item)
		end
		create_item_parent_listener(item)
		add_item(item)
	end)
	for _,item in ipairs(user.Backpack:GetChildren()) do
		create_item_parent_listener(item)
		add_item(item)
	end
	for _,item in ipairs(character:GetChildren()) do
		if item.ClassName == 'Tool' then 
			create_item_parent_listener(item)
			add_item(item)
		end
	end
end

local function add_inv_listener(types,name,f,group_names)
	group_names = group_names or {}
	if inv_listeners[name] then
		rm_inv_listener(name)
	end
	inv_listeners[name] = {}
	inv_listeners[name].f = f
	inv_listeners[name].types = types
	inv_listeners[name].groups = group_names
	for _,v in ipairs(group_names) do
		if not inventory_items[v] then
			inv_group_to_listener_names[v] = {}
			inventory_items[v] = {}
		end
		inv_group_to_listener_names[v][name] = true
	end
	for _,v in ipairs(types) do
		inv_group_to_listener_names[v][name] = true
	end
	for _,type in pairs(types) do
		for i in pairs(inventory_items[type]) do
			f(i)
		end
	end
end

local function rm_inv_listener(name)
	if not inv_listeners[name] then return end
	for _,v in ipairs(inv_listeners[name].groups) do
		inv_group_to_listener_names[v][name] = nil
		if not next(inv_group_to_listener_names[v]) then
			inv_group_to_listener_names[v] = nil
			inventory_items[v] = nil
		end
	end
	for _,v in ipairs(inv_listeners[name].types) do
		inv_group_to_listener_names[v][name] = nil
	end
	inv_listeners[name] = nil
end

local function favorite_item(item)
	if item:GetAttribute('d') ~= true then
		ReplicatedStorage.GameEvents.Favorite_Item:FireServer(item)
	end
end
local function unfavorite_item(item)
	if item:GetAttribute('d') == true then
		ReplicatedStorage.GameEvents.Favorite_Item:FireServer(item)
	end
end


local function concat_pet_name(pet,max_len)
	if pet.PetData.MutationType and pet.PetData.MutationType ~= 'm' then
		return PetMutationRegistry.EnumToPetMutation[pet.PetData.MutationType]:sub(1,max_len) .. ' ' .. pet.PetType:sub(1,max_len)
	else
		return pet.PetType:sub(1,max_len*2)
	end
end

local function round_down(n,decimals)
	return math.floor(n * 10^decimals)/(10^decimals)
end

local function format_pet_name(uuid)
	local pet = data.PetsData.PetInventory.Data[uuid]
	if not pet then return end
	local name = string.format('%s\n[%.3fkg] Age %d', concat_pet_name(pet,9), round_down(pet.PetData.BaseWeight * 1.1,3), pet.PetData.Level)
	if (pet.PetData.MutationType and pet.PetData.MutationType ~= 'm' and ((#PetMutationRegistry.EnumToPetMutation[pet.PetData.MutationType]>9) or (#pet.PetType>9))) or (#pet.PetType>18) then
		name = name .. '\n\n' .. concat_pet_name(pet,100)
	end
	return name
end

local function calculate_pet_weight(pet)
	return pet.PetData.BaseWeight * (0.1 * pet.PetData.Level + 1)
end

PetStatValues = {}
PetStatValues.Seal = {['']={2.5,0.22,8,50}}
PetStatValues.Koi = {['']={3,0.22,8,50}}
PetStatValues.Brontosaurus = {['']={5.25,0.1,30,30}}
PetStatValues.Phoenix = {['max age bonus']={4.8,0.1}}



local function get_mutation_passive_boost(pet)
	if pet.PetData.MutationType and PetMutationRegistry.PetMutationRegistry[PetMutationRegistry.EnumToPetMutation[pet.PetData.MutationType] ].Boosts[1] and PetMutationRegistry.PetMutationRegistry[PetMutationRegistry.EnumToPetMutation[pet.PetData.MutationType] ].Boosts[1].BoostType == 'PASSIVE_BOOST' then
		return PetMutationRegistry.PetMutationRegistry[PetMutationRegistry.EnumToPetMutation[pet.PetData.MutationType] ].Boosts[1].BoostAmount
	else
		return 0
	end
end

local function calc_passive_mult(pet,mtoy,stoy)
	return 1 + get_mutation_passive_boost(pet) + (mtoy and .2 or 0) + (stoy and .1 or 0)
end

local function calc_pet_stat(pet,petstat,mtoy,stoy)
	if PetStatValues[pet.PetType] then
		return math.min(calculate_pet_weight(pet) * petstat[2] + calc_passive_mult(pet,mtoy,stoy) * petstat[1], petstat[3] or 0xFFFFFFFFFFFFFFFF) 
	end
end

local function calc_equipped_pet_stats()
	eqipped_pets = {}
	output = {}
	for _,v in pairs(data.PetsData.EquippedPets) do
		local pet = data.PetsData.PetInventory.Data[v]	
		if PetStatValues[pet.PetType] then 
			for i,stat in pairs(PetStatValues[pet.PetType]) do
				if PetStatValues[pet.PetType][i] and PetStatValues[pet.PetType][i][4] then	
					if not output[pet.PetType] then
						output[pet.PetType] = {}
					end	
					if not output[pet.PetType][i] then
						output[pet.PetType][i] = 0
					end
					--print((PetMutationRegistry.EnumToPetMutation[pet.PetData.MutationType] or 'normal') .. ' ' .. pet.PetType .. ' ' .. round_down(calculate_pet_weight(pet),3) .. 'kg ' .. round_down(calc_pet_stat(pet,stat),3))
					output[pet.PetType][i] = output[pet.PetType][i] + calc_pet_stat(pet,stat)
				end
			end
		end
	end
	return output
end

local function print_pet_stats(stats)
	for pet,stats in pairs(stats) do
		for stat,v in pairs(stats) do
			print(pet .. stat .. ': ' .. v)
		end
	end
end


local pets_to_equip = {}
local pets_to_unequip = {}
local pets_to_mutate = {}
local aging_pets_loadout = {}
local aging_pets_loadout_map = {}

local function add_pet_qualifier(qualfier_type,pet_type,a1wlower,a1whigher,target_mutations,make_mutations_inverse)
	local equip_qualifier = {pet_type,nil,nil,a1wlower*0.909090909,a1whigher*0.909090909,target_mutations,make_mutations_inverse}
	local unequip_qualifier = {pet_type,nil,nil,a1wlower*0.909090909,a1whigher*0.909090909,target_mutations,make_mutations_inverse}
	if qualfier_type == 'm' then
		equip_qualifier[2] = 1
		equip_qualifier[3] = 49
		unequip_qualifier[2] = 50
		unequip_qualifier[3] = 100
		table.insert(pets_to_mutate,unequip_qualifier)
		table.insert(pets_to_unequip,unequip_qualifier)
		table.insert(pets_to_equip,equip_qualifier)
	elseif qualfier_type == 'a' then
		equip_qualifier[2] = 1
		equip_qualifier[3] = 99
		unequip_qualifier[2] = 100
		unequip_qualifier[3] = 100
		table.insert(pets_to_unequip,unequip_qualifier)
		table.insert(pets_to_equip,equip_qualifier)
	end
end


local function unequip_pets(pets)
	for _,v in ipairs(pets) do 
		ReplicatedStorage.GameEvents.PetsService:FireServer('UnequipPet',v)
	end
end

local function equip_pets(pets)
	for _,v in ipairs(pets) do 
		ReplicatedStorage.GameEvents.PetsService:FireServer('EquipPet',(type(v) == 'string') and v or v:GetAttribute('PET_UUID'),player_farm.Center_Point.CFrame)
	end
end

local function mumachine(arg)
	ReplicatedStorage.GameEvents.PetMutationMachineService_RE:FireServer(arg)
end

local function check_val_in_array(array,val)
	for _,v in ipairs(array) do
		if v == val then return true end
	end
	return false
end

local function check_equipped_pets(loadout)
	for _,v in ipairs(loadout) do
		if not check_val_in_array(data.PetsData.EquippedPets,v) then
			return false
		end
	end
	return true
end
			

local phoenix_loadout = {}
local old_loadout = {}
local using_phoenix_loadout
local phoenix_loadout_timout_time = 0
local function make_phoenix_loadout()
	local phoenixes = {}
	local phoenix_id_to_stat = {}
	for i,v in pairs(data.PetsData.PetInventory.Data) do
		if v.PetType == 'Phoenix' then
			table.insert(phoenixes,i)
			phoenix_id_to_stat[i] = math.min(calculate_pet_weight(v) * 0.1 + calc_passive_mult(v) * 4.8, 10) 
		elseif v.PetType == 'Rainbow Phoenix' then
			table.insert(phoenixes,i)
			phoenix_id_to_stat[i] = math.min(calculate_pet_weight(v) * 0.1 + calc_passive_mult(v) * 5.8, 10) + 1
		end
	end
	if not phoenixes[1] then return false end
	table.sort(phoenixes,function(v1,v2) return phoenix_id_to_stat[v1] > phoenix_id_to_stat[v2] end)
	phoenix_loadout = table.pack(table.unpack(phoenixes,1,data.PetsData.MutableStats.MaxEquippedPets))
	return true
end

local function stop_using_phoenix_loadout()
	using_phoenix_loadout = nil
	unequip_pets(phoenix_loadout)
	equip_pets(old_loadout)
	phoenix_loadout = {}
	old_loadout = {}
	phoenix_loadout_timout_time = 0
end

local function use_phoenix_loadout()
	if check_equipped_pets(phoenix_loadout) then
		mumachine('ClaimMutatedPet')
		mumachine('StartMachine')
		stop_using_phoenix_loadout()
		return
	end
	if os.clock() > phoenix_loadout_timout_time then
		print('phoenix timeout')
		mumachine('ClaimMutatedPet')
		mumachine('StartMachine')
		stop_using_phoenix_loadout()
	end
end



local function start_mutation_machine()
	if data.PetMutationMachine.SubmittedPet and data.PetMutationMachine.PetReady == true then
		if make_phoenix_loadout() == true then
			using_phoenix_loadout = true
			phoenix_loadout_timout_time = os.clock() + 15
			for _,v in ipairs(data.PetsData.EquippedPets,v) do
				table.insert(old_loadout,v)
			end
			unequip_pets(old_loadout)
			equip_pets(phoenix_loadout)
		else
			mumachine('ClaimMutatedPet')
			mumachine('StartMachine')
		end
	elseif data.PetMutationMachine.PetReady == false and data.PetMutationMachine.IsRunning == false then
		mumachine('StartMachine')
	end
end

local function check_mutation(pet,mutations,exclusionary)
	local mutation = pet.PetData.MutationType or 'm'
	for _,v in ipairs(mutations) do
		if mutation == v then
			return not exclusionary
		end
	end
	return exclusionary
end

local function match_equipped_pets(output,type,agelower,agehigher,bwlower,bwhigher,mutations,exclusionary)
	for _,v in ipairs(data.PetsData.EquippedPets) do
		local pet = data.PetsData.PetInventory.Data[v]
		if pet.PetType == type and not aging_pets_loadout_map[i] and pet.PetData.Level >= agelower and pet.PetData.Level <= agehigher and
		pet.PetData.BaseWeight >= bwlower and pet.PetData.BaseWeight <= bwhigher and
		check_mutation(pet,mutations,exclusionary) then
			table.insert(output,v)
		end
	end
end

local function match_backpack_pets(ignor_fav,type,agelower,agehigher,bwlower,bwhigher,mutations,exclusionary)
	local output = {}
	for i in pairs(inventory_items.l) do
		local pet = data.PetsData.PetInventory.Data[i:GetAttribute('PET_UUID')]
		if not (ignor_fav and i:GetAttribute('d') == true) and pet and pet.PetType == type and 
		pet.PetData.Level >= agelower and pet.PetData.Level <= agehigher and
		pet.PetData.BaseWeight >= bwlower and pet.PetData.BaseWeight <= bwhigher and
		check_mutation(pet,mutations,exclusionary) then
			table.insert(output,i)
		end
	end
	table.sort(output,function(v1,v2) 
			return data.PetsData.PetInventory.Data[v1:GetAttribute('PET_UUID')].PetData.BaseWeight > data.PetsData.PetInventory.Data[v2:GetAttribute('PET_UUID')].PetData.BaseWeight 
		end)
	return output
end

local function mutate_qualifying_pet()
	for _,v in ipairs(pets_to_mutate) do
		local output = match_backpack_pets(true,table.unpack(v))
		if output[1] then
			hold_tool(output[1],1)
			mumachine('SubmitHeldPet')
			return
		end
	end
end

local function equip_qualifying_pets(n)
	for _,v in ipairs(pets_to_equip) do
		local output = match_backpack_pets(false,table.unpack(v))
		if output[1] then
			equip_pets(table.pack(table.unpack(output,1,n)))
			n = n - #output
			if n <= 0 then
				return
			end
		end
	end
end

local mut_pets_last = 0.0
local mut_pets_cycle_length = 2
local function equip_and_mutate_pets()
	if using_phoenix_loadout then use_phoenix_loadout() return end
	if (os.clock() - mut_pets_last) < mut_pets_cycle_length then return end
	mut_pets_last = os.clock()
	start_mutation_machine()
	if not data.PetMutationMachine.SubmittedPet and (not holding_tool or (hold_tool_timeout < os.clock())) then
		mutate_qualifying_pet()
	end
	if #data.PetsData.EquippedPets < data.PetsData.MutableStats.MaxEquippedPets then
		equip_qualifying_pets(data.PetsData.MutableStats.MaxEquippedPets-#data.PetsData.EquippedPets)
	end
	local to_unequip = {}
	for _,v in ipairs(pets_to_unequip) do
		match_equipped_pets(to_unequip,table.unpack(v))
	end
	if to_unequip[1] then
		unequip_pets(to_unequip)
		equip_qualifying_pets(#to_unequip)
	end
end





local function find_tool(group,att,value)
	for i in pairs(inventory_items) do
		if i:GetAttribute(att) == value then
			return i
		end
	end
end


local pets_to_sell = {}
local eggs_to_hatch_koi = {}
local eggs_to_hatch_bronto = {}
local egg_cords = {}
local auto_hatch_last = 0.0
local auto_hatch_cycle_length = 0.1
local auto_hatch_sell_check_interval = 8
local auto_hatch_sell_check_last = 0
local auto_hatch_paused
local auto_hatch_step
local egg_types_to_place_in_order = {'Zen Egg'}
local hatch_loadout = {}
local koi_loadout = {}
local bronto_loadout = {}
local seal_loadout = {}
local lock_pet_loadout
local lock_pet_loadout_timeout
local eggs_in_inv_last = 0

local function get_all_egg_cords()
	for _,v in ipairs(player_farm.Important.Objects_Physical:GetChildren()) do
		if v:GetAttribute('OBJECT_TYPE') == 'PetEgg' then
			table.insert(egg_cords,vector.create(v.WorldPivot.x,v.WorldPivot.y,v.WorldPivot.z))
		end
	end
end


local function make_koi_loadout()
	local koi = {}
	local koi_id_to_stat = {}
	for i,v in pairs(data.PetsData.PetInventory.Data) do
		if v.PetType == 'Koi' then
			table.insert(koi,i)
			koi_id_to_stat[i] = math.min(calculate_pet_weight(v) * 0.22 + calc_passive_mult(v) * 3, 8) 
		end
	end
	table.sort(koi,function(v1,v2) return koi_id_to_stat[v1] > koi_id_to_stat[v2] end)
	koi = table.pack(table.unpack(koi,1,8))
	local stat_sum = 0
	for _,v in ipairs(koi) do
		stat_sum = stat_sum + koi_id_to_stat[v]
	end
	if stat_sum > 50 then
		koi_loadout = koi
	else
		auto_hatch_paused = 'koi no good enough'
	end
end
local function make_bronto_loadout()
	local bronto = {}
	local bronto_id_to_stat = {}
	for i,v in pairs(data.PetsData.PetInventory.Data) do
		if v.PetType == 'Brontosaurus' then
			table.insert(bronto,i)
			bronto_id_to_stat[i] = calculate_pet_weight(v) * 0.1 + calc_passive_mult(v) * 5.25
		end
	end
	table.sort(bronto,function(v1,v2) return bronto_id_to_stat[v1] > bronto_id_to_stat[v2] end)
	bronto = table.pack(table.unpack(bronto,1,8))
	local stat_sum = 0
	local enough_brontos = {}
	for _,v in ipairs(bronto) do
		stat_sum = stat_sum + bronto_id_to_stat[v]
		table.insert(enough_brontos,v)
		if stat_sum > 30 then break end
	end
	if stat_sum < 30 then
		auto_hatch_paused = 'brontos no good enough'
		return
	end
	local koi = {}
	local koi_id_to_stat = {}
	for i,v in pairs(data.PetsData.PetInventory.Data) do
		if v.PetType == 'Koi' then
			table.insert(koi,i)
			koi_id_to_stat[i] = math.min(calculate_pet_weight(v) * 0.22 + calc_passive_mult(v) * 3, 8) 
		end
	end
	table.sort(koi,function(v1,v2) return koi_id_to_stat[v1] > koi_id_to_stat[v2] end)
	while #enough_brontos < 8 and koi[1] do
		table.insert(enough_brontos,koi[1])
		table.remove(koi,1)
	end
	bronto_loadout = enough_brontos
end
local function make_seal_loadout()
	local seal = {}
	local seal_id_to_stat = {}
	for i,v in pairs(data.PetsData.PetInventory.Data) do
		if v.PetType == 'Seal' then
			table.insert(seal,i)
			seal_id_to_stat[i] = math.min(calculate_pet_weight(v) * 0.22 + calc_passive_mult(v) * 2.5, 8) 
		end
	end
	table.sort(seal,function(v1,v2) return seal_id_to_stat[v1] > seal_id_to_stat[v2] end)
	seal = table.pack(table.unpack(seal,1,8))
	local stat_sum = 0
	for _,v in ipairs(seal) do
		stat_sum = stat_sum + seal_id_to_stat[v]
	end
	if stat_sum > 50 then
		seal_loadout = seal
	else
		auto_hatch_paused = 'seals no good enough'
	end
end

local egg_hatch_rules = {
	['Common Egg'] = {
		['Bunny'] = 2.9*0.699,
		['Dog'] = 2.9*0.699,
		['Golden Lab'] = 2.9*0.699
	},
	['Zen Egg'] = {
		['Shiba Inu'] = 2.9*0.699,
		['Nihonzaru'] = 2.9*0.699,
		['Tanuki'] = 2.9*0.699,
		['Kappa'] = 2.9*0.699,
		['Tanchozuru'] = 2.9*0.699,
		['Kitsune'] = 2.2*0.699,
	}
}

local function pet_sell_or_fav(pet,threashold)
	if data.PetsData.PetInventory.Data[pet:GetAttribute('PET_UUID')].PetData.BaseWeight < threashold then
		table.insert(pets_to_sell,pet)
	else
		--favorite_item(pet)
	end
end

local pet_sell_rules = {
	['Bunny'] = {pet_sell_or_fav,2.9*0.9090909},
	['Dog'] = {pet_sell_or_fav,2.9*0.9090909},
	['Golden Lab'] = {pet_sell_or_fav,2.9*0.9090909},
	['Shiba Inu'] = {pet_sell_or_fav,2.9*0.9090909},
	['Nihonzaru'] = {pet_sell_or_fav,2.9*0.9090909},
	['Tanuki'] = {pet_sell_or_fav,2.9*0.9090909},
	['Kappa'] = {pet_sell_or_fav,2.9*0.9090909},
	['Tanchozuru'] = {pet_sell_or_fav,2.9*0.9090909},
}

local function new_pet_listener(pet)
	local pet_data = data.PetsData.PetInventory.Data[pet:GetAttribute('PET_UUID')]
	if pet_data and pet_sell_rules[pet_data.PetType] then
		pet_sell_rules[pet_data.PetType][1](pet,pet_sell_rules[pet_data.PetType][2])
	end
end

local function initiate_auto_hatch()
	make_koi_loadout()
	make_seal_loadout()
	make_bronto_loadout()
	get_all_egg_cords()
	for _,v in pairs(data.PetsData.EquippedPets) do
		table.insert(hatch_loadout,v)
	end
	add_inv_listener({'l'},'sellorfavpets',function(v)
		delay(2,function() new_pet_listener(v) end)
	end)
end
	
local function check_if_eggs_is_ready()
	for _,obj in pairs(data.SaveSlots.AllSlots[data.SaveSlots.SelectedSlot].SavedObjects) do
		if obj.ObjectType == 'PetEgg' and egg_hatch_rules[obj.Data.EggName] and not obj.Data.BaseWeight then
			return false
		end
	end
	for i,obj in pairs(data.SaveSlots.AllSlots[data.SaveSlots.SelectedSlot].SavedObjects) do
		if obj.ObjectType == 'PetEgg' and egg_hatch_rules[obj.Data.EggName] and egg_hatch_rules[obj.Data.EggName][obj.Data.Type] then
			if obj.Data.BaseWeight >= egg_hatch_rules[obj.Data.EggName][obj.Data.Type] then
				eggs_to_hatch_bronto[i] = true
			else
				eggs_to_hatch_koi[i] = true
			end
		end
	end
	for _,egg_type in ipairs(egg_types_to_place_in_order) do
		for egg in pairs(inventory_items.c) do
			if egg:GetAttribute('h') == egg_type then
				eggs_in_inv_last = egg:GetAttribute('e') or 0
			end
		end
	end
	return true
end

local function switch_pet_loadout(loadout)
	for _,v in ipairs(loadout) do
		if not data.PetsData.PetInventory.Data[v] then
			return 'missing'
		end		
	end
	local equipped_count = 0
	for _,v in ipairs(data.PetsData.EquippedPets) do
		if not check_val_in_array(loadout,v) then
			ReplicatedStorage.GameEvents.PetsService:FireServer('UnequipPet',v)
		else	
			equipped_count = equipped_count + 1
		end	
	end
	if equipped_count == #loadout then
		return true
	end
	equip_pets(loadout)
	return false
end

local function place_down_eggs()
	local egg_tool
	for _,egg_type in ipairs(egg_types_to_place_in_order) do
		for egg in pairs(inventory_items.c) do
			if egg:GetAttribute('h') == egg_type then
				hold_tool(egg,0.6)
				for _,cord in ipairs(egg_cords) do
					ReplicatedStorage.GameEvents.PetEggService:FireServer('CreateEgg',cord)
				end
				return true
			end
		end
	end
	return false
end

local function count_placed_eggs()
	local count = 0
	for _,v in ipairs(player_farm.Important.Objects_Physical:GetChildren()) do
		if v:GetAttribute('OBJECT_TYPE') == 'PetEgg' then
			count = count + 1
		end
	end
	return count
end

auto_hatch_eggs = {}
function auto_hatch_eggs.hatch()
	if next(eggs_to_hatch_bronto) then
		local switch_pets = switch_pet_loadout(bronto_loadout)
		if switch_pets == 'missing' then auto_hatch_paused = 'missing bronto' return end
		if switch_pets then
			for _,v in ipairs(player_farm.Important.Objects_Physical:GetChildren()) do
				if eggs_to_hatch_bronto[v:GetAttribute('OBJECT_UUID')] then
					print(string.format('hatched %s %.3fkg (bronto)',data.SaveSlots.AllSlots[data.SaveSlots.SelectedSlot].SavedObjects[v:GetAttribute('OBJECT_UUID')].Data.Type,data.SaveSlots.AllSlots[data.SaveSlots.SelectedSlot].SavedObjects[v:GetAttribute('OBJECT_UUID')].Data.BaseWeight*1.1*1.3))
					ReplicatedStorage.GameEvents.PetEggService:FireServer('HatchPet',v)
				end
			end
			eggs_to_hatch_bronto = {}
		end
	elseif next(eggs_to_hatch_koi) then
		local switch_pets = switch_pet_loadout(koi_loadout)
		if switch_pets == 'missing' then auto_hatch_paused = 'missing koi' return end
		if switch_pets then
			for _,v in ipairs(player_farm.Important.Objects_Physical:GetChildren()) do
				if eggs_to_hatch_koi[v:GetAttribute('OBJECT_UUID')] then
					local petdata = data.SaveSlots.AllSlots[data.SaveSlots.SelectedSlot].SavedObjects[v:GetAttribute('OBJECT_UUID')].Data
					if not pet_sell_rules[petdata.Type] or petdata.BaseWeight*1.1 > pet_sell_rules[petdata.Type][2] then
						print(string.format('hatched %s %.3fkg',petdata.Type,petdata.BaseWeight*1.1))
					end
					ReplicatedStorage.GameEvents.PetEggService:FireServer('HatchPet',v)
				end
			end
			eggs_to_hatch_koi = {}
		end
	else
		place_down_eggs()
		local switch_pets = switch_pet_loadout(hatch_loadout)
		if switch_pets == 'missing' then auto_hatch_paused = 'missing hatch loadout' return end
		auto_hatch_last = auto_hatch_last + 1
		if switch_pets == true and ((count_placed_eggs() >= #egg_cords) or not place_down_eggs()) then
			print(eggs_in_inv_last - egg:GetAttribute('e'))
			auto_hatch_step = nil
		end
	end	
end

function auto_hatch_eggs.sell()
	if pets_to_sell[1] then
		local switch_pets = switch_pet_loadout(seal_loadout)
		if switch_pets == 'missing' then auto_hatch_paused = 'missing seals' return end
		if switch_pets == true and (holding_tool == nil or hold_tool_timeout < os.clock()) then
			while pets_to_sell[1] and ((not (pets_to_sell[1].Parent == character or pets_to_sell[1].Parent == user.Backpack)) or pets_to_sell[1]:GetAttribute('d') == true) do
				table.remove(pets_to_sell,1)
			end
			if pets_to_sell[1] then
				hold_tool(pets_to_sell[1])
				ReplicatedStorage.GameEvents.SellPet_RE:FireServer()
			end	
		end
	else
		local switch_pets = switch_pet_loadout(hatch_loadout)
		if switch_pets == 'missing' then auto_hatch_paused = 'missing hatch loadout' return end
		if switch_pets == true then
			auto_hatch_step = nil
		end
	end	
end


function auto_hatch_eggs.main()
	if os.clock() < auto_hatch_last then return end
	auto_hatch_last = os.clock() + auto_hatch_cycle_length
	if auto_hatch_paused then print(auto_hatch_paused) return end
	if auto_hatch_step and auto_hatch_eggs[auto_hatch_step] then
		auto_hatch_eggs[auto_hatch_step]()
	elseif (os.clock() - auto_hatch_sell_check_last) > auto_hatch_sell_check_interval then
		auto_hatch_sell_check_last = os.clock()
		if getddsize(data.PetsData.PetInventory,{'Data'}) + 13 >= data.PetsData.MutableStats.MaxPetsInInventory then
			auto_hatch_step = 'sell'
			return
		end
	elseif check_if_eggs_is_ready() then
		auto_hatch_step = 'hatch'
	end
end





function get_fruit_from_groups(groups,n,output)
  local count = 0
  for _,v in ipairs(groups) do
    for i in pairs(sorted_fruits[v]) do
      table.insert(output,i)
      count = count + 1 
      if count >= n then 
        return
      end
    end
  end
end

function collect_fruit_batch(fruits)
  if fruits and next(fruits) then
    ReplicatedStorage.GameEvents.Crops.Collect:FireServer(fruits)
  end
end





function attributeMatch(obj,pos,neg)
	pos = pos or {}
	neg = neg or {}
	for _,attr in ipairs(neg) do 
		if obj:GetAttribute(attr) == true then
			return false
		end 
	end
	for _,attr in ipairs(pos) do 
		if not obj:GetAttribute(attr) == true then
			return false
		end 
	end
	return true
end

function FindAttributeMatchInGroups(groups,n,pos_muts,neg_muts,output,pos_any)
	local count = 0
	for _,t in ipairs(groups) do
		for object in pairs(t) do 
			if (pos_any and (attributeMatch(object,nil,neg_muts) and not attributeMatch(object,nil,pos_muts))) or (not pos_any and attributeMatch(object,pos_muts,neg_muts)) then
				count = count + 1
				table.insert(output,object)
				if count >= n then 
					  return 
				end
			end 
		end
	end
end

local collect_fruit_last = 0.0
local collect_fruit_cycle_length = 2
local fruits_to_collect = {{'Cacao',5,5}}
local function count_fruit_in_inventory(fruit)
	local count = 0
	for i in pairs(inventory_items.j) do
		if i:GetAttribute('f') == fruit then
			count = count + 1
		end
	end
	return count
end
function collect_fruit_simple()
  	if (os.clock() - collect_fruit_last) < collect_fruit_cycle_length then return end
	collect_fruit_last = os.clock()
	local frutbatch = {}
	for _,v in ipairs(fruits_to_collect) do
		if v[2] then
			if count_fruit_in_inventory(v[1]) < v[2] then
				get_fruit_from_groups({v[1]},v[3],frutbatch)
			end
		else
			get_fruit_from_groups(v[1],10,frutbatch)
		end
	end
	collect_fruit_batch(frutbatch)
end

local rebirth_cycle_last = -10
local rebirth_cycle_length = 10
local rebirth_reset_time = require(ReplicatedStorage.Data.RebirthConfigData).RESET_TIME
local rebirth_output = ''
local required_fruit
local requried_fruit_tracker

local function dorebirth()
	if (not required_fruit) or (holding_tool and (hold_tool_timeout > os.clock())) then return end
	unfavorite_item(required_fruit)
	hold_tool(required_fruit,1)
	ReplicatedStorage.GameEvents.BuyRebirth:FireServer()
end

local function savereqfruit(item)
	required_fruit = item
	required_fruit_tracker = required_fruit.AncestryChanged:Connect(function(child, parent)
		if parent ~= character and parent ~= user.Backpack then
			required_fruit_tracker:Disconnect()
			required_fruit_tracker = nil
			required_fruit = nil
		end
	end)
	favorite_item(required_fruit)
end

local function unsave_required_rebirth_fruit()
	if not required_fruit then return end
	unfavorite_item(required_fruit)
	required_fruit_tracker:Disconnect()
	required_fruit_tracker = nil
	required_fruit = nil
end

function auto_rebirth()
	if (os.clock() - rebirth_cycle_last) < rebirth_cycle_length then return end
	rebirth_cycle_last = os.clock()
	local req_plant = data.RebirthData.RequiredPlants[1].FruitName
	local req_mutations = data.RebirthData.RequiredPlants[1].Mutations
	if not required_fruit or not(required_fruit.Parent == charcter or required_fruit.Parent == user.Backpack) or required_fruit:GetAttribute('f') ~= req_plant or not attributeMatch(required_fruit,req_mutations) then
		if required_fruit then
			unsave_required_rebirth_fruit()
		end
		for i in pairs(inventory_items.j) do
			if i:GetAttribute('f') == req_plant and attributeMatch(i,req_mutations,{'d'}) then
				savereqfruit(i)
				break
			end
		end
		if not required_fruit then
			local frutingarden = {}
			FindAttributeMatchInGroups({sorted_fruits[req_plant]},1,req_mutations,nil,frutingarden)
			if frutingarden[1] then
				collect_fruit_batch(frutingarden)
				local listener_timout_time = os.clock() + 9
				local listenen4reqfruit
				listenen4reqfruit = user.Backpack.ChildAdded:Connect(function(item)
					if item:GetAttribute('b') == 'j' and item:GetAttribute('f') == req_plant and attributeMatch(item,req_mutations) then
						listenen4reqfruit:Disconnect()
						savereqfruit(item)
					elseif os.clock() > listener_timout_time then
						listenen4reqfruit:Disconnect()
					end
				end)
			elseif req_mutations[1] then
				local mut_match_any = {}
				if req_mutations[1] == 'Wet' then
					mut_match_any = {'Chilled','Drenched','Frozen'}
				elseif req_mutations[1] == 'Windstruck' then
					mut_match_any = {'Tempestuous','Twisted'}
				elseif req_mutations[1] == 'Chilled' then
					mut_match_any = {'Drenched','Frozen','Wet'}
				end
				FindAttributeMatchInGroups({sorted_fruits[req_plant]},5,mut_match_any,nil,frutingarden,true)
				if frutingarden[1] then
					collect_fruit_batch(frutingarden)
				end
			end
		end
	end
	if ((data.RebirthData.LastRebirthTime + rebirth_reset_time - DateTime.now().UnixTimestamp) < 0) and required_fruit then
		dorebirth()
	end	
	rebirth_output = data.RebirthData.LastRebirthTime + rebirth_reset_time - DateTime.now().UnixTimestamp
	for _,plant in ipairs(data.RebirthData.RequiredPlants) do
		for _,v in ipairs(plant.Mutations) do
			rebirth_output = rebirth_output .. ' ' .. v
		end
		rebirth_output = rebirth_output .. ' ' .. plant.FruitName
	end
	rebirth_output = rebirth_output .. ' ' .. (required_fruit and 'obtained' or 'not obtained')
end

start_inventry_listener()
add_inv_listener({'l'},'formatpetnames',function(v)
	v.Name = format_pet_name(v:GetAttribute('PET_UUID')) or v.Name
end)
start_farm_listener()

add_pet_qualifier('m','Brontosaurus',1.74,2.5,{'b','c','n'},true)
add_pet_qualifier('a','Brontosaurus',1.74,2.5,{'b','c'})
add_pet_qualifier('m','Bald Eagle',1.14,2.5,{'c','n'},true)
add_pet_qualifier('a','Bald Eagle',1.14,2.5,{'c'})
add_pet_qualifier('m','Brontosaurus',1.2,1.75,{'c','n'},true)
add_pet_qualifier('a','Brontosaurus',1.2,1.75,{'c'})
add_pet_qualifier('m','Scarlet Macaw',9,100,{'c','n','i'},true)
add_pet_qualifier('a','Koi',1.18,2.5,{'c'})
add_pet_qualifier('m','Koi',1.18,2.5,{'c'},true)
add_pet_qualifier('m','Phoenix',0,2.5,{'c','n'},true)
add_pet_qualifier('a','Phoenix',0,2.5,{'c'})
add_pet_qualifier('a','Seal',1.72,100,{},true)
add_pet_qualifier('m','Seal',1.6,1.72,{'b','c','n'},true)
add_pet_qualifier('a','Seal',1.6,1.72,{'b','c'})
initiate_auto_hatch()
local run
run = RunService.Heartbeat:Connect(function(dt)
	if character:FindFirstChild('Shovel [Destroy Plants]') then 
		run:Disconnect() 
		diconec_farm_listener() 
		diconec_inventory_listener()
		unsave_required_rebirth_fruit()
		Players.LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = 'script stopped'
		return 
	end
	auto_hatch_eggs.main()
	--equip_and_mutate_pets()
	auto_rebirth()
	collect_fruit_simple()
	Players.LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = rebirth_output
end)
