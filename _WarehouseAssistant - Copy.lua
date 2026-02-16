-- Таблица с номерами аккаунтов и именами персонажей 
local accountCharacters = {
    ["01"] = {"Каменюшка", "Медь", "Шмоточка", "Пушечка", "Точная", "Ювелирная"},
    ["02"] = {"Рецептура", "Мушкет", "Сума", "Шмот", "Мортира"},
    ["03"] = {"Ниточка", "Кожаная", "Цветущая", "Извечка", "Пыльная", "Рулетик", "Рыбная", "Мясная"},
    ["04"] = {"Мензурочка", "Бумажная", "Крошшер", "Тернистая", "Красочка"},
    ["05"] = {"Складочка", "Упаковка", "Грузчик", "Пикап", "Пылинка", "Осколочная", "Замерзшая"},
}

-- Цвета: мягкий серый для неактивной кнопки и яркий зелёный для активной
local COLORS = {
    disabled = {0.5, 1, 0.5, 1}, -- Зеленый для неактивных
    enabled = {1, 0, 0, 1}, -- Красный для активных
    background = {0, 0, 0, 0.8}, -- Фон
}

-- Создаем фрейм для UI
local frame = CreateFrame("Frame", "WarehouseAssistantFrame", UIParent)
frame:SetSize(280, 120)
frame:SetPoint("CENTER")
frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
})
frame:SetBackdropColor(unpack(COLORS.background))
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- Кнопка сворачивания
local toggleButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
toggleButton:SetSize(20, 20)
toggleButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
toggleButton:SetText("_")

-- Состояние сворачивания
local isCollapsed = false
local function ToggleFrame()
    if isCollapsed then
        frame:SetHeight(120)
        toggleButton:SetText("_")
        for _, button in pairs(frame.buttons) do
            button:Show()
        end
    else
        frame:SetHeight(30)
        toggleButton:SetText("+")
        for _, button in pairs(frame.buttons) do
            button:Hide()
        end
    end
    isCollapsed = not isCollapsed
end

toggleButton:SetScript("OnClick", ToggleFrame)

-- Кнопки для аккаунтов
frame.buttons = {}
local function CreateButton(parent, account, position)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(40, 40)
    button:SetPoint("LEFT", (position - 1) * 50 + 20, 0)
    button:SetText(account)

    button:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
    button:SetBackdropColor(unpack(COLORS.disabled)) -- По умолчанию зелёный (неактивный)
    
    button:SetScript("OnEnter", function()
        local tooltip = GameTooltip
        tooltip:SetOwner(button, "ANCHOR_RIGHT")
        tooltip:AddLine("Персонажи аккаунта " .. account)
        local characters = accountCharacters[account]
        for _, character in ipairs(characters) do
            if character == button.characterOnline then
                tooltip:AddLine(character .. " (онлайн)", 0, 1, 0) -- Зелёный для онлайн
            else
                tooltip:AddLine(character, 1, 1, 1) -- Белый для оффлайн
            end
        end
        tooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("OnClick", function()
        if button.characterOnline then
            SendChatMessage("Хочу сдать предметы на этот склад", "WHISPER", nil, button.characterOnline)
        end
    end)

    return button
end

-- Создаем UI элементы для аккаунтов
for i, account in ipairs({"01", "02", "03", "04", "05"}) do
    frame.buttons[account] = CreateButton(frame, account, i)
end

-- Проверка онлайна персонажей через гильдейский список
local function CheckGuildRoster()
    GuildRoster() -- Обновляем данные гильдейского списка
    local guildMembers = {}
    
    for i = 1, GetNumGuildMembers() do
        local name, _, _, _, _, _, _, _, isOnline = GetGuildRosterInfo(i)
        if isOnline then
            local cleanedName = name:match("^(%S+)-?") -- Удаляем имя сервера, если оно есть
            guildMembers[cleanedName] = true
        end
    end
    
    -- Проверяем статусы аккаунтов
    for account, characters in pairs(accountCharacters) do
        local characterOnline = nil
        for _, characterName in ipairs(characters) do
            if guildMembers[characterName] then
                characterOnline = characterName
                break
            end
        end

        local button = frame.buttons[account]
        if characterOnline then
            button:SetBackdropColor(unpack(COLORS.enabled)) -- Зелёный (активный)
            button.characterOnline = characterOnline
        else
            button:SetBackdropColor(unpack(COLORS.disabled)) -- Мягкий зелёный (неактивный)
            button.characterOnline = nil
        end
    end
end

-- Регистрация событий
frame:RegisterEvent("GUILD_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        GuildRoster()
    end
    CheckGuildRoster()
end)

-- Таймер для проверки (в секундах)
local CHECK_INTERVAL = 1
local lastUpdate = 0

frame:SetScript("OnUpdate", function(self, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate >= CHECK_INTERVAL then
        lastUpdate = 0
        CheckGuildRoster()
    end
end)

-- Ручная проверка через команду
SLASH_WAREHOUSE1 = "/wh"
SlashCmdList["WAREHOUSE"] = CheckGuildRoster
