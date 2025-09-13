game:GetService("Players").LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = 'a'
local function getlf()
	if game:GetService("Workspace").Interaction and
	game:GetService("Workspace").Interaction.UpdateItems and
	game:GetService("Workspace").Interaction.UpdateItems["Fall Festival"] and
	game:GetService("Workspace").Interaction.UpdateItems["Fall Festival"].FallPlatform and
	game:GetService("Workspace").Interaction.UpdateItems["Fall Festival"].FallPlatform.MrOakaly and
	game:GetService("Workspace").Interaction.UpdateItems["Fall Festival"].FallPlatform.MrOakaly.BubblePart and
	game:GetService("Workspace").Interaction.UpdateItems["Fall Festival"].FallPlatform.MrOakaly.BubblePart.FallMarketBillboard and
	game:GetService("Workspace").Interaction.UpdateItems["Fall Festival"].FallPlatform.MrOakaly.BubblePart.FallMarketBillboard.BG and
	game:GetService("Workspace").Interaction.UpdateItems["Fall Festival"].FallPlatform.MrOakaly.BubblePart.FallMarketBillboard.BG and
	game:GetService("Workspace").Interaction.UpdateItems["Fall Festival"].FallPlatform.MrOakaly.BubblePart.FallMarketBillboard.BG.TraitTextLabel then
		local _,s = game:GetService("Workspace").Interaction.UpdateItems["Fall Festival"].FallPlatform.MrOakaly.BubblePart.FallMarketBillboard.BG.TraitTextLabel.Text:find('FFF\">',nil,true)
		if s then
			local f,_ = game:GetService("Workspace").Interaction.UpdateItems["Fall Festival"].FallPlatform.MrOakaly.BubblePart.FallMarketBillboard.BG.TraitTextLabel.Text:find(' Plants',s,true)
			if f then
				return game:GetService("Workspace").Interaction.UpdateItems["Fall Festival"].FallPlatform.MrOakaly.BubblePart.FallMarketBillboard.BG.TraitTextLabel.Text:sub(s+1,f-1)
			end
		end
		
	end
end

local growabledata = require(game:GetService("ReplicatedStorage").Data.GrowableData):GetAllPlantData()
local traitsdata = require(game:GetService("ReplicatedStorage").Modules.PlantTraitsData).Traits
local shvst_map = {}
local mhvst_map = {}
for i,v in pairs(growabledata) do
	if v.PlantData.GrowFruitTime then
		if i == 'Mandrake' then
			shvst_map[i] = true
		else
			mhvst_map[i] = true
		end
	else
		shvst_map[i] = true
	end
end
local trait_map ={}
for trait,plants in pairs(traitsdata) do
	for _,p in ipairs(plants) do
    if not trait_map[p] then trait_map[p] = {} end
    table.insert(trait_map[p],trait)
	end
end

local trees = {}
local fruits = {}
local sorted_fruits = {}
local sorted_fruits_map = {}
local DataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local user = Players.LocalPlayer.Name 
local player_farm
for _,farm in pairs(workspace.Farm:GetChildren()) do
	if farm.Important.Data.Owner.Value == user then
		player_farm = farm
		break
	end
end
local theplants = player_farm.Important.Plants_Physical 

for i in pairs(traitsdata) do 
  sorted_fruits[i] = {}
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
  if not trait_map[fruit.Name] then return end
  sorted_fruits_map[fruit] = {}
  for _,v in ipairs(trait_map[fruit.Name]) do
    table.insert(sorted_fruits_map[fruit],v)
    sorted_fruits[v][fruit] = true
  end
end
  
local function addfruit(fruit)
	if not fruits[fruit.Name] then fruits[fruit.Name] = {} end
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
	if fruit:GetAttribute('DoneGrowTime') and fruit:GetAttribute('Favorited') ~= true then
		sort_fruit(fruit) 
	else
		fruits[fruit.Name][fruit].grown = fruit:GetAttributeChangedSignal('DoneGrowTime'):Connect(function()
			if fruit:GetAttribute('Favorited') == true then return end
			sort_fruit(fruit) 
		end) 
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
end
	
local farmlistener = theplants.ChildAdded:Connect(function(child)
  if trait_map[child.Name] then
  	if shvst_map[child.Name] then addfruit(child)
    	elseif mhvst_map[child.Name] then addtree(child)
  	end
  end
end) 

for _,child in ipairs(theplants:GetChildren()) do
  if trait_map[child.Name] then
  	if shvst_map[child.Name] then 
  		addfruit(child)
  	elseif mhvst_map[child.Name] then
  		addtree(child)
  		for _,frut in ipairs(child.Fruits:GetChildren()) do
  			addfruit(frut)
  		end
  	end 
  end
end

game:GetService("Players").LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = '111'
local function diconec()
	farmlistener:Disconnect()
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




function get_fruit_from_table(t,n,output)
  local count = 0
  for i in pairs(t) do
    table.insert(output,i)
    count = count + 1 
    if count >= n then 
      break
    end
  end
end
function collect_fruit_batch(fruits)
  if fruits and next(fruits) then
    game:GetService("ReplicatedStorage").GameEvents.Crops.Collect:FireServer(fruits)
  end
end



function getdsize(d)
  local size = 0
  for _ in pairs(d) do
    size = size + 1
  end
  return size
end

local cycle_last = 0.0
local cycle_length = 0.2
local run

run = RunService.Heartbeat:Connect(function(dt)
	if workspace[user]:FindFirstChild('Shovel [Destroy Plants]') then run:Disconnect() diconec() return end
	if (os.clock() - cycle_last) > cycle_length then
		cycle_last = os.clock()
    local data = DataService:GetData()
    local reqtrait = getlf()
    if reqtrait and sorted_fruits[reqtrait] then
      Players.LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = 300 - os.time() + data.FallMarket.LastRewardClaimedTime .. ' ' .. reqtrait .. ' ' .. getdsize(sorted_fruits[reqtrait])
  		if os.time() - data.FallMarket.LastRewardClaimedTime > 300 then
        local frutbatch = {}
        get_fruit_from_table(sorted_fruits[reqtrait],10,frutbatch)
        collect_fruit_batch(frutbatch)
        game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("FallMarketEvent"):WaitForChild("SubmitAllPlants"):FireServer()
      end
    else
      Players.LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = os.time() - data.FallMarket.LastRewardClaimedTime
    end
  end
end)


