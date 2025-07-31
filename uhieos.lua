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

-- Fungsi untuk menambah teks ke console
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

-- Ambil stock dari shop dengan filter stock > 0
local function getFilteredStock(shopName)
    local shopGui = player:WaitForChild("PlayerGui"):FindFirstChild(shopName, true)
    local filtered = {}
    if shopGui then
        local frame = shopGui:FindFirstChildWhichIsA("ScrollingFrame", true)
        if frame then
            for _, child in ipairs(frame:GetChildren()) do
                if child:IsA("Frame") and not child.Name:match("_Padding$") then
                    local name = child.Name
                    local stockLabel = child:FindFirstChild("Stock_Text", true)
                    if stockLabel and stockLabel:IsA("TextLabel") then
                        local stock = tonumber(stockLabel.Text:match("X(%d+)"))
                        if stock and stock > 0 then
                            table.insert(filtered, { name = name, stock = stock })
                        end
                    end
                end
            end
        end
    end
    return filtered
end

-- Previous data
local prev = { seed = {}, gear = {}, pet = {}, event = {} }

-- Kirim ke API
local function sendToAPI(seed, gear, pet, event)
    local payload = {
        seed_stock = seed,
        gear_stock = gear,
        pet_stock = pet,
        event_stock = event
    }
    http_request({
        Url = "https://fruit-api-rho.vercel.app/api/stock",
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(payload)
    })
    print("✅ Data terkirim ke API (filtered)")
end

-- Loop pengecekan
task.spawn(function()
    while true do
        local seedData = getFilteredStock("Seed_Shop")
        local gearData = getFilteredStock("Gear_Shop")
        local petData = getFilteredStock("PetShop_UI")
        local eventData = getFilteredStock("EventShop_UI")

        local changed = HttpService:JSONEncode(seedData) ~= HttpService:JSONEncode(prev.seed)
            or HttpService:JSONEncode(gearData) ~= HttpService:JSONEncode(prev.gear)
            or HttpService:JSONEncode(petData) ~= HttpService:JSONEncode(prev.pet)
            or HttpService:JSONEncode(eventData) ~= HttpService:JSONEncode(prev.event)

        if changed then
            clearLines()
            addLine("🌱 Seed Shop:")
            for _, item in ipairs(seedData) do addLine(item.name .. " = X" .. item.stock .. " Stock") end

            addLine("⚙️ Gear Shop:")
            for _, item in ipairs(gearData) do addLine(item.name .. " = X" .. item.stock .. " Stock") end

            addLine("🐾 Pet Shop:")
            for _, item in ipairs(petData) do addLine(item.name .. " = X" .. item.stock .. " Stock") end

            addLine("🎉 Event Shop:")
            for _, item in ipairs(eventData) do addLine(item.name .. " = X" .. item.stock .. " Stock") end

            prev.seed, prev.gear, prev.pet, prev.event = seedData, gearData, petData, eventData

            -- Kirim data dalam bentuk object
            local function toObj(data)
                local obj = {}
                for _, v in ipairs(data) do obj[v.name] = v.stock end
                return obj
            end
            sendToAPI(toObj(seedData), toObj(gearData), toObj(petData), toObj(eventData))
        end

        wait(5)
    end
end)
