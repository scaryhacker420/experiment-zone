local event_shop_data = require(game:GetService("ReplicatedStorage").Data.EventShopData)
local DataService = require(game:GetService("ReplicatedStorage").Modules.DataService):GetData()
local data = DataService:GetData()
local tobuy = {'Fall Egg','Marmot','Sugar Glider','Space Squirrel','Mallard','Red Panda'}

local function buyeventshop()
  for _,v in pairs(tobuy) do
    if data.EventShopStock[event_shop_data[v].ShopIndex] and 
    data.EventShopStock[event_shop_data[v].ShopIndex].Stocks[v] and 
    data.EventShopStock[event_shop_data[v].ShopIndex].Stocks[v] > 0 then
      for i = 1,data.EventShopStock[event_shop_data[v].ShopIndex].Stocks[v] do
        game:GetService("ReplicatedStorage").GameEvents.BuyEventShopStock:FIreServer(v,event_shop_data[v])
      end
    end
  end
end



local last_stock = {}
local buy_last_time 
local buy_cycle_length = 1
local stock_unchanged = 0

run = RunService.Heartbeat:Connect(function(dt)
	if workspace[user.Name]:FindFirstChild('Shovel [Destroy Plants]') then 

)
