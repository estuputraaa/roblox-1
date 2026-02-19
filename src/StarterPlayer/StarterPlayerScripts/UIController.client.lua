--[[
UIController (Client)
- Merender HUD dasar dan event feed dari payload remote server.
- Semua handler remote dibuat defensif agar payload tidak lengkap tidak menyebabkan crash UI.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local shared = ReplicatedStorage:WaitForChild("Shared")
local sharedRemotes = shared:WaitForChild("Remotes")
local RemoteNames = require(sharedRemotes:WaitForChild("RemoteNames"))

local runtimeRemotes = ReplicatedStorage:WaitForChild("Remotes")

local function getRemoteEvent(remoteName)
	local remote = runtimeRemotes:FindFirstChild(remoteName)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	local fetched = runtimeRemotes:WaitForChild(remoteName, 8)
	if fetched and fetched:IsA("RemoteEvent") then
		return fetched
	end
	return nil
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "JagaWarnetHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local topLeftFrame = Instance.new("Frame")
topLeftFrame.Name = "TopLeftHUD"
topLeftFrame.Size = UDim2.new(0, 360, 0, 190)
topLeftFrame.Position = UDim2.fromOffset(14, 14)
topLeftFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 30)
topLeftFrame.BackgroundTransparency = 0.15
topLeftFrame.BorderSizePixel = 0
topLeftFrame.Parent = screenGui

local function newLabel(name, posY, text, sizeY)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, -16, 0, sizeY or 24)
	label.Position = UDim2.new(0, 8, 0, posY)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 16
	label.TextColor3 = Color3.fromRGB(233, 238, 245)
	label.Text = text
	label.Parent = topLeftFrame
	return label
end

local dayLabel = newLabel("DayLabel", 10, "Day: 1")
local phaseLabel = newLabel("PhaseLabel", 36, "Phase: Pagi")
local timerLabel = newLabel("TimerLabel", 62, "Sisa Waktu: 05:00")
local cashLabel = newLabel("CashLabel", 88, "Cash: Rp 0")

local objectiveLabel = newLabel("ObjectiveLabel", 116, "Objective: Survive sampai hari 7", 36)
objectiveLabel.TextWrapped = true
objectiveLabel.TextYAlignment = Enum.TextYAlignment.Top
objectiveLabel.Font = Enum.Font.Gotham
objectiveLabel.TextSize = 14

local hintLabel = newLabel("HintLabel", 154, "Hint: TungTung / portal tersembunyi", 28)
hintLabel.TextWrapped = true
hintLabel.TextYAlignment = Enum.TextYAlignment.Top
hintLabel.Font = Enum.Font.Gotham
hintLabel.TextSize = 13
hintLabel.TextColor3 = Color3.fromRGB(150, 193, 255)

local eventFeedFrame = Instance.new("Frame")
eventFeedFrame.Name = "EventFeedFrame"
eventFeedFrame.Size = UDim2.new(0, 540, 0, 152)
eventFeedFrame.Position = UDim2.new(0.5, -270, 0, 14)
eventFeedFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
eventFeedFrame.BackgroundTransparency = 0.1
eventFeedFrame.BorderSizePixel = 0
eventFeedFrame.Parent = screenGui

local eventTitle = Instance.new("TextLabel")
eventTitle.Name = "EventTitle"
eventTitle.Size = UDim2.new(1, -14, 0, 24)
eventTitle.Position = UDim2.fromOffset(7, 6)
eventTitle.BackgroundTransparency = 1
eventTitle.TextXAlignment = Enum.TextXAlignment.Left
eventTitle.Font = Enum.Font.GothamBold
eventTitle.TextSize = 15
eventTitle.TextColor3 = Color3.fromRGB(255, 215, 120)
eventTitle.Text = "Event Feed"
eventTitle.Parent = eventFeedFrame

local eventBody = Instance.new("TextLabel")
eventBody.Name = "EventBody"
eventBody.Size = UDim2.new(1, -14, 1, -36)
eventBody.Position = UDim2.fromOffset(7, 30)
eventBody.BackgroundTransparency = 1
eventBody.TextXAlignment = Enum.TextXAlignment.Left
eventBody.TextYAlignment = Enum.TextYAlignment.Top
eventBody.TextWrapped = true
eventBody.Font = Enum.Font.Gotham
eventBody.TextSize = 13
eventBody.TextColor3 = Color3.fromRGB(229, 232, 238)
eventBody.Text = "[INFO] Menunggu update server..."
eventBody.Parent = eventFeedFrame

local alertLabel = Instance.new("TextLabel")
alertLabel.Name = "AlertLabel"
alertLabel.Size = UDim2.new(0.72, 0, 0, 46)
alertLabel.Position = UDim2.new(0.14, 0, 0.82, 0)
alertLabel.BackgroundColor3 = Color3.fromRGB(40, 15, 15)
alertLabel.BackgroundTransparency = 0.15
alertLabel.BorderSizePixel = 0
alertLabel.Font = Enum.Font.GothamBold
alertLabel.TextSize = 18
alertLabel.TextColor3 = Color3.fromRGB(255, 236, 236)
alertLabel.Text = ""
alertLabel.Visible = false
alertLabel.Parent = screenGui

local feedEntries = {}
local maxFeedEntries = 5

local function formatClock(secondsValue)
	local seconds = math.max(0, math.floor(tonumber(secondsValue) or 0))
	local minutesPart = math.floor(seconds / 60)
	local remain = seconds % 60
	return string.format("%02d:%02d", minutesPart, remain)
end

local function formatCash(cash)
	local normalized = math.max(0, math.floor(tonumber(cash) or 0))
	return ("Rp %d"):format(normalized)
end

