
frame2 = CFrame.new(Vector3.new(0.0,100.0,0.0))

local player = Workspace.Player_Orientation_References:GetChildren()[1].Name
local player_farm = nil
for _,farm in pairs(Workspace.Farm:GetChildren()) do
	if farm.Important.Data.Owner.Value == player then
		player_farm = farm
		break
	end
end
local theplants = player_farm.Important.Plants_Physical

function getTrees(output_table,tree_names) 
	local name_map = {}
	for i,v in ipairs(tree_names) do 
		name_map[v]=i
	end 
	for _,tree in pairs(theplants:GetChildren()) do
		if name_map[tree.Name] then
			table.insert(output_table,tree)
		end
	end
end

function getGrownFruitsWithMutation(output_table,tree_list,mutation_list)
  local mutation_list = mutation_list or {}
  table.insert(mutation_list,'DoneGrowTime') 
	for _,tree in ipairs(tree_list) do
		for _,fruit in pairs(tree.Fruits:getChildren()) do 
			local notmatch = false  
			for _,mut in ipairs(mutation_list) do 
				if not fruit:GetAttribute(mut) then
					notmatch = true
					break
				end 
			end	 
			if not notmatch then
				table.insert(output_table,fruit)
			end 
		end
	end 
end 


function getGrownFruits(output_table,tree_list)
	for _,tree in ipairs(tree_list) do
		for _,fruit in pairs(tree.Fruits:getChildren()) do
			if fruit:GetAttribute('DoneGrowTime') then
				table.insert(output_table)
			end	
		end
	end
end

function findMutatedFruitsInList(output_table,list,mutations)
	for _,fruit in ipairs(list) do 
		local notmatch = false
		for mut in ipairs(mutatation_list) do
			if not fruit:GetAttribute(mut) then
				notmatch = true
				break
			end
		end	
		if not notmatch then
			table.insert(output_table,fruit)
		end
	end
end

function collectFruits(fruits)
	for _,fruit in ipairs(fruits) do 
		for _,fruit_part in pairs(fruit:GetChildren()) do
			if fruit_part.IsA('Part') and fruit_part:FindFirstChildOfClass(ProximityPrompt) then
				fireproximityprompt(fruit_part.ProximityPrompt)
				break
			end
		end
	end
end
	

local trees = {}
local rfruits = {}
getTrees(trees,{'Romanesco'})  
getGrownFruitsWithMutation(rfruits,trees,{'CloudTouched'}) 
collectFruits(rfruits) 



Workspace[player].HumanoidRootPart.CFrame = frame2
wait(1)
