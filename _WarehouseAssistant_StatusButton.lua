local addonName, WarehouseAssistantStatusButton = ...

-- Таблица для хранения состояния
local StatusButton = {
    isWorking = false,
    frame = nil,
    lastRankCheck = nil,
    checkAttempts = 0,
    timerFrame = nil
}

-- Таймер
local function CreateTimer()
    if not StatusButton.timerFrame then
        StatusButton.timerFrame = CreateFrame("Frame")
        StatusButton.timerFrame.timeElapsed = 0
        StatusButton.timerFrame:SetScript("OnUpdate", function(self, elapsed)
            self.timeElapsed = self.timeElapsed + elapsed
            if self.timeElapsed >= 0.5 then
                self.timeElapsed = 0
                self:Hide()
                if self.callback then
                    self.callback()
                end
            end
        end)
    end
    return StatusButton.timerFrame
end

local function After(delay, callback)
    local timer = CreateTimer()
    timer.callback = callback
    timer.timeElapsed = 0
    timer:Show()
end

-- Функция проверки прав доступа (проверяем начало строки)
local function CheckGuildPermissions()
    GuildRoster()
    
    if not IsInGuild() then 
        StatusButton.lastRankCheck = false
        return false 
    end
    
    local guildName = GetGuildInfo("player")
    if guildName ~= "Phoenix Nest" then 
        StatusButton.lastRankCheck = false
        return false 
    end
    
    local _, rankName = GetGuildInfo("player")
    
    -- Проверяем начало названия звания
    local hasPermission = (rankName and (strfind(rankName, "^Банкир") or strfind(rankName, "^Зам ГМ")))
    StatusButton.lastRankCheck = hasPermission
    return hasPermission
end

-- Функция обновления статуса кнопки
local function UpdateStatus()
    if not StatusButton.frame then return end
    
    if StatusButton.isWorking then
        StatusButton.frame:SetText("Работаю")
        StatusButton.frame:GetFontString():SetTextColor(0, 1, 0)
    else
        StatusButton.frame:SetText("Не работаю")
        StatusButton.frame:GetFontString():SetTextColor(1, 0, 0)
    end
end

-- Функция обновления видимости кнопки
local function UpdateButtonVisibility()
    if not StatusButton.frame then return end
    
    if CheckGuildPermissions() and StatusButton.lastRankCheck then
        StatusButton.frame:Show()
        UpdateStatus()
    else
        StatusButton.frame:Hide()
    end
end

-- Функция создания кнопки
local function CreateStatusButton()
    if not WarehouseAssistantFrame then
        if StatusButton.checkAttempts < 10 then
            StatusButton.checkAttempts = StatusButton.checkAttempts + 1
            After(0.5, CreateStatusButton)
        end
        return
    end

    if not StatusButton.frame then
        StatusButton.frame = CreateFrame("Button", nil, WarehouseAssistantFrame, "UIPanelButtonTemplate")
        StatusButton.frame:SetSize(130, 22)
        StatusButton.frame:SetPoint("TOPLEFT", WarehouseAssistantFrame, "TOPLEFT", 5, -3)
        
        -- Настройка текста
        local fontString = StatusButton.frame:GetFontString()
        fontString:SetPoint("CENTER", 0, 0)
        fontString:SetJustifyH("CENTER")
        fontString:SetFont("Fonts\\FRIZQT__.TTF", 11)
        fontString:SetShadowOffset(1, -1)
        
        -- Обработчик нажатия с дополнительной проверкой
        StatusButton.frame:SetScript("OnClick", function()
            if not CheckGuildPermissions() or not StatusButton.lastRankCheck then
                print("Ошибка: недостаточно прав")
                return
            end
            
            StatusButton.isWorking = not StatusButton.isWorking
            if StatusButton.isWorking then
                SendChatMessage("Принимаю списки на выдачу со склада", "GUILD")
            else
                SendChatMessage("Работа со складами завершена", "GUILD")
            end
            UpdateStatus()
        end)
        
        -- Первоначальная проверка видимости
        UpdateButtonVisibility()
    end
end

-- Обработчик событий
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "GUILD_ROSTER_UPDATE" then
        GuildRoster()
    end
    
    After(0.5, function()
        if StatusButton.frame then
            UpdateButtonVisibility()
        else
            CreateStatusButton()
        end
    end)
end)

-- Инициализация аддона
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")

initFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        self.loaded = true
    end
    
    if event == "PLAYER_LOGIN" and self.loaded then
        After(2, function()
            CreateStatusButton()
            UpdateButtonVisibility()
        end)
        self:UnregisterAllEvents()
    end
end)

-- Функция для ручной проверки (для отладки)
SLASH_WAREHOUSECHECK1 = "/warehousecheck"
SlashCmdList["WAREHOUSECHECK"] = function()
    print("=== Проверка прав гильдии ===")
    print("В гильдии:", IsInGuild() and "Да" or "Нет")
    if IsInGuild() then
        local guildName, rankName = GetGuildInfo("player")
        print("Название гильдии:", guildName)
        print("Полное звание:", rankName)
        
        -- Проверка по началу строки
        local hasAccess = (strfind(rankName, "^Банкир") or strfind(rankName, "^Зам/твин ГМ"))
        print("Доступ разрешен:", hasAccess and "Да" or "Нет")
    end
    UpdateButtonVisibility()
end