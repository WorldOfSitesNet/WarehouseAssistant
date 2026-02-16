local addonName, WarehouseAssistant = ...

-- Создаем фрейм для обработки событий
local eventFrame = CreateFrame("Frame")

-- Переменная для хранения последнего известного количества слотов
local lastKnownFreeSlots = 0

local function CalculateActualFreeSlots()
    local totalFree = 0
    
    -- Основной инвентарь (16 слотов)
    for slot = 1, 16 do
        if not GetContainerItemInfo(0, slot) then
            totalFree = totalFree + 1
        end
    end
    
    -- Проверяем обычные сумки (1-4)
    for bag = 1, 4 do
        local bagType = select(2, GetContainerNumFreeSlots(bag))
        -- Тип 0 = обычная сумка, остальные (ключницы и т.д.) игнорируем
        if bagType == 0 then
            local numSlots = GetContainerNumSlots(bag)
            for slot = 1, numSlots do
                if not GetContainerItemInfo(bag, slot) then
                    totalFree = totalFree + 1
                end
            end
        end
    end
    
    return totalFree
end

local function UpdateFreeSlots()
    lastKnownFreeSlots = CalculateActualFreeSlots()
end

local function SaveFreeSlots()
    if not BankItems_Save then return end
    
    local playerKey = UnitName("player").."|"..GetRealmName()
    if not BankItems_Save[playerKey] then
        BankItems_Save[playerKey] = {}
    end
    
    -- Используем последнее известное значение
    BankItems_Save[playerKey].freeSlots = lastKnownFreeSlots
end

-- Регистрируем события
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        UpdateFreeSlots()
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    elseif event == "BAG_UPDATE" then
        UpdateFreeSlots()
    elseif event == "PLAYER_LOGOUT" then
        -- Сохраняем данные ДО того, как API перестанет работать
        SaveFreeSlots()
    end
end)