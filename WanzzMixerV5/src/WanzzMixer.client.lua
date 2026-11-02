--[[
	WANZZMIXER V5-PRO | grandMA2 x Pearl 1024B Engine
	Port Roblox Luau (LocalScript) dari versi HTML/Canvas.
	Letakkan di: StarterPlayer > StarterPlayerScripts

	Logika engine (state, presetMemory, rumus gerakan, case bank) sama dengan versi web.
	Perbedaan teknis: Canvas diganti Frame yang dirotasi + UIGradient untuk menggambar beam.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

---------------------------------------------------------------------
-- KONSTANTA & WARNA
---------------------------------------------------------------------
local TOTAL_BEAMS = 28

local C = {
	bgDark = Color3.fromHex("#090a0d"),
	panel = Color3.fromHex("#13151b"),
	card = Color3.fromHex("#1c1f28"),
	border = Color3.fromHex("#2c3140"),
	maYellow = Color3.fromHex("#ffb700"),
	pearlOrange = Color3.fromHex("#ff6d00"),
	redBrutal = Color3.fromHex("#ff1744"),
	cyanFx = Color3.fromHex("#00e5ff"),
	greenGo = Color3.fromHex("#00e676"),
	text = Color3.fromHex("#f1faee"),
	muted = Color3.fromHex("#8b92a5"),
}

---------------------------------------------------------------------
-- STATE ENGINE V5
---------------------------------------------------------------------
local engine = {
	mode = "center",
	speed = 45,
	panSize = 60,
	tiltSize = 70,
	phase = 35,
	dimmer = 100,
	color = Color3.fromHex("#00e5ff"),
	time = 0,
}

-- Penyimpanan parameter independen per gerakan (khas V5)
local presetMemory = {
	center = { speed = 0, panSize = 0, tiltSize = 0, phase = 0 },
	pargoy = { speed = 55, panSize = 75, tiltSize = 45, phase = 40 },
	tiltsaw = { speed = 50, panSize = 0, tiltSize = 85, phase = 30 },
	circlesym = { speed = 45, panSize = 65, tiltSize = 65, phase = 25 },
	wavewing = { speed = 48, panSize = 40, tiltSize = 80, phase = 55 },
	xcross = { speed = 40, panSize = 85, tiltSize = 50, phase = 15 },
	ballyhoo = { speed = 62, panSize = 90, tiltSize = 85, phase = 70 },
	fanopen = { speed = 20, panSize = 95, tiltSize = 30, phase = 50 },
	odd_even = { speed = 60, panSize = 35, tiltSize = 85, phase = 50 },
	brutal_shake = { speed = 95, panSize = 90, tiltSize = 95, phase = 80 },
	strobe_drop = { speed = 88, panSize = 20, tiltSize = 90, phase = 10 },
}

local savedCases = {
	{ name = "Case 1: Opening Pargoy", mode = "pargoy", speed = 55, panSize = 75, tiltSize = 45, phase = 40, color = Color3.fromHex("#00e5ff") },
	{ name = "Case 2: Drop Brutal", mode = "brutal_shake", speed = 95, panSize = 90, tiltSize = 95, phase = 80, color = Color3.fromHex("#ff1744") },
	{ name = "Case 3: Kipas Megah", mode = "fanopen", speed = 20, panSize = 95, tiltSize = 30, phase = 50, color = Color3.fromHex("#ffb700") },
	{ name = "Case 4: Sym Circle", mode = "circlesym", speed = 45, panSize = 65, tiltSize = 65, phase = 25, color = Color3.fromHex("#00e676") },
}

local FX_LIST = {
	{ "center", "01. STANDBY CENTER", false },
	{ "pargoy", "02. PARGOY HOREG V5", false },
	{ "tiltsaw", "03. TILT SAW UP/DOWN", false },
	{ "circlesym", "04. CIRCLE SYMMETRIC", false },
	{ "wavewing", "05. WAVE WING (MA2)", false },
	{ "xcross", "06. X-CROSS SWEEP", false },
	{ "ballyhoo", "07. BALLYHOO PARTY", false },
	{ "fanopen", "08. FANNING KIPAS", false },
	{ "odd_even", "09. GANJIL GENAP SNAP", false },
	{ "brutal_shake", "10. BRUTAL HOREG", true },
	{ "strobe_drop", "11. DROP BLINDER FX", true },
}

local COLOR_SWATCHES = { "#ffffff", "#ff1744", "#00e5ff", "#ffb700", "#00e676", "#d500f9" }

---------------------------------------------------------------------
-- HELPER UI
---------------------------------------------------------------------
local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		inst[k] = v
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(parent, r)
	return new("UICorner", { CornerRadius = UDim.new(0, r or 4) }, parent)
end

local function stroke(parent, color, thickness)
	return new("UIStroke", {
		Color = color or C.border,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function label(parent, text, size, color, font, xAlign)
	return new("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		TextSize = size or 12,
		TextColor3 = color or C.text,
		Font = font or Enum.Font.GothamBold,
		TextXAlignment = xAlign or Enum.TextXAlignment.Left,
	}, parent)
end

---------------------------------------------------------------------
-- ROOT GUI
---------------------------------------------------------------------
local old = playerGui:FindFirstChild("WanzzMixerV5")
if old then
	old:Destroy()
end

local gui = new("ScreenGui", {
	Name = "WanzzMixerV5",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local root = new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = C.bgDark,
	BorderSizePixel = 0,
}, gui)

-- TOP BAR ----------------------------------------------------------
local topBar = new("Frame", {
	Size = UDim2.new(1, 0, 0, 38),
	BackgroundColor3 = Color3.fromHex("#1a1d27"),
	BorderSizePixel = 0,
}, root)
new("Frame", {
	Size = UDim2.new(1, 0, 0, 2),
	Position = UDim2.new(0, 0, 1, -2),
	BackgroundColor3 = C.maYellow,
	BorderSizePixel = 0,
}, topBar)

local brand = label(topBar, "⚡ WANZZMIXER V5-PRO  |  28x BEAM CLARA S 14R", 13, C.maYellow)
brand.Size = UDim2.new(0.42, 0, 1, 0)
brand.Position = UDim2.new(0, 12, 0, 0)

local topRight = new("Frame", {
	Size = UDim2.new(0.58, -12, 1, 0),
	Position = UDim2.new(0.42, 0, 0, 0),
	BackgroundTransparency = 1,
}, topBar)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, topRight)

local patchInfo = label(topRight, "PATCH: DMX READY", 11, C.cyanFx)
patchInfo.Size = UDim2.new(0, 190, 0, 22)
patchInfo.BackgroundTransparency = 0
patchInfo.BackgroundColor3 = Color3.fromHex("#252936")
patchInfo.TextXAlignment = Enum.TextXAlignment.Center
patchInfo.LayoutOrder = 1
corner(patchInfo, 3)

local activeFxBadge = label(topRight, "FX: STANDBY CENTER", 11, C.cyanFx)
activeFxBadge.Size = UDim2.new(0, 210, 0, 22)
activeFxBadge.BackgroundTransparency = 0
activeFxBadge.BackgroundColor3 = Color3.fromHex("#252936")
activeFxBadge.TextXAlignment = Enum.TextXAlignment.Center
activeFxBadge.LayoutOrder = 2
corner(activeFxBadge, 3)

local stopBtn = new("TextButton", {
	Size = UDim2.new(0, 120, 0, 24),
	BackgroundColor3 = C.redBrutal,
	Text = "STOP / RESET ALL",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 11,
	Font = Enum.Font.GothamBold,
	AutoButtonColor = true,
	LayoutOrder = 3,
}, topRight)
corner(stopBtn, 3)

-- STAGE VISUALIZER -------------------------------------------------
local stage = new("Frame", {
	Size = UDim2.new(1, 0, 0, 230),
	Position = UDim2.new(0, 0, 0, 38),
	BackgroundColor3 = Color3.fromHex("#07090e"),
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, root)
new("UIGradient", {
	Color = ColorSequence.new(Color3.fromHex("#111520"), Color3.fromHex("#050608")),
	Rotation = 90,
}, stage)

local beamLayer = new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
}, stage)

local stageHeader = label(stage, "RIGGING TRUSS: 28 UNIT BEAM (1-14 KIRI | 15-28 KANAN)", 11, C.muted, Enum.Font.Gotham)
stageHeader.Size = UDim2.new(0.7, 0, 0, 16)
stageHeader.Position = UDim2.new(0, 12, 0, 6)
stageHeader.ZIndex = 5

local fpsLabel = label(stage, "ENGINE V5: 60 FPS LOCKED", 11, C.muted, Enum.Font.Gotham, Enum.TextXAlignment.Right)
fpsLabel.Size = UDim2.new(0.3, -12, 0, 16)
fpsLabel.Position = UDim2.new(0.7, 0, 0, 6)
fpsLabel.ZIndex = 5

-- Beam objects
local beams = {}
for i = 0, TOTAL_BEAMS - 1 do
	local beam = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(16, 100),
		BackgroundColor3 = engine.color,
		BorderSizePixel = 0,
	}, beamLayer)
	local grad = new("UIGradient", { Rotation = 90 }, beam)

	local dot = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(6, 6),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 4,
	}, beamLayer)
	corner(dot, 3)

	beams[i] = { frame = beam, grad = grad, dot = dot }
