local flappy_zeal_addon = {
    name = "Flappy zeal",
    version = "1.0.0",
    author = "Fmp",
    desc = "Zeal takes flight"
}

-- Avoid global name collisions by declaring file locals
local canvas
local zealHitbox
local zealIconView
local refreshButton
local gameOverTextView
local scoreTextView
local obstacles = {}

local windowWidth = 1200
local windowHeight = 800
local gravity = 0.03

local isGameOver = false
local wasShiftDown = false

local minGapSize = 120
local startingGapSize = 350
local gapSize = 350
local pillarDistance = 400
local score = 0

local function DrawView()
    zealIconView:AddAnchor("TOPLEFT", canvas, "TOPLEFT", zealHitbox.x, zealHitbox.y)
    scoreTextView:SetText("Score: " .. score)

    for index, pillar in ipairs(obstacles) do 
        local isOnScreen = pillar.x < 0
        pillar.top:Show(isOnScreen)
        pillar.bottom:Show(isOnScreen)

        pillar.topWidthAnchor:AddAnchor("TOPRIGHT", canvas, pillar.x - pillar.width, pillar.topHeight)
        pillar.top:AddAnchor("TOPRIGHT", canvas, pillar.x, 0)
        pillar.top:AddAnchor("BOTTOMLEFT", pillar.topWidthAnchor, 0, 0)

        pillar.bottomWidthAnchor:AddAnchor("BOTTOMRIGHT", canvas, pillar.x - pillar.width, -1 * pillar.bottomHeight)
        pillar.bottom:AddAnchor("BOTTOMRIGHT", canvas, pillar.x, 0)
        pillar.bottom:AddAnchor("TOPLEFT", pillar.bottomWidthAnchor, 0, 0)
    end
end

local function CheckInput() 
    local isShiftDown = api.Input:IsShiftKeyDown()

    if isShiftDown and not wasShiftDown then 
        zealHitbox.velocity = -3.3
    end

    wasShiftDown = isShiftDown
end

local function endGame()
    isGameOver = true
    refreshButton:Show(true)
    gameOverTextView:Show(true)
end

local function resetPillar(x, pillar)
    pillar.x = x
    pillar.topHeight = math.random(100, windowHeight - 100 - gapSize)
    pillar.bottomHeight = windowHeight - (pillar.topHeight + gapSize)
    pillar.scored = false
end

local function spawnPillar(x)
    local pillar = {}
    pillar.scored = false
    pillar.x = x
    pillar.topHeight = math.random(100, windowHeight - 100 - gapSize)
    pillar.bottomHeight = windowHeight - (pillar.topHeight + gapSize)
    pillar.width = 50
    pillar.velocity = -2

    pillar.topWidthAnchor = canvas:CreateChildWidget("label", "widthAnchor", 0, true)

    pillar.top = api.Interface:CreateStatusBar("bgStatusBar", canvas, "item_evolving_material")
    pillar.top.bg:SetColor(ConvertColor(15), ConvertColor(15), ConvertColor(15), 1)


    pillar.bottomWidthAnchor = canvas:CreateChildWidget("label", "widthAnchor", 0, true)

    pillar.bottom = api.Interface:CreateStatusBar("bgStatusBar", canvas, "item_evolving_material")
    pillar.bottom.bg:SetColor(ConvertColor(15), ConvertColor(15), ConvertColor(15), 1)
    table.insert(obstacles, pillar)
end

local function checkCollisions(pillar)
    -- Zeal is anchored via top left, pillars are anchored via right
    local flippedPillarX = pillar.x * -1

    if zealHitbox.x <= flippedPillarX + pillar.width + zealHitbox.size and zealHitbox.x >= flippedPillarX and
        (
            zealHitbox.y <= pillar.topHeight or zealHitbox.y >= windowHeight - pillar.bottomHeight - zealHitbox.size
        ) then
            endGame()
    end
end

local function checkScore(pillar)
    if zealHitbox.x <= (pillar.x * -1) and not pillar.scored then
        pillar.scored = true
        score = score + 1
    end