local function pushFeed(message, level)
	local safeMessage = tostring(message or "-")
	local safeLevel = string.upper(tostring(level or "info"))
	local line = ("[%s] %s"):format(safeLevel, safeMessage)
	table.insert(feedEntries, 1, line)
	while #feedEntries > maxFeedEntries do
		table.remove(feedEntries, #feedEntries)
	end
	eventBody.Text = table.concat(feedEntries, "\n")
end

local function showAlert(message, level)
	alertLabel.Visible = true
	alertLabel.Text = tostring(message or "Notifikasi")
	if level == "critical" then
		alertLabel.BackgroundColor3 = Color3.fromRGB(95, 23, 23)
	elseif level == "warning" then
		alertLabel.BackgroundColor3 = Color3.fromRGB(83, 58, 24)
	else
		alertLabel.BackgroundColor3 = Color3.fromRGB(23, 52, 83)
	end

	task.delay(6, function()
		if alertLabel.Text == tostring(message or "Notifikasi") then
			alertLabel.Visible = false
		end
	end)
end

local function applyHudPayload(payload)
	if type(payload) ~= "table" then
		return
	end

	dayLabel.Text = ("Day: %s"):format(tostring(payload.day or "1"))
	phaseLabel.Text = ("Phase: %s"):format(tostring(payload.phaseLabel or payload.phase or "Pagi"))
	timerLabel.Text = ("Sisa Waktu: %s"):format(formatClock(payload.timeRemainingSeconds))
	cashLabel.Text = ("Cash: %s"):format(formatCash(payload.cash))
	objectiveLabel.Text = ("Objective: %s"):format(tostring(payload.objective or "Survive sampai hari 7"))
	local hintText = tostring(payload.hint or "Cari petunjuk ending tersembunyi.")
	if payload.continueAvailable then
		local continuePrice = math.max(0, math.floor(tonumber(payload.continuePriceRobux) or 0))
		local usageCount = math.max(0, math.floor(tonumber(payload.continueUsageCount) or 0))
		hintText = ("%s | Continue: %d Robux (pakai: %d)"):format(hintText, continuePrice, usageCount)
	end
	hintLabel.Text = ("Hint: %s"):format(hintText)
end

local function connectRemote(remoteName, handler)
	local remote = getRemoteEvent(remoteName)
	if not remote then
		warn(("UIController: remote '%s' tidak ditemukan"):format(remoteName))
		return
	end
	remote.OnClientEvent:Connect(function(payload)
		local ok, err = pcall(handler, payload)
		if not ok then
			warn(("UIController: handler error remote '%s': %s"):format(remoteName, tostring(err)))
		end
	end)
end

connectRemote(RemoteNames.HUDUpdate, function(payload)
	applyHudPayload(payload)
end)

connectRemote(RemoteNames.DayTimerUpdate, function(payload)
	if type(payload) ~= "table" then
		return
	end
	timerLabel.Text = ("Sisa Waktu: %s"):format(formatClock(payload.timeRemainingSeconds))
end)

connectRemote(RemoteNames.DayPhaseUpdate, function(payload)
	if type(payload) ~= "table" then
		return
	end
	phaseLabel.Text = ("Phase: %s"):format(tostring(payload.label or payload.phase or "Pagi"))
	pushFeed(("Fase: %s"):format(tostring(payload.label or payload.phase or "?")), "info")
end)

connectRemote(RemoteNames.DayTransition, function(payload)
	if type(payload) ~= "table" then
		return
	end
	local dayNumber = payload.toDay or payload.day
	if dayNumber then
		dayLabel.Text = ("Day: %s"):format(tostring(dayNumber))
	end
	pushFeed(("Hari baru dimulai: %s"):format(tostring(dayNumber or "?")), "info")
end)

connectRemote(RemoteNames.EventFeed, function(payload)
	if type(payload) ~= "table" then
		pushFeed(payload, "info")
		return
	end
	pushFeed(payload.message or "Event update", payload.level or "info")
end)

connectRemote(RemoteNames.AnomalyWarning, function(payload)
	if type(payload) ~= "table" then
		pushFeed("Anomali terdeteksi", "warning")
		return
	end
	pushFeed(payload.message or "Anomali terdeteksi", payload.level or "warning")
end)

connectRemote(RemoteNames.FailTriggered, function(payload)
	local reason = type(payload) == "table" and payload.reason or "unknown"
	local message = ("Run kritis (%s). Gunakan Continue jika tersedia."):format(tostring(reason))
	pushFeed(message, "critical")
	showAlert("Kondisi kritis!", "critical")
end)

connectRemote(RemoteNames.ContinuePrompt, function(payload)
	local status = type(payload) == "table" and payload.status or "unknown"
	local priceRobux = type(payload) == "table" and math.max(0, math.floor(tonumber(payload.priceRobux) or 0)) or 0
	if status == "granted" then
		pushFeed("Continue berhasil, lanjutkan run.", "info")
		showAlert("Continue berhasil", "info")
	elseif status == "declined" then
		pushFeed("Continue ditolak, kembali ke lobby.", "warning")
		showAlert("Continue ditolak", "warning")
	elseif status == "prompted" then
		pushFeed(("Continue ditawarkan: %d Robux"):format(priceRobux), "warning")
		showAlert(("Continue %d Robux"):format(priceRobux), "warning")
	end
end)

connectRemote(RemoteNames.EndingTriggered, function(payload)
	if type(payload) ~= "table" then
		showAlert("Ending tercapai", "critical")
		pushFeed("Ending tercapai", "critical")
		return
	end
	local title = tostring(payload.title or payload.code or "Ending")
	showAlert(title, "critical")
	pushFeed(("Ending: %s"):format(title), "critical")
end)

pushFeed("HUD siap. Menunggu runtime update...", "info")
