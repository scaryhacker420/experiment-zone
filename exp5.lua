
local trait_label
local progress_label
if game:GetService("Workspace"):FindFirstChild('Fall Festival') and
	game:GetService("Workspace")["Fall Festival"]:FindFirstChild('FallPlatform') and
	game:GetService("Workspace")["Fall Festival"].FallPlatform:FindFirstChild('MrOakaly') then
	trait_label = game:GetService("Workspace")["Fall Festival"].FallPlatform.MrOakaly.BubblePart.FallMarketBillboard.BG.TraitTextLabel
	progress_label = workspace["Fall Festival"].FallPlatform.MrOakaly.ProgressPart.ProgressBilboard.UpgradeBar.ProgressionLabel
else error() 
end
local function getlf()
	local _,s = trait_label.Text:find('FFF\">',nil,true)
	if s then
		local f,_ = trait_label.Text:find(' Plants',s,true)
		if f then
			return trait_label.Text:sub(s+1,f-1)
		end
	end
end


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
		for _,obj in pairs(t) do
			for _,v in pairs(obj) do
				v:Disconnect()
			end
		end
	end
	for _,t in pairs(fruits) do
		for _,obj in pairs(t) do
			for _,v in pairs(obj) do
				v:Disconnect()
			end
		end
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
	if pet.PetData.MutationType and PetMutationRegistry.PetMutationRegistry[PetMutationRegistry.EnumToPetMutation[pet.PetData.MutationType] ].Boosts[1].BoostType == 'PASSIVE_BOOST' then
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
		if os.clock() > hold_tool_timeout then
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
		if os.clock() > hold_tool_timeout then
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

local inventory_listener
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



function getddsize(dicdic,keys)
  local size = 0
  for _,v in ipairs(keys) do
    for _ in pairs(dicdic[v]) do
      size = size + 1
    end
  end
  return size
end

local fall_cycle_last = 0.0
local fall_cycle_length = 0.2
local falloutput = ''
function do_fall_event()
  	if (os.clock() - fall_cycle_last) < fall_cycle_length then return end
	fall_cycle_last = os.clock()
	local reqtrait = getlf()
	if reqtrait and traitsdata[reqtrait] then
	  	if not progress_label.Text:find('Cooldown') and (299 - DateTime.now().UnixTimestamp + data.FallMarket.LastRewardClaimedTime) <= 0 then
			local frutbatch = {}
			get_fruit_from_groups(traitsdata[reqtrait],10,frutbatch)
			collect_fruit_batch(frutbatch)
			ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("FallMarketEvent"):WaitForChild("SubmitAllPlants"):FireServer()
	 	 end
	 	 falloutput = 300 - DateTime.now().UnixTimestamp + data.FallMarket.LastRewardClaimedTime .. ' ' .. reqtrait .. ' ' .. getddsize(sorted_fruits,traitsdata[reqtrait])
	end
end

function attributeMatch(obj,pos,neg)
	pos = pos or {}
	neg = neg or {}
	for _,attr in ipairs(pos) do 
		if not obj:GetAttribute(attr) == true then
			return false
		end 
	end
	for _,attr in ipairs(neg) do 
		if obj:GetAttribute(attr) == true then
			return false
		end 
	end
	return true
end

function findFirstNFruits(groups,n,pos_muts,neg_muts,output)
  local count = 0
  for _,v in ipairs(groups) do
  	for fruit in pairs(sorted_fruits[v]) do 
  		if attributeMatch(fruit,pos_muts,neg_muts) then
	        count = count + 1
	        table.insert(output,fruit)
	        if count >= n then 
	  			  return 
	        end
  		end 
  	end
  end
end

local rebirth_cycle_last = -10
local rebirth_cycle_length = 10
local rebirth_reset_time = require(ReplicatedStorage.Data.RebirthConfigData).RESET_TIME
local rebirth_output = ''
local required_fruit
local requried_fruit_tracker

local function dorebirth()
	if required_fruit then
		unfavorite_item(required_fruit)
		hold_tool(required_fruit,1)
		ReplicatedStorage.GameEvents.BuyRebirth:FireServer()
	end
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

local function usave_required_rebirth_fruit()
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
	if not required_fruit or required_fruit:GetAttribute('f') ~= req_plant or not attributeMatch(required_fruit,req_mutations) then
		if required_fruit then
			usave_required_rebirth_fruit()
		end
		for i in pairs(inventory_items.j) do
			if i:GetAttribute('f') == req_plant and attributeMatch(i,req_mutations,{'d'}) then
				savereqfruit(i)
				break
			end
		end
		if not required_fruit then
			for i in pairs(sorted_fruits[req_plant]) do
				if i.Name == req_plant and attributeMatch(i,req_mutations) then
					collect_fruit_batch({i})
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
					break
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
local run
run = RunService.Heartbeat:Connect(function(dt)
	if character:FindFirstChild('Shovel [Destroy Plants]') then 
		run:Disconnect() 
		diconec_farm_listener() 
		diconec_inventory_listener()
		usave_required_rebirth_fruit()
		Players.LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = 'script stopped'
		return 
	end
	do_fall_event()
	auto_rebirth()
	Players.LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = falloutput .. '\n' .. rebirth_output
end)