end

local function CalculatePhysics() 
    -- Zeal
    -- Apply velocity
    zealHitbox.y = zealHitbox.y + zealHitbox.velocity

    -- Check bounds
    if zealHitbox.y < 0 then 
        zealHitbox.y = 0
        zealHitbox.velocity = 0
    end

    -- Pillars
    for index, pillar in ipairs(obstacles) do 
        -- Apply velocity
        pillar.x = pillar.x + pillar.velocity

        -- Check bounds
        if -1 * pillar.x >= windowWidth - pillar.width then
            gapSize = math.max(minGapSize, gapSize - 15)
            resetPillar(0, pillar)
        end

        -- Check collisions
        checkCollisions(pillar)
        checkScore(pillar)
    end

    if zealHitbox.y >= windowHeight - zealHitbox.size then
        endGame()
    end

    -- Apply gravity
    zealHitbox.velocity = zealHitbox.velocity + gravity
end

local function OnDraw()
    CheckInput()
    if not isGameOver then
        CalculatePhysics()
    end
    DrawView()
end

-- Both initializes and resets the game
local function InitializeGame()
    zealHitbox.x = windowWidth / 2
    zealHitbox.y = windowHeight / 2

    zealHitbox.velocity = 0

    gapSize = startingGapSize

    for index, pillar in ipairs(obstacles) do 
        resetPillar(pillarDistance * (index - 1), pillar)
    end

    score = 0

    isGameOver = false

    zealIconView:Show(true)
    refreshButton:Show(false)
    gameOverTextView:Show(false)
end

local function OnLoad() 
    -- Create canvas
    canvas = api.Interface:CreateWindow("Canvas", "", windowWidth, windowHeight)
    canvas:Show(true)
    canvas:AddAnchor("CENTER", "UIParent", 0, 0)
    
    -- Create icon
    zealIconView = CreateItemIconButton("zealIcon", canvas)
    local trackedBuffInfo = api.Ability:GetBuffTooltip(495)
	F_SLOT.ApplySlotSkin(zealIconView, zealIconView.back, SLOT_STYLE.BUFF)
    F_SLOT.SetIconBackGround(zealIconView, trackedBuffInfo.path)

    -- Create restart button
    refreshButton = canvas:CreateChildWidget("button", "refreshButton", 0, true)
    refreshButton:AddAnchor("BOTTOMRIGHT", canvas, "BOTTOMRIGHT", -10, -10)
    refreshButton:SetHandler("OnClick", InitializeGame)
    ApplyButtonSkin(refreshButton, BUTTON_BASIC.RESET)

    -- Create game over text view
    gameOverTextView = canvas:CreateChildWidget("label", "label", 0, true)
	gameOverTextView:SetText("Game over!")
	gameOverTextView:AddAnchor("CENTER", canvas, "CENTER", 0, -150)
	gameOverTextView.style:SetFontSize(44)
    ApplyTextColor(
        gameOverTextView, {
            ConvertColor(15),
            ConvertColor(15),
            ConvertColor(15),
            1
        }
    )

    -- Create hitbox for the zeal icon
    zealHitbox = {}
    zealHitbox.size = 43

    InitializeGame()

    -- Spawn the pillars into the game, with some off screen
    spawnPillar(0)
    spawnPillar(pillarDistance)
    spawnPillar(pillarDistance * 2)

    -- Add the score, must be done after pillars are added so the score text is rendered on top
    scoreTextView = canvas:CreateChildWidget("label", "label", 0, true)
    scoreTextView:Show(true)
	scoreTextView:AddAnchor("BOTTOMRIGHT", canvas, "BOTTOMRIGHT", -150, -30)
	scoreTextView.style:SetFontSize(44)

    -- Register frame callback
    api.On("UPDATE", OnDraw)
end

local function OnUnload()
	if canvas ~= nil then
		canvas:Show(false)
		canvas = nil
	end
end

flappy_zeal_addon.OnLoad = OnLoad
flappy_zeal_addon.OnUnload = OnUnload

return flappy_zeal_addon