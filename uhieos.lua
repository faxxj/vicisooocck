local HttpService = game:GetService("HttpService")
local player = game.Players.LocalPlayer

-- GUI Console
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FruitConsole"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 400, 0, 400)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = ScreenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Text = "🍍 Fruit Console"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

-- Tombol Close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 18
closeBtn.Parent = mainFrame
closeBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)

-- Tombol Minimize
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -60, 0, 0)
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 18
minimizeBtn.Parent = mainFrame

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, -30)
scroll.Position = UDim2.new(0, 0, 0, 30)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Parent = scroll
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Toggle minimize
local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    scroll.Visible = not isMinimized
    mainFrame.Size = isMinimized and UDim2.new(0, 400, 0, 30) or UDim2.new(0, 400, 0, 400)
end)

local function addLine(text)
    local line = Instance.new("TextLabel")
    line.Size = UDim2.new(1, 0, 0, 20)
    line.BackgroundTransparency = 1
    line.Text = "• " .. text
    line.TextColor3 = Color3.fromRGB(255, 255, 255)
    line.Font = Enum.Font.Code
    line.TextSize = 16
    line.TextXAlignment = Enum.TextXAlignment.Left
    line.Parent = scroll
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
end

local function clearLines()
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
end

-- Fungsi ambil stock untuk shop apa saja
local function getStockFromShop(shopName)
    local shopGui = player:WaitForChild("PlayerGui"):FindFirstChild(shopName, true)
    if shopGui then
        local frame = shopGui:FindFirstChildWhichIsA("ScrollingFrame", true)
        if frame then
            local data = {}
            for _, child in ipairs(frame:GetChildren()) do
                if child:IsA("Frame") and not child.Name:match("_Padding$") then
                    local name = child.Name
                    local stockLabel = child:FindFirstChild("Stock_Text", true)
                    local stock = "?"
                    if stockLabel and stockLabel:IsA("TextLabel") then
                        stock = stockLabel.Text
                    end
                    table.insert(data, name .. " = " .. stock)
                end
            end
            return data
        end
    end
    return {}
end

-- Previous data untuk deteksi perubahan
local prev = {
    seed = {},
    gear = {},
    pet = {},
    event = {}
}

local function filterStock(dataArray)
    local filtered = {}
    for _, line in ipairs(dataArray) do
        local name, stock = line:match("^(.-)%s*=%s*X(%d+)%s*Stock$")
        if name and stock and tonumber(stock) > 0 then
            table.insert(filtered, name .. " = X" .. stock .. " Stock")
        end
    end
    return filtered
end

local function sendToAPI(seedData, gearData, petData, eventData)
    local payload = {
        seed_stock = filterStock(seedData),
        gear_stock = filterStock(gearData),
        pet_stock = filterStock(petData),
        event_stock = filterStock(eventData)
    }
    http_request({
        Url = "https://fruit-api-rho.vercel.app/api/stock",
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(payload)
    })
    print("✅ Data terkirim ke API (filtered)")
end

task.spawn(function()
    while true do
        local seedData = getStockFromShop("Seed_Shop")
        local gearData = getStockFromShop("Gear_Shop")
        local petData = getStockFromShop("PetShop_UI")
        local eventData = getStockFromShop("EventShop_UI")
        
        -- Cek perubahan
        local changed = (#seedData ~= #prev.seed) or (#gearData ~= #prev.gear) or 
                        (#petData ~= #prev.pet) or (#eventData ~= #prev.event)
        
        if not changed then
            for i = 1, #seedData do if seedData[i] ~= prev.seed[i] then changed = true break end end
            for i = 1, #gearData do if gearData[i] ~= prev.gear[i] then changed = true break end end
            for i = 1, #petData do if petData[i] ~= prev.pet[i] then changed = true break end end
            for i = 1, #eventData do if eventData[i] ~= prev.event[i] then changed = true break end end
        end
        
        if changed then
            clearLines()
            addLine("🌱 Seed Shop:")
            for _, line in ipairs(seedData) do addLine(line) end
            
            addLine("⚙️ Gear Shop:")
            for _, line in ipairs(gearData) do addLine(line) end
            
            addLine("🐾 Pet Shop:")
            for _, line in ipairs(petData) do addLine(line) end
            
            addLine("🎉 Event Shop:")
            for _, line in ipairs(eventData) do addLine(line) end
            
            prev.seed, prev.gear, prev.pet, prev.event = seedData, gearData, petData, eventData
            sendToAPI(seedData, gearData, petData, eventData)
        end
        
        wait(5)
    end
end)
