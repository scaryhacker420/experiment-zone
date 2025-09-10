local trees = {}
local fruits = {}
local multiharvest = {''}
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


theplants.ChildAdded:Connect(function(child)
	if singleharvest_map[child.Name] then fruits[child] = child.AncestryChanged:Connect(function(child, parent)
    if not parent then
        fruits[child] = nil
    end
  end)
  elseif multiharvest_map[child.Name] then trees[child] = {
    child.AncestryChanged:Connect(function(child, parent)
      if not parent then
        trees[child] = nil
      end
    end),
    child.Fruits.ChildAdded:Connect(function(frut)
      fruits[frut] = frut.AncestryChanged:Connect(function(child, parent)
        if not parent then
          fruits[child] = nil
        end
    end)
  end)}
  end
  end)

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
function findspray()
  for _,v in pairs(Players.LocalPlayer.Backpack:GetChildren())
    if v:GetAttribute('l') == 'Mutation Spray' and v:GetAttribute('m') == 'Glimmering' then glimspray = v return true end
  end
  for _,v in pairs(workspace[user]:GetChildren())
    if v:GetAttribute('l') == 'Mutation Spray' and v:GetAttribute('m') == 'Glimmering' then glimspray = v return true end
  end
  return false
end

function spray(fruit)
  if not glimspray then if not findspray() then return end end
  glimspray.Parent = workspace[user]
  game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("SprayService_RE"):FireServer({'TrySpray',fruit})
end


local run
run = RunService.Heartbeat:Connect(function(dt)
	if workspace[user]:FindFirstChild('Shovel [Destroy Plants]') then run:Disconnect() return end
	local data = DataService:GetData()
	for i in pairs(fruits) do 
    spray(i)
  end
	Players.LocalPlayer.PlayerGui.Sheckles_UI.TextLabel.Text = os.clock()
end)

