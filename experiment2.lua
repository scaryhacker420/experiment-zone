local trees = {}
local fruits = {}
local grownfruit = {}
local multiharvest = {'Strawberry','Blueberry','Tomato','Corn','Apple','Coconut','Cactus','Dragon Fruit','Mango','Grape','Peper','Cacao','Beanstalk','Ember Lily','Sugar Apple','Burning Bud','Giant Pinecone','Elder Strawbery','Romanesco'}
local singleharvest = {'Bamboo','Mushroom','Orange Tulip','Daffodil','Watermelon','Pumpkin'}
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

local function addmap(outputmap,inputordered)
  for _,v in ipairs(inputordered) do 
  	outputmap[v] = true
  end
end
local multiharvest_map = {}
local singleharvest_map = {}
addmap(multiharvest_map,multiharvest)
addmap(singleharvest_map,singleharvest)

local function addfruit(fruit)
	if not fruits[frut.Name] then fruits[fruit.Name] = {} end
	fruits[fruit.Name][fruit] = {} 
	fruits[fruit.Name][fruit].dc = fruit.AncestryChanged:Connect(function(child, parent)
        if not parent then
			for _,v in pairs(fruits[child.Name][child]) do
				v:Disconnect()
			end
          	fruits[child.Name][child] = nil
			grownfrut[child.Name][child] = nil
        end
    end)
	fruits[fruit.Name][fruit].grown = fruit:GetAttributeChangedSignal('DoneGrowTime'):Connect(function()
		if not grownfruit[fruit.Name] then grownfruit[fruit.Name] = {} end
		grownfruit[fruit.Name][frut] = 1
	end) 
end

local function addtree(tree)
	if not fruits[tree.Name] then fruits[tree.Name] = {} end
	trees[tree.Name][tree] = {}
	trees[tree.Name][tree].dc = tree.AncestryChanged:Connect(function(child, parent)
        if not parent then
			for _,v in pairs(trees[tree.Name][child]) do
				v:Disconnect()
			end
          	trees[tree.Name][tree] = nil
        end
    end)--[[
	trees[tree.Name][tree].newfruit = tree.Fruits.ChildAdded:Connect(function(frut)
		addfruit(child)
        if :GetAttribute('DoneGrowTime') then
			if not grownfruit[frut.Name] then grownfruit[frut.Name] = {} end
			grownfruit[frut.Name][frut] = 1
		end
    end) ]]
end
	--[[
local farmlistener = theplants.ChildAdded:Connect(function(child)
	if singleharvest_map[child.Name] then addfruit(child)
  	elseif multiharvest_map[child.Name] then addtree(child)
	end
end)

for _,child in ipairs(theplants.GetChildren()) do
	if singleharvest_map[child.Name] then addfruit(child)
	elseif multiharvest_map[child.Name] then 
		addtree(child)
		for _,frut in ipairs(child.Fruits.GetChildren()) do
			addfruit(frut)
		end
	end
end

function attributeMatch(obj,pos,neg)
	pos = pos or {}
	neg = neg or {}
	for _,attr in ipairs(pos) do 
		if not obj:GetAttribute(attr) then
			return false
		end 
	end
	for _,attr in ipairs(neg) do 
		if obj:GetAttribute(attr) then
			return false
		end 
	end
	return true
end

function findFirstMutatedFruitsInList(list,pos_muts,neg_muts)
	for _,fruit in ipairs(list) do 
		if attributeMatch(fruit,pos_muts,neg_muts) then
			return fruit
		end 
	end
end

function collectFruits(fruits,limit)
	limit = limit or 999999999
	local count = 0
	for _,fruit in ipairs(fruits) do 
		game:GetService("ReplicatedStorage").GameEvents.Crops.Collect:FireServer({fruit})
		count = count + 1
		if count >= limit then return end
	end
end
]]

local glimspray
local glimspraytracker
function findspray() 
  for _,v in ipairs(Players.LocalPlayer.Backpack:GetChildren()) do
    if v:GetAttribute('l') == 'Mutation Spray' and v:GetAttribute('m') == 'Glimmering' then saveglimspray(v) return true end
  end
  for _,v in ipairs(workspace[user]:GetChildren()) do
    if v:GetAttribute('l') == 'Mutation Spray' and v:GetAttribute('m') == 'Glimmering' then saveglimspray(v) return true end
  end
  return false
end 

function saveglimspray(g)
	glimspray = g
	glimspraytracker = t.AncestryChanged:Connect(function(child, parent)
        if not parent then
			glimspraytracker:Disconnect()
          	glimspraytracker = nil
			glimspray = nil
		end
	end)
end

function spray(fruit)
	if not glimspray then if not findspray() then return 'no' end end
	glimspray.Parent = workspace[user]
	game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("SprayService_RE"):FireServer('TrySpray',fruit)
end

local cycle_last = 0
local cycle_length = 4
local run
run = RunService.Heartbeat:Connect(function(dt)
	if workspace[user]:FindFirstChild('Shovel [Destroy Plants]') then run:Disconnect() return end
	Players.LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = os.clock()
	if os.clock() - cycle_last > cycle_length then
		cycle_last = os.clock()
		local data = DataService:GetData()
		local tocollectglim = {}
		local tocollect = {}
		for _,v in ipairs(tocollectglim) do
			if spray(v) ~= 'no' then
				table.insert(tocollect,v)
			end
		end
		collectFruits(tocollect)
	end
end)