end

-- WORKSPACE --------------------------------------------------------
local workspaceFrame = new("Frame", {
	Size = UDim2.new(1, 0, 1, -268),
	Position = UDim2.new(0, 0, 0, 268),
	BackgroundTransparency = 1,
}, root)
new("UIPadding", {
	PaddingTop = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
}, workspaceFrame)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, workspaceFrame)

local function makePanel(order, widthScale, title, subtitle, subColor)
	local panel = new("Frame", {
		Size = UDim2.new(widthScale, -6, 1, 0),
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
		LayoutOrder = order,
	}, workspaceFrame)
	corner(panel, 5)
	stroke(panel, C.border)

	local head = new("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundColor3 = Color3.fromHex("#1d2029"),
		BorderSizePixel = 0,
	}, panel)
	corner(head, 5)
	local t = label(head, title, 11, C.maYellow)
	t.Size = UDim2.new(0.65, 0, 1, 0)
	t.Position = UDim2.new(0, 8, 0, 0)
	local s = label(head, subtitle, 10, subColor or C.muted, Enum.Font.Gotham, Enum.TextXAlignment.Right)
	s.Size = UDim2.new(0.35, -8, 1, 0)
	s.Position = UDim2.new(0.65, 0, 0, 0)

	local scroll = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -28),
		Position = UDim2.new(0, 0, 0, 28),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, panel)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	}, scroll)
	return scroll
