local trees = {}
local fruits = {}
local grownfruit = {}
local multiharvest = {'Strawberry','Blueberry','Tomato','Corn','Apple','Coconut','Cactus','Dragon Fruit','Mango','Grape','Peper','Cacao','Beanstalk','Ember Lily','Sugar Apple','Burning Bud','Giant Pinecone','Elder Strawbery','Romanesco'}
local singleharvest = {'Bamboo','Mushroom','Orange Tulip','Daffodil','Watermelon','Pumpkin','Carrot'}
local DataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local sheck = Players.LocalPlayer.PlayerGui.Sheckles_UI.TextLabel
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
	sheck.Text = type(fruits[fruit.Name])
	local self = fruit
	fruits[fruit.Name][fruit] = {}
	sheck.Text = 1
	fruits[fruit.Name][fruit].instance = fruit
	fruits[fruit.Name][fruit].conn = {}
	fruits[fruit.Name][fruit].conn.dc = fruit.AncestryChanged:Connect(function(child, parent)
        if not parent then
			sheck.Text = 333333333
			for _,v in pairs(fruits[child.Name][child].conn) do
				v:Disconnect()
			end
          	fruits[child.Name][child] = nil
        end
    end)
	sheck.Text = 2
	fruits[fruit.Name][fruit].conn.grown = fruit:GetAttributeChangedSignal('DoneGrowTime'):Connect(function()
			sheck.Text = 11111
		game:GetService("ReplicatedStorage").GameEvents.Crops.Collect:FireServer({fruit})
	end) 
	sheck.Text = 3
	--fruits[fruit.Name][fruit] = self
end
sheck.Text = theplants.Name
local farmlistener = theplants.ChildAdded:Connect(function(child)
		sheck.Text = '0000'
	if singleharvest_map[child.Name] then 
			sheck.Text = '000'
			addfruit(child)
			sheck.Text = '=='
			--sheck.Text = 46346
	end
end)  
local run
run = RunService.Heartbeat:Connect(function(dt)
	if workspace[user]:FindFirstChild('Shovel [Destroy Plants]') then run:Disconnect() farmlistener:Disconnect() return end
	--sheck.Text = os.clock()
end)
