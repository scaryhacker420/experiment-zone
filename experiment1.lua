
frame2 = CFrame.new(Vector3.new(0.0,100.0,0.0))
frame = CFrame.new(Vector3.new(100.0,100.0,0.0))

local player = Workspace.Player_Orientation_References:GetChildren()[1].Name
local player_farm = nil
for _,farm in pairs(Workspace.Farm:GetChildren()) do
	if farm.Important.Data.Owner.Value == player then
		player_farm = farm
		break
	end
end
local theplants = player_farm.Important.Plants_Physical

function attributeMatch(obj,pos,neg)
	local pos = pos or {}
	local neg = neg or {}
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


function getTrees(output_table,tree_names) 
	local name_map = {}
	for i,v in ipairs(tree_names) do 
		name_map[v]=i
	end 
	for _,tree in ipairs(theplants:GetChildren()) do
		if name_map[tree.Name] then
			table.insert(output_table,tree)
		end
	end
end

function getFruitsWithMutations(output_table,tree_list,grown,pos_muts,neg_muts)
	pos_muts = pos_muts or {}
	if grown then
		table.insert(pos_muts,'DoneGrowTime') 
	end 
	for _,tree in ipairs(tree_list) do
		for _,fruit in ipairs(tree.Fruits:getChildren()) do 
			if attributeMatch(fruit,pos_muts,neg_muts) then
				table.insert(output_table,fruit)
			end 
		end
	end 
end 

function getFruitsWithMutationsLimited(output_table,tree_list,grown,limit,pos_muts,neg_muts)
	local count = 0
	pos_muts = pos_muts or {}
	if grown then
		table.insert(pos_muts,'DoneGrowTime') 
	end
	for _,tree in ipairs(tree_list) do
		for _,fruit in ipairs(tree.Fruits:getChildren()) do 
			if attributeMatch(fruit,pos_muts,neg_muts) then
				table.insert(output_table,fruit)
				count = count + 1
				if count >= limit then return end
			end 
		end
	end 
end 

function findMutatedFruitsInList(output_table,list,pos_muts,neg_muts)
	for _,fruit in ipairs(list) do 
		if attributeMatch(fruit,pos_muts,neg_muts) then
			table.insert(output_table,fruit)
		end 
	end
end

function collectFruits(fruits,limit)
	limit = limit or 999999999
	local count = 0
	for _,fruit in ipairs(fruits) do 
		for _,fruit_part in ipairs(fruit:GetChildren()) do 
			if fruit_part:IsA('Part') and fruit_part:FindFirstChildOfClass('ProximityPrompt') then 
				fireproximityprompt(fruit_part.ProximityPrompt)
				break
			end
		end
		
				
		count = count + 1
		if count >= limit then return end
	end
end
	

local trees = {}
local rfruits = {}
getTrees(trees,{'Romanesco'})  
getFruitsWithMutations(rfruits,trees,true) 
collectFruits(rfruits) 



Workspace[player].HumanoidRootPart.CFrame = frame
wait(1)