end

local col1 = makePanel(1, 0.37, "1. V5 MOVEMENT & PARGOY ENGINE", "Pearl 1024B Shape", C.cyanFx)
local col2 = makePanel(2, 0.32, "2. INDEPENDENT SHAPE GENERATOR", "Anti-Stuck Touch")
local col3 = makePanel(3, 0.31, "3. UNLIMITED CASE MEMORY BANK", "V5 Storage")

---------------------------------------------------------------------
-- KOLOM 1: FX GRID + COLOR WHEEL
---------------------------------------------------------------------
local fxGrid = new("Frame", {
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
}, col1)
new("UIGridLayout", {
	CellSize = UDim2.new(0.3333, -4, 0, 40),
	CellPadding = UDim2.fromOffset(6, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, fxGrid)

local fxButtons = {}

local function styleFxButton(mode, active)
	local b = fxButtons[mode]
	if not b then
		return
	end
	local brutal = b:GetAttribute("brutal")
	if active then
		b.BackgroundColor3 = brutal and C.redBrutal or C.maYellow
		b.TextColor3 = brutal and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
	else
		b.BackgroundColor3 = C.card
		b.TextColor3 = brutal and Color3.fromHex("#ff8a80") or C.text
	end
end

local function setActiveButton(mode)
	for m in pairs(fxButtons) do
		styleFxButton(m, m == mode)
	end
end

-- state sinkronisasi slider (diisi setelah slider dibuat)
local syncSlidersUI

local function setV5Move(modeName)
	engine.mode = modeName
	setActiveButton(modeName)

	local mem = presetMemory[modeName]
	if mem then
		engine.speed = mem.speed
		engine.panSize = mem.panSize
		engine.tiltSize = mem.tiltSize
		engine.phase = mem.phase
		syncSlidersUI()
	end
	activeFxBadge.Text = "FX: " .. string.upper(modeName)
end

local function resetAllMovement()
	engine.mode = "center"
	engine.speed = 0
	engine.panSize = 0
	engine.tiltSize = 0
	engine.phase = 0
	engine.dimmer = 100
	syncSlidersUI()
	setActiveButton("center")
	activeFxBadge.Text = "FX: RESET / STANDBY CENTER"
end

for idx, fx in ipairs(FX_LIST) do
	local mode, text, brutal = fx[1], fx[2], fx[3]
	local btn = new("TextButton", {
		Text = text,
		TextWrapped = true,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		BackgroundColor3 = C.card,
		TextColor3 = C.text,
		BorderSizePixel = 0,
		LayoutOrder = idx,
		AutoButtonColor = false,
	}, fxGrid)
	btn:SetAttribute("brutal", brutal)
	corner(btn, 4)
	new("UIStroke", { Color = brutal and C.redBrutal or C.cyanFx, Thickness = 1, Transparency = 0.4 }, btn)
	fxButtons[mode] = btn
	btn.Activated:Connect(function()
		setV5Move(mode)
	end)
end

-- Tombol 12: hapus gerakan
local resetFxBtn = new("TextButton", {
	Text = "12. HAPUS GERAKAN",
	TextWrapped = true,
	TextSize = 11,
	Font = Enum.Font.GothamBold,
	BackgroundColor3 = Color3.fromHex("#2b191d"),
	TextColor3 = Color3.fromHex("#ff5252"),
	BorderSizePixel = 0,
	LayoutOrder = #FX_LIST + 1,
}, fxGrid)
corner(resetFxBtn, 4)
resetFxBtn.Activated:Connect(resetAllMovement)
stopBtn.Activated:Connect(resetAllMovement)

-- Color wheel
local colorTitle = label(col1, "COLOR WHEEL (CLARA 14R):", 10, C.muted, Enum.Font.Gotham)
colorTitle.Size = UDim2.new(1, 0, 0, 18)
colorTitle.Position = UDim2.new(0, 0, 0, 0)
-- posisi di bawah grid: pakai layout vertikal di col1
new("UIListLayout", {
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, col1)
fxGrid.LayoutOrder = 1
colorTitle.LayoutOrder = 2

local colorBar = new("Frame", {
	Size = UDim2.new(1, 0, 0, 26),
	BackgroundTransparency = 1,
	LayoutOrder = 3,
}, col1)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 5),
}, colorBar)
for _, hex in ipairs(COLOR_SWATCHES) do
	local sw = new("TextButton", {
		Text = "",
		Size = UDim2.new(1 / #COLOR_SWATCHES, -5, 1, 0),
		BackgroundColor3 = Color3.fromHex(hex),
		BorderSizePixel = 0,
		AutoButtonColor = false,
	}, colorBar)
	corner(sw, 3)
	stroke(sw, Color3.new(1, 1, 1), 1)
	sw.Activated:Connect(function()
		engine.color = Color3.fromHex(hex)
	end)
end

---------------------------------------------------------------------
-- KOLOM 2: SLIDER
---------------------------------------------------------------------
new("UIListLayout", {
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, col2)

local sliderSetters = {}
local updateParam -- forward declaration

local function makeSlider(order, key, title, fmt)
	local group = new("Frame", {
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = C.card,
		BorderSizePixel = 0,
		LayoutOrder = order,
	}, col2)
	corner(group, 4)
	stroke(group, Color3.fromHex("#262a36"))

	local lbl = label(group, title, 10, C.muted, Enum.Font.Gotham)
	lbl.Size = UDim2.new(0.7, 0, 0, 18)
	lbl.Position = UDim2.new(0, 8, 0, 4)

	local val = label(group, "", 11, C.maYellow, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
	val.Size = UDim2.new(0.3, -8, 0, 18)
	val.Position = UDim2.new(0.7, 0, 0, 4)

	-- area sentuh lebih tinggi supaya mudah di HP
	local hit = new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 0, 26),
		Position = UDim2.new(0, 8, 0, 22),
		Active = true,
	}, group)

	local track = new("Frame", {
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.new(0, 0, 0.5, -3),
		BackgroundColor3 = Color3.fromHex("#0d0f14"),
		BorderSizePixel = 0,
	}, hit)
	corner(track, 3)

	local fill = new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.maYellow,
		BorderSizePixel = 0,
	}, track)
	corner(fill, 3)

	local thumb = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.fromScale(0, 0.5),
		BackgroundColor3 = C.maYellow,
		BorderSizePixel = 0,
	}, track)
	corner(thumb, 8)
	stroke(thumb, Color3.new(1, 1, 1), 2)

	local dragging = false
	local function setFromX(x)
		local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		engine[key] = math.floor(rel * 100 + 0.5)
		updateParam()
	end

	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch)
		then
			setFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	sliderSetters[key] = function(v)
		fill.Size = UDim2.fromScale(v / 100, 1)
		thumb.Position = UDim2.fromScale(v / 100, 0.5)
		val.Text = fmt(v)
	end
