local event_shop_data = require(game:GetService("ReplicatedStorage").Data.EventShopData)
local DataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local user = Players.LocalPlayer
local data = DataService:GetData()
local tobuy = {'Fall Egg''Space Squirrel','Mallard','Red Panda','Acorn Bell','Acorn Lollipop','Super Leaf Blower','Maple Crate'}

local function buyeventshop()
  for _,v in ipairs(tobuy) do
    if data.EventShopStock[event_shop_data[v].ShopIndex] and 
    data.EventShopStock[event_shop_data[v].ShopIndex].Stocks[v] and 
    data.EventShopStock[event_shop_data[v].ShopIndex].Stocks[v].Stock > 0 then
      for i = 1,data.EventShopStock[event_shop_data[v].ShopIndex].Stocks[v].Stock do
        game:GetService("ReplicatedStorage").GameEvents.BuyEventShopStock:FireServer(v,event_shop_data[v].ShopIndex)
      end
    end
  end
end

local last_stock = {}
local function save_last_stock()
	for _,v in ipairs(tobuy) do
		 if data.EventShopStock[event_shop_data[v].ShopIndex] and 
		data.EventShopStock[event_shop_data[v].ShopIndex].Stocks[v] then
			last_stock[v] = data.EventShopStock[event_shop_data[v].ShopIndex].Stocks[v].Stock
		else
			last_stock[v] = 0
		end
	end
end
		
local last_buy_time = 0
local buy_cycle_length = 1
local stock_unchanged = 0

run = RunService.Heartbeat:Connect(function(dt)
	if workspace[user.Name]:FindFirstChild('Shovel [Destroy Plants]') then 
		run:Disconnect() 
		return
	end
	if os.clock() - last_buy_time > buy_cycle_length then
		last_buy_time = os.clock() 
		data = DataService:GetData()
		for _,v in ipairs(tobuy) do
			 if data.EventShopStock[event_shop_data[v].ShopIndex] and 
			data.EventShopStock[event_shop_data[v].ShopIndex].Stocks[v] and 
			data.EventShopStock[event_shop_data[v].ShopIndex].Stocks[v].Stock ~= last_stock[v] then
				stock_unchanged = 0
				break
			end
		end
		if stock_unchanged < 4 then
			buyeventshop()
		end
		stock_unchanged = stock_unchanged + 1
	end
end)
