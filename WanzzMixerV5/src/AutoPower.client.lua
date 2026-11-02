--[[
	WANZZMIXER V5-PRO | Auto Power (Roblox Luau LocalScript)
	Letakkan di: StarterPlayer > StarterPlayerScripts

	Cara kerja:
	- Memindai ProximityPrompt di workspace yang teksnya cocok dengan KEYWORDS_ON
	  (power, panel, hidup, dll) dan tidak cocok dengan KEYWORDS_SKIP (off, mati, dll).
	- Menekannya seperti pemain menekan tombol E (InputHoldBegin / InputHoldEnd).
	- Setiap prompt hanya ditekan SEKALI supaya power yang bersifat toggle tidak mati lagi.

	Batasan: hanya jalan kalau power/panel di game memakai ProximityPrompt.
	Script ini tidak menembak RemoteEvent acak. Kalau game memakai RemoteEvent / DMX,
	sambungkan lewat API resmi developer (isi fungsi customPowerOn di bawah).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

---------------------------------------------------------------------
-- CONFIG (sesuaikan dengan teks prompt di game)
---------------------------------------------------------------------
local CONFIG = {
	ENABLED_AT_START = true,
	SCAN_INTERVAL = 1.5, -- detik antar pemindaian
	PRESS_GAP = 0.35, -- jeda antar penekanan prompt
	AUTO_WALK = false, -- true: karakter berjalan (MoveTo) ke prompt yang jauh
	KEYWORDS_ON = { "power", "panel", "hidup", "nyala", "start", "switch", "turn on", "on/off" },
	KEYWORDS_SKIP = { "off", "mati", "stop", "delete", "hapus", "remove", "sell", "buy" },
}

-- Hook opsional: isi kalau developer menyediakan API resmi (RemoteEvent, dll).
-- Dipanggil sekali per scan dengan daftar prompt yang akan ditekan.
local function customPowerOn()
	-- contoh: game.ReplicatedStorage.Remotes.PowerAll:FireServer()
end

---------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------
local enabled = CONFIG.ENABLED_AT_START
local pressed = setmetatable({}, { __mode = "k" }) -- prompt -> true
local pressedCount = 0
local busy = false

---------------------------------------------------------------------
-- HELPER
---------------------------------------------------------------------
local function matchAny(text, list)
	text = string.lower(text)
	for _, kw in ipairs(list) do
		if string.find(text, kw, 1, true) then
			return true
		end
	end
	return false
end

local function promptText(prompt)
	local parts = { prompt.ActionText, prompt.ObjectText, prompt.Name }
	local p = prompt.Parent
	if p then
		table.insert(parts, p.Name)
		if p.Parent then
			table.insert(parts, p.Parent.Name)
		end
	end
	return table.concat(parts, " ")
end

local function shouldPress(prompt)
	if not prompt.Enabled or pressed[prompt] then
		return false
	end
	-- skip dibaca dari ActionText/ObjectText saja (teks tombol), supaya status "Turn Off" terdeteksi
	if matchAny(prompt.ActionText .. " " .. prompt.ObjectText, CONFIG.KEYWORDS_SKIP) then
		return false
	end
	return matchAny(promptText(prompt), CONFIG.KEYWORDS_ON)
end

local function promptPosition(prompt)
	local p = prompt.Parent
	if not p then
		return nil
	end
	if p:IsA("BasePart") then
		return p.Position
	elseif p:IsA("Attachment") then
		return p.WorldPosition
	elseif p:IsA("Model") then
		return p:GetPivot().Position
	end
	return nil
end

local function press(prompt)
	pressed[prompt] = true
	pressedCount += 1
	prompt:InputHoldBegin()
	task.wait(math.max(prompt.HoldDuration, 0) + 0.05)
	prompt:InputHoldEnd()
end

---------------------------------------------------------------------
-- UI KECIL (kanan bawah)
---------------------------------------------------------------------
local old = playerGui:FindFirstChild("WanzzAutoPower")
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "WanzzAutoPower"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent = playerGui

local btn = Instance.new("TextButton")
btn.AnchorPoint = Vector2.new(1, 1)
btn.Position = UDim2.new(1, -10, 1, -10)
btn.Size = UDim2.fromOffset(190, 38)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 12
btn.BorderSizePixel = 0
btn.Parent = gui
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

local function refreshButton()
	if enabled then
		btn.BackgroundColor3 = Color3.fromHex("#00e676")
		btn.TextColor3 = Color3.new(0, 0, 0)
		btn.Text = ("AUTO POWER: ON (%d)"):format(pressedCount)
	else
		btn.BackgroundColor3 = Color3.fromHex("#ff1744")
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Text = "AUTO POWER: OFF"
	end
end

btn.Activated:Connect(function()
	enabled = not enabled
	if enabled then
		table.clear(pressed) -- ON ulang = boleh menekan lagi dari awal
		pressedCount = 0
	end
	refreshButton()
end)
refreshButton()

---------------------------------------------------------------------
-- LOOP UTAMA
---------------------------------------------------------------------
local function scan()
	if busy or not enabled then
		return
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then
		return
	end

	busy = true
	pcall(customPowerOn)

	for _, inst in ipairs(workspace:GetDescendants()) do
		if not enabled then
			break
		end
		if inst:IsA("ProximityPrompt") and shouldPress(inst) then
			local pos = promptPosition(inst)
			if pos then
				local dist = (pos - root.Position).Magnitude
				if dist <= inst.MaxActivationDistance then
					press(inst)
					refreshButton()
					task.wait(CONFIG.PRESS_GAP)
				elseif CONFIG.AUTO_WALK then
					hum:MoveTo(pos)
					break -- jalan dulu, tekan di scan berikutnya
				end
			end
		end
	end
	busy = false
end

task.spawn(function()
	while true do
		scan()
		task.wait(CONFIG.SCAN_INTERVAL)
	end
end)