end

local plain = function(v)
	return tostring(v)
end
makeSlider(1, "speed", "SPEED MASTER (BPM)", plain)
makeSlider(2, "panSize", "PAN SIZE / SWING WIDTH", plain)
makeSlider(3, "tiltSize", "TILT SIZE / HEIGHT", plain)
makeSlider(4, "phase", "PHASE SPREAD (GELOMBANG)", plain)
makeSlider(5, "dimmer", "MASTER DIMMER & STROBE", function(v)
	return v .. "%"
end)

function syncSlidersUI()
	for key, setter in pairs(sliderSetters) do
		setter(engine[key])
	end
end

function updateParam()
	-- Simpan langsung ke memori independen gerakan yang sedang aktif
	if presetMemory[engine.mode] then
		presetMemory[engine.mode] = {
			speed = engine.speed,
			panSize = engine.panSize,
			tiltSize = engine.tiltSize,
			phase = engine.phase,
		}
	end
	syncSlidersUI()
end

---------------------------------------------------------------------
-- KOLOM 3: CASE BANK & AUTO PATCH
---------------------------------------------------------------------
new("UIListLayout", {
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, col3)

local bankActions = new("Frame", {
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundTransparency = 1,
	LayoutOrder = 1,
}, col3)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 6),
}, bankActions)

