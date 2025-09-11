local trees = {}
local fruits = {}
local grownfruit = {}
local multiharvest = {'Strawberry','Blueberry','Tomato','Corn','Apple','Coconut','Cactus','Dragon Fruit','Mango','Grape','Pepper','Cacao','Beanstalk','Ember Lily','Sugar Apple','Burning Bud','Giant Pinecone','Elder Strawberry','Romanesco','Sunbulb','Lightshoot','Glowthorn'}
local singleharvest = {'Bamboo','Mushroom','Orange Tulip','Daffodil','Watermelon','Pumpkin','Carrot'}
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
	if not fruits[fruit.Name] then fruits[fruit.Name] = {} end
	fruits[fruit.Name][fruit] = {} 
	fruits[fruit.Name][fruit].dc = fruit.AncestryChanged:Connect(function(child, parent)
        if not parent then
			for _,v in pairs(fruits[child.Name][child]) do
				v:Disconnect()
			end
          	fruits[child.Name][child] = nil
			if grownfruit[child.Name] then
				grownfruit[child.Name][child] = nil
			end
        end
    end)
	if fruit:GetAttribute('DoneGrowTime') then
		if not grownfruit[fruit.Name] then grownfruit[fruit.Name] = {} end
		grownfruit[fruit.Name][fruit] = true
	else
		fruits[fruit.Name][fruit].grown = fruit:GetAttributeChangedSignal('DoneGrowTime'):Connect(function()
			if not grownfruit[fruit.Name] then grownfruit[fruit.Name] = {} end
			grownfruit[fruit.Name][fruit] = true
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
	if singleharvest_map[child.Name] then addfruit(child)
  	elseif multiharvest_map[child.Name] then addtree(child)
	end
end)



for _,child in ipairs(theplants:GetChildren()) do
	
	if singleharvest_map[child.Name] then 
		addfruit(child)
	elseif multiharvest_map[child.Name] then
		addtree(child)
		for _,frut in ipairs(child.Fruits:GetChildren()) do
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

function findFirstMutatedFruitsInDic(dic,pos_muts,neg_muts)
	for fruit in pairs(dic) do 
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


local glimspray
local glimspraytracker
local function saveglimspray(g)
	glimspray = g
	glimspraytracker = g.AncestryChanged:Connect(function(child, parent)
        if not parent then
			glimspraytracker:Disconnect()
          	glimspraytracker = nil
			glimspray = nil
		end
	end)
end
local function findspray() 
  for _,v in ipairs(Players.LocalPlayer.Backpack:GetChildren()) do
    if v:GetAttribute('l') == 'Mutation Spray' and v:GetAttribute('m') == 'Glimmering' then saveglimspray(v) return true end
  end
  for _,v in ipairs(workspace[user]:GetChildren()) do
    if v:GetAttribute('l') == 'Mutation Spray' and v:GetAttribute('m') == 'Glimmering' then saveglimspray(v) return true end
  end
  return false
end 

local function spray(fruit)
	if not glimspray then if not findspray() then return 'no' end end
	glimspray.Parent = workspace[user]
	game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("SprayService_RE"):FireServer('TrySpray',fruit)
	
	Players.LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = 444
end

local function diconec()
	farmlistener:Disconnect()
	for _,type in pairs(trees) do
		for _,obj in pairs(type) do
			for _,v in pairs(obj) do
				v:Disconnect()
			end
		end
	end
	for _,type in pairs(fruits) do
		for _,obj in pairs(type) do
			for _,v in pairs(obj) do
				v:Disconnect()
			end
		end
	end
	if glimspraytracker then glimspraytracker:Disconnect() end
end 

local cycle_last = 0.0
local cycle_length = 2.0
local run

run = RunService.Heartbeat:Connect(function(dt)
	if workspace[user]:FindFirstChild('Shovel [Destroy Plants]') then run:Disconnect() diconec() return end
	--Players.LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = os.clock()
	if (os.clock() - cycle_last) > cycle_length then
		Players.LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = os.clock() 
		local count = 0
		for _,v in pairs(multiharvest) do
			if not fruits[v] then Players.LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = v break end
		end
		cycle_last = os.clock()
		local data = DataService:GetData()
		local tocollectglim = {}
		local tocollect = {}
		for _,v in ipairs({'Mango','Sunbulb','Lightshoot','Glowthorn'}) do
			if grownfruit[v] then
				table.insert(tocollect,table.pack(next(grownfruit[v]))[1])
			end
		end
		for _,v in ipairs(data.FairyQuests.Containers) do
				local quest = data.QuestContainers[v].Quests[1]
			if quest.Arguments[2] and (not quest.Completed) and grownfruit[quest.Arguments[1] ] and next(grownfruit[quest.Arguments[1] ]) then
				local glimfruit = findFirstMutatedFruitsInDic(grownfruit[quest.Arguments[1] ],{'Glimmering'})
				if glimfruit then 
					table.insert(tocollect,glimfruit)
				else
					table.insert(tocollectglim,table.pack(next(grownfruit[quest.Arguments[1] ]))[1])
				end
			end
		end	
		for _,v in ipairs(tocollectglim) do
				Players.LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = 333
			if spray(v) ~= 'no' then
				table.insert(tocollect,v)
			end
		end
		collectFruits(tocollect)
	end
end)

