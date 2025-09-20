game:GetService("Players").LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = 'a'
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
game:GetService("Players").LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = 'b'



local growabledata = require(game:GetService("ReplicatedStorage").Data.GrowableData):GetAllPlantData()
local traitsdata = require(game:GetService("ReplicatedStorage").Modules.PlantTraitsData).Traits
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

local inventory_enums = game:GetService("ReplicatedStorage").Data.EnumRegistry.InventoryServiceEnums
local item_type_enums = game:GetService("ReplicatedStorage").Data.EnumRegistry.ItemTypeEnums




local DataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
local data = DataService:GetData()
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local user = Players.LocalPlayer
local player_farm
for _,farm in pairs(workspace.Farm:GetChildren()) do
	if farm.Important.Data.Owner.Value == user.Name then
		player_farm = farm
		break
	end
end
local theplants = player_farm.Important.Plants_Physical 



game:GetService("Players").LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = '111'
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
			fruits[fruit.Name].grown:Disconnect()
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


local inventory_listener
local inventory_items = {}
local grouped_items = {}

local function diconec_inventory_listener()

end

local function start_inventry_listener()
end

local function add_inv_listener_group()

end

local function rm_inv_listener_group()
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
    game:GetService("ReplicatedStorage").GameEvents.Crops.Collect:FireServer(fruits)
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
function do_fall_event()
  if (os.clock() - fall_cycle_last) > fall_cycle_length then
    fall_cycle_last = os.clock()
    local reqtrait = getlf()
    if reqtrait and traitsdata[reqtrait] then
      if not progress_label.Text:find('Cooldown') and (300 - os.time() + data.FallMarket.LastRewardClaimedTime) <= 0 then
        local frutbatch = {}
        get_fruit_from_groups(traitsdata[reqtrait],10,frutbatch)
        collect_fruit_batch(frutbatch)
        game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("FallMarketEvent"):WaitForChild("SubmitAllPlants"):FireServer()
      end
      return 300 - os.time() + data.FallMarket.LastRewardClaimedTime .. ' ' .. reqtrait .. ' ' .. getddsize(sorted_fruits,traitsdata[reqtrait])
    end
  end
end

function attributeMatch(obj,pos,neg)
	if obj:GetAttribute('Favorited') == true then return false end
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

local rebirth_cycle_last = 0.0
local rebirth_cycle_length = 10
function auto_rebirth()
  if (os.clock() - rebirth_cycle_last) > rebirth_cycle_length then
    rebirth_cycle_last = os.clock()
   
  end
end


start_farm_listener()
game:GetService("Players").LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = '222'
local falloutput = ''
local run
run = RunService.Heartbeat:Connect(function(dt)
	if workspace[user.Name]:FindFirstChild('Shovel [Destroy Plants]') then 
		run:Disconnect() 
		diconec_farm_listener() 
		Players.LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = 'script stopped'
		return 
	end
	data = DataService:GetData()
	local s = ''
	falloutput = do_fall_event() or falloutput
	s = s .. falloutput
	Players.LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = s
end)