local saveBtn = new("TextButton", {
	Text = "+ SIMPAN CASE",
	Size = UDim2.new(0.5, -3, 1, 0),
	BackgroundColor3 = C.greenGo,
	TextColor3 = Color3.new(0, 0, 0),
	TextSize = 11,
	Font = Enum.Font.GothamBold,
	BorderSizePixel = 0,
}, bankActions)
corner(saveBtn, 3)

local patchBtn = new("TextButton", {
	Text = "AUTO PATCH 28",
	Size = UDim2.new(0.5, -3, 1, 0),
	BackgroundColor3 = C.pearlOrange,
	TextColor3 = Color3.new(0, 0, 0),
	TextSize = 11,
	Font = Enum.Font.GothamBold,
	BorderSizePixel = 0,
}, bankActions)
corner(patchBtn, 3)

local caseList = new("Frame", {
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	LayoutOrder = 2,
}, col3)
new("UIGridLayout", {
	CellSize = UDim2.new(0.5, -3, 0, 34),
	CellPadding = UDim2.fromOffset(5, 5),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, caseList)

local function autoPatchClara()
	patchInfo.Text = "PATCH: 28x CLARA S 14R (UNIV 1-2 OK)"
	patchInfo.TextColor3 = C.greenGo
end
patchBtn.Activated:Connect(autoPatchClara)

local function renderCases()
	for _, child in ipairs(caseList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	for idx, c in ipairs(savedCases) do
		local item = new("TextButton", {
			Text = "",
			BackgroundColor3 = Color3.fromHex("#232733"),
			BorderSizePixel = 0,
			AutoButtonColor = true,
			LayoutOrder = idx,
		}, caseList)
		corner(item, 3)
		stroke(item, C.pearlOrange)

		local nameLbl = label(item, c.name, 10, C.text, Enum.Font.Gotham)
		nameLbl.Size = UDim2.new(1, -24, 1, 0)
		nameLbl.Position = UDim2.new(0, 6, 0, 0)
		nameLbl.TextWrapped = true

		local dot = label(item, "●", 12, c.color, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
		dot.Size = UDim2.new(0, 18, 1, 0)
		dot.Position = UDim2.new(1, -20, 0, 0)

		item.Activated:Connect(function()
			engine.mode = c.mode
			engine.speed = c.speed
			engine.panSize = c.panSize
			engine.tiltSize = c.tiltSize
			engine.phase = c.phase
			engine.color = c.color
			syncSlidersUI()
			activeFxBadge.Text = "CASE: " .. string.upper(c.name)
		end)
	end
end

local function saveCurrentCase()
	local id = #savedCases + 1
	table.insert(savedCases, {
		name = ("Case %d: %s"):format(id, string.upper(engine.mode)),
		mode = engine.mode,
		speed = engine.speed,
		panSize = engine.panSize,
		tiltSize = engine.tiltSize,
		phase = engine.phase,
		color = engine.color,
	})
	renderCases()
end
saveBtn.Activated:Connect(saveCurrentCase)

---------------------------------------------------------------------
-- CORE RENDER 28 BEAM V5 ENGINE
---------------------------------------------------------------------
local function animateBeams(dt)
	local stageW = beamLayer.AbsoluteSize.X
	local stageH = beamLayer.AbsoluteSize.Y
	if stageW <= 0 or stageH <= 0 then
		return
	end

	-- dt dinormalisasi ke 60 FPS supaya kecepatan sama dengan versi web
	engine.time += (engine.speed / 1000) * 1.8 * (dt * 60)

	local spacing = (stageW - 40) / (TOTAL_BEAMS - 1)
	local startY = 28

	for i = 0, TOTAL_BEAMS - 1 do
		local x = 20 + i * spacing

		-- Wing symmetry mirror (kiri 0-13, kanan 14-27)
		local isRightWing = i >= TOTAL_BEAMS / 2
		local wingIndex = isRightWing and (TOTAL_BEAMS - 1 - i) or i
		local mirrorDir = isRightWing and -1 or 1

		local phaseOffset = wingIndex * (engine.phase / 100) * 0.45
		local t = engine.time + phaseOffset

		local panOffset = 0
		local tiltLen = stageH * 0.75
		local alpha = (engine.dimmer / 100) * 0.55
		local mode = engine.mode

		if mode == "center" then
			panOffset = 0
			tiltLen = stageH * 0.78
		elseif mode == "pargoy" then
			panOffset = math.sin(t * 2) * (engine.panSize * 1.4) * mirrorDir
			tiltLen = (stageH * 0.55) + math.cos(t * 4) * (engine.tiltSize * 0.8)
		elseif mode == "tiltsaw" then
			panOffset = 0
			tiltLen = (stageH * 0.45) + math.sin(t * 2.5) * (engine.tiltSize * 1.2)
		elseif mode == "circlesym" then
			panOffset = math.cos(t * 2) * (engine.panSize * 1.2) * mirrorDir
			tiltLen = (stageH * 0.55) + math.sin(t * 2) * (engine.tiltSize * 0.9)
		elseif mode == "wavewing" then
			panOffset = math.sin(t * 1.5) * (engine.panSize * 0.6) * mirrorDir
			tiltLen = (stageH * 0.5) + math.sin(t * 3) * (engine.tiltSize * 1.1)
		elseif mode == "xcross" then
			local dir = (i % 2 == 0) and 1 or -1
			panOffset = (dir * math.sin(engine.time * 2)) * (engine.panSize * 1.5)
			tiltLen = stageH * 0.75
		elseif mode == "ballyhoo" then
			panOffset = math.sin(t * 2.7 + i) * (engine.panSize * 1.5)
			tiltLen = (stageH * 0.5) + math.cos(t * 3.3 - i) * (engine.tiltSize * 1.1)
		elseif mode == "fanopen" then
			local normalizedPos = (i - (TOTAL_BEAMS - 1) / 2) / (TOTAL_BEAMS / 2)
			panOffset = normalizedPos * (engine.panSize * 1.8) * (0.7 + 0.3 * math.sin(engine.time))
			tiltLen = stageH * 0.8
		elseif mode == "odd_even" then
			local isOdd = (i % 2 == 0)
			local snap = (math.sin(engine.time * 3) > 0) and 1 or -1
			local s = isOdd and snap or -snap
			panOffset = s * (engine.panSize * 0.8)
			tiltLen = (stageH * 0.55) + s * (engine.tiltSize * 0.9)
		elseif mode == "brutal_shake" then
			panOffset = math.sin(t * 8 + i) * (engine.panSize * 1.7) * mirrorDir
			tiltLen = (stageH * 0.5) + math.cos(t * 10) * (engine.tiltSize * 1.2)
			if math.random() > 0.35 then
				alpha = 0.85
			else
				alpha = 0.1
			end
		elseif mode == "strobe_drop" then
			panOffset = 0
			tiltLen = stageH * 0.85
			alpha = (math.sin(engine.time * 18) > 0) and 0.9 or 0.05
		end

		-- Hitung sorotan beam (garis dari truss ke target)
		local targetX = x + panOffset
		local targetY = math.max(45, startY + tiltLen)
		local dx = targetX - x
		local dy = targetY - startY
		local length = math.sqrt(dx * dx + dy * dy)

		local b = beams[i]
		b.frame.Size = UDim2.fromOffset(18, length)
		b.frame.Position = UDim2.fromOffset((x + targetX) / 2, (startY + targetY) / 2)
		b.frame.Rotation = -math.deg(math.atan2(dx, dy))
		b.frame.BackgroundColor3 = engine.color
		b.grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, math.clamp(1 - alpha, 0, 1)),
			NumberSequenceKeypoint.new(1, 1),
		})

		b.dot.Position = UDim2.fromOffset(x, startY)
	end
end

RunService.RenderStepped:Connect(animateBeams)

---------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------
setActiveButton("center")
syncSlidersUI()
renderCases()
