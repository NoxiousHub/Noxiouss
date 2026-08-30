--// NoxiousHub
--// Stinger Server Hopper + Auto Hive + GUI + Webhook + Persistent Data

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- CONFIG
--==================================================

local DISCORD_INVITE = "https://discord.gg/xAsXmn9SQ"

local SAVE_FILE = "NoxiousHub_Data.json"

local STINGER_NAME = "Vicious"

local WAIT_BEFORE_GOING_UP = 3
local HEIGHT = 10

-- NEW:
local SERVER_HOP_DELAY = 10

--==================================================
-- SERVICES / OBJECTS
--==================================================

local Particles = workspace:WaitForChild("Particles")
local HivePlatforms = workspace:WaitForChild("HivePlatforms")

local ClaimHive = ReplicatedStorage
	:WaitForChild("Events")
	:WaitForChild("ClaimHive")

--==================================================
-- DATA
--==================================================

local sessionRuntime = 0
local totalRuntime = 0
local stingers = 0

-- NEW:
local savedWebhook = ""

--==================================================
-- TIME FORMAT
--==================================================

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60

	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

--==================================================
-- LOAD SAVED DATA
--==================================================

local function loadData()
	if not (isfile and readfile) then
		warn("[NoxiousHub] File functions unavailable.")
		return
	end

	if not isfile(SAVE_FILE) then
		return
	end

	local success, result = pcall(function()
		return HttpService:JSONDecode(
			readfile(SAVE_FILE)
		)
	end)

	if success and type(result) == "table" then

		totalRuntime =
			tonumber(result.totalRuntime) or 0

		stingers =
			tonumber(result.stingers) or 0

		savedWebhook =
			tostring(result.webhook or "")

		print("[NoxiousHub] Saved data loaded.")
	end
end

--==================================================
-- SAVE DATA
--==================================================

local function saveData()
	if not writefile then
		return
	end

	local data = {
		totalRuntime = totalRuntime,
		stingers = stingers,

		-- NEW:
		webhook = savedWebhook
	}

	pcall(function()
		writefile(
			SAVE_FILE,
			HttpService:JSONEncode(data)
		)
	end)
end

loadData()

--==================================================
-- REMOVE OLD GUI
--==================================================

pcall(function()
	local old =
		game:GetService("CoreGui")
			:FindFirstChild("NoxiousHub")

	if old then
		old:Destroy()
	end
end)

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "NoxiousHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
	gui.Parent = game:GetService("CoreGui")
end)

if not gui.Parent then
	gui.Parent =
		LocalPlayer:WaitForChild("PlayerGui")
end

--==================================================
-- MAIN
--==================================================

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 330, 0, 300)
main.Position = UDim2.new(0, 15, 0, 15)
main.BackgroundColor3 =
	Color3.fromRGB(17, 17, 23)
main.BorderSizePixel = 0
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color =
	Color3.fromRGB(168, 85, 247)
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.2
mainStroke.Parent = main

--==================================================
-- TITLE
--==================================================

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 0, 38)
title.Position = UDim2.new(0, 15, 0, 8)
title.BackgroundTransparency = 1
title.Text = "NoxiousHub"
title.TextColor3 =
	Color3.fromRGB(207, 150, 255)
title.TextSize = 23
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -30, 0, 18)
subtitle.Position = UDim2.new(0, 15, 0, 36)
subtitle.BackgroundTransparency = 1
subtitle.Text = "stinger automation"
subtitle.TextColor3 =
	Color3.fromRGB(115, 110, 125)
subtitle.TextSize = 11
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = main

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -30, 0, 1)
divider.Position = UDim2.new(0, 15, 0, 60)
divider.BackgroundColor3 =
	Color3.fromRGB(55, 55, 65)
divider.BorderSizePixel = 0
divider.Parent = main

--==================================================
-- WEBHOOK LABEL
--==================================================

local webhookLabel = Instance.new("TextLabel")
webhookLabel.Size = UDim2.new(1, -30, 0, 20)
webhookLabel.Position = UDim2.new(0, 15, 0, 70)
webhookLabel.BackgroundTransparency = 1
webhookLabel.Text = "Webhook"
webhookLabel.TextColor3 =
	Color3.fromRGB(220, 215, 225)
webhookLabel.TextSize = 13
webhookLabel.Font = Enum.Font.GothamBold
webhookLabel.TextXAlignment =
	Enum.TextXAlignment.Left
webhookLabel.Parent = main

--==================================================
-- WEBHOOK BOX
--==================================================

local webhookBox = Instance.new("TextBox")
webhookBox.Name = "WebhookBox"
webhookBox.Size = UDim2.new(1, -30, 0, 38)
webhookBox.Position = UDim2.new(0, 15, 0, 93)
webhookBox.BackgroundColor3 =
	Color3.fromRGB(27, 27, 35)
webhookBox.BorderSizePixel = 0
webhookBox.PlaceholderText =
	"Paste webhook here..."
webhookBox.PlaceholderColor3 =
	Color3.fromRGB(105, 105, 115)

-- NEW:
-- Loads the saved webhook automatically.
webhookBox.Text = savedWebhook

webhookBox.TextColor3 =
	Color3.fromRGB(225, 225, 230)
webhookBox.TextSize = 12
webhookBox.Font = Enum.Font.Gotham
webhookBox.ClearTextOnFocus = false
webhookBox.TextXAlignment =
	Enum.TextXAlignment.Left
webhookBox.Parent = main

local webhookCorner = Instance.new("UICorner")
webhookCorner.CornerRadius = UDim.new(0, 7)
webhookCorner.Parent = webhookBox

local webhookPadding = Instance.new("UIPadding")
webhookPadding.PaddingLeft = UDim.new(0, 10)
webhookPadding.PaddingRight = UDim.new(0, 10)
webhookPadding.Parent = webhookBox

--==================================================
-- AUTO-SAVE WEBHOOK
--==================================================

webhookBox.FocusLost:Connect(function()
	savedWebhook = webhookBox.Text

	saveData()

	print("[NoxiousHub] Webhook saved.")
end)

--==================================================
-- STATUS
--==================================================

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -30, 0, 18)
status.Position = UDim2.new(0, 15, 0, 135)
status.BackgroundTransparency = 1
status.Text = "Status: Starting..."
status.TextColor3 =
	Color3.fromRGB(130, 130, 140)
status.TextSize = 11
status.Font = Enum.Font.GothamMedium
status.TextXAlignment =
	Enum.TextXAlignment.Left
status.Parent = main

local function setStatus(text, color)
	status.Text = "Status: " .. text

	if color then
		status.TextColor3 = color
	end
end

--==================================================
-- STATS
--==================================================

local function createStat(text, y)
	local label = Instance.new("TextLabel")

	label.Size = UDim2.new(1, -30, 0, 23)
	label.Position = UDim2.new(0, 15, 0, y)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 =
		Color3.fromRGB(205, 205, 215)
	label.TextSize = 13
	label.Font = Enum.Font.GothamMedium
	label.TextXAlignment =
		Enum.TextXAlignment.Left
	label.Parent = main

	return label
end

local runtimeLabel = createStat(
	"Runtime                 00:00:00",
	158
)

local totalRuntimeLabel = createStat(
	"Total Runtime       00:00:00",
	182
)

local stingerLabel = createStat(
	"Stingers Gotten             0",
	206
)

--==================================================
-- BUTTONS
--==================================================

local testButton = Instance.new("TextButton")
testButton.Name = "Test"
testButton.Size = UDim2.new(0, 140, 0, 40)
testButton.Position = UDim2.new(0, 15, 1, -52)
testButton.BackgroundColor3 =
	Color3.fromRGB(168, 85, 247)
testButton.BorderSizePixel = 0
testButton.Text = "TEST"
testButton.TextColor3 =
	Color3.fromRGB(255, 255, 255)
testButton.TextSize = 13
testButton.Font = Enum.Font.GothamBold
testButton.Parent = main

local testCorner = Instance.new("UICorner")
testCorner.CornerRadius = UDim.new(0, 8)
testCorner.Parent = testButton

local discordButton = Instance.new("TextButton")
discordButton.Name = "Discord"
discordButton.Size = UDim2.new(0, 140, 0, 40)
discordButton.Position =
	UDim2.new(1, -155, 1, -52)
discordButton.BackgroundColor3 =
	Color3.fromRGB(42, 42, 52)
discordButton.BorderSizePixel = 0
discordButton.Text = "DISCORD"
discordButton.TextColor3 =
	Color3.fromRGB(225, 225, 230)
discordButton.TextSize = 13
discordButton.Font = Enum.Font.GothamBold
discordButton.Parent = main

local discordCorner = Instance.new("UICorner")
discordCorner.CornerRadius = UDim.new(0, 8)
discordCorner.Parent = discordButton

--==================================================
-- DRAGGING
--==================================================

local dragging = false
local dragStart
local startPos

title.InputBegan:Connect(function(input)
	if input.UserInputType ==
		Enum.UserInputType.MouseButton1
		or input.UserInputType ==
			Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then
		return
	end

	if input.UserInputType ==
		Enum.UserInputType.MouseMovement
		or input.UserInputType ==
			Enum.UserInputType.Touch then

		local delta =
			input.Position - dragStart

		main.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ==
		Enum.UserInputType.MouseButton1
		or input.UserInputType ==
			Enum.UserInputType.Touch then

		dragging = false
	end
end)

--==================================================
-- WEBHOOK REQUEST
--==================================================

local function getRequestFunction()
	return http_request
		or request
		or (syn and syn.request)
		or (http and http.request)
end

local function sendWebhook()
	local webhook = webhookBox.Text

	if webhook == "" then
		return false, "Paste a webhook first."
	end

	-- Save immediately whenever webhook is used.
	savedWebhook = webhook
	saveData()

	local req = getRequestFunction()

	if not req then
		return false,
			"No HTTP request function available."
	end

	local gameName = "Unknown"

	pcall(function()
		gameName =
			MarketplaceService
				:GetProductInfo(game.PlaceId).Name
	end)

	local payload = {
		username = "NoxiousHub",

		embeds = {{
			title = "🟣 NoxiousHub Test",
			description =
				"Webhook connection successful.",
			color = 0xA855F7,

			fields = {
				{
					name = "Player",
					value = LocalPlayer.Name,
					inline = true
				},

				{
					name = "Game",
					value = gameName,
					inline = true
				},

				{
					name = "Runtime",
					value = formatTime(
						sessionRuntime
					),
					inline = true
				},

				{
					name = "Total Runtime",
					value = formatTime(
						totalRuntime
					),
					inline = true
				},

				{
					name = "Stingers",
					value = tostring(stingers),
					inline = true
				}
			},

			footer = {
				text = "NoxiousHub"
			}
		}}
	}

	local success, result = pcall(function()
		return req({
			Url = webhook,
			Method = "POST",

			Headers = {
				["Content-Type"] =
					"application/json"
			},

			Body =
				HttpService:JSONEncode(payload)
		})
	end)

	if not success then
		return false, tostring(result)
	end

	return true
end

--==================================================
-- TEST BUTTON
--==================================================

testButton.MouseButton1Click:Connect(function()
	testButton.Text = "SENDING..."

	setStatus(
		"Sending webhook...",
		Color3.fromRGB(255, 200, 80)
	)

	local success, err = sendWebhook()

	if success then
		testButton.Text = "SENT!"

		setStatus(
			"Webhook sent successfully.",
			Color3.fromRGB(80, 220, 130)
		)
	else
		testButton.Text = "FAILED"

		setStatus(
			tostring(err),
			Color3.fromRGB(255, 90, 90)
		)

		warn(
			"[NoxiousHub] Webhook:",
			err
		)
	end

	task.wait(1.5)

	testButton.Text = "TEST"

	if success then
		setStatus(
			"Running...",
			Color3.fromRGB(130, 130, 140)
		)
	end
end)

--==================================================
-- DISCORD BUTTON
--==================================================

discordButton.MouseButton1Click:Connect(function()
	if setclipboard then
		setclipboard(DISCORD_INVITE)

		discordButton.Text = "COPIED!"
		discordButton.BackgroundColor3 =
			Color3.fromRGB(55, 170, 90)

		task.wait(1.5)

		discordButton.Text = "DISCORD"
		discordButton.BackgroundColor3 =
			Color3.fromRGB(42, 42, 52)
	else
		discordButton.Text = "UNSUPPORTED"

		task.wait(1.5)

		discordButton.Text = "DISCORD"
	end
end)

--==================================================
-- CHARACTER
--==================================================

local function getCharacter()
	return LocalPlayer.Character
		or LocalPlayer.CharacterAdded:Wait()
end

--==================================================
-- STINGER CFRAME
--==================================================

local function getStingerCFrame(stinger)
	if not stinger then
		return nil
	end

	if stinger:IsA("BasePart") then
		return stinger.CFrame
	end

	if stinger:IsA("Model") then
		return stinger:GetPivot()
	end

	local part =
		stinger:FindFirstChildWhichIsA(
			"BasePart",
			true
		)

	if part then
		return part.CFrame
	end

	return nil
end

--==================================================
-- CLAIM HIVE
--==================================================

local function claimHive()
	for _, platform in ipairs(
		HivePlatforms:GetChildren()
	) do

		local playerRef =
			platform:FindFirstChild("PlayerRef")

		if playerRef
			and playerRef.Value == nil then

			local hiveValue =
				platform:FindFirstChild("Hive")

			if hiveValue
				and hiveValue.Value then

				local hiveID =
					hiveValue.Value
						:FindFirstChild("HiveID")

				if hiveID then
					ClaimHive:FireServer(
						hiveID.Value
					)

					print(
						"🐝 Claimed hive: "
						.. hiveValue.Value.Name
					)

					return true
				end
			end
		end
	end

	warn("❌ No available hive found")

	return false
end

--==================================================
-- SERVER HOP DELAY
--==================================================

local hopping = false

local function serverHop()
	if hopping then
		return
	end

	hopping = true

	--==============================================
	-- WAIT 10 SECONDS BEFORE SERVER HOP
	--==============================================

	for i = SERVER_HOP_DELAY, 1, -1 do

		if not gui.Parent then
			return
		end

		setStatus(
			"Server hopping in "
			.. tostring(i)
			.. "s...",
			Color3.fromRGB(255, 190, 80)
		)

		task.wait(1)
	end

	print("🌎 Server hopping...")

	setStatus(
		"Finding new server...",
		Color3.fromRGB(255, 190, 80)
	)

	local placeId = game.PlaceId

	local success, response = pcall(function()
		return game:HttpGet(
			"https://games.roblox.com/v1/games/"
				.. placeId
				.. "/servers/Public?sortOrder=Asc&limit=100"
		)
	end)

	if not success then
		warn(
			"❌ Failed to get server list"
		)

		hopping = false

		return
	end

	local success2, data = pcall(function()
		return HttpService:JSONDecode(response)
	end)

	if not success2
		or not data
		or not data.data then

		warn(
			"❌ Failed to decode server list"
		)

		hopping = false

		return
	end

	for _, server in ipairs(data.data) do

		if server.id ~= game.JobId
			and server.playing < server.maxPlayers then

			print(
				"🚀 Joining server: "
				.. server.id
			)

			local teleported = pcall(function()
				TeleportService:
					TeleportToPlaceInstance(
						placeId,
						server.id,
						LocalPlayer
					)
			end)

			if teleported then
				return
			end
		end
	end

	warn(
		"❌ No available server found"
	)

	hopping = false
end

--==================================================
-- STINGER AUTOMATION
--==================================================

local function processStinger(stinger)

	if not stinger
		or not stinger.Parent then

		return
	end

	print("🐝 STINGER FOUND!")

	setStatus(
		"Stinger found!",
		Color3.fromRGB(80, 220, 130)
	)

	--==============================================
	-- CLAIM HIVE
	--==============================================

	setStatus(
		"Claiming hive...",
		Color3.fromRGB(255, 200, 80)
	)

	claimHive()

	task.wait(0.5)

	--==============================================
	-- GET STINGER POSITION
	--==============================================

	local cf =
		getStingerCFrame(stinger)

	if not cf then

		warn(
			"❌ Couldn't get Stinger position"
		)

		serverHop()

		return
	end

	--==============================================
	-- TELEPORT
	--==============================================

	local character = getCharacter()

	character:PivotTo(cf)

	print(
		"🐝 Teleported to Stinger!"
	)

	setStatus(
		"At Stinger - waiting 3 seconds...",
		Color3.fromRGB(80, 200, 255)
	)

	--==============================================
	-- WAIT 3 SECONDS
	--==============================================

	task.wait(
		WAIT_BEFORE_GOING_UP
	)

	--==============================================
	-- CHECK STINGER
	--==============================================

	if not stinger.Parent then

		print(
			"❌ Stinger disappeared during wait"
		)

		setStatus(
			"Stinger disappeared!",
			Color3.fromRGB(255, 100, 100)
		)

		serverHop()

		return
	end

	--==============================================
	-- MOVE 10 STUDS UP
	--==============================================

	character = getCharacter()

	character:PivotTo(
		character:GetPivot()
			+ Vector3.new(0, HEIGHT, 0)
	)

	print(
		"⬆️ Moved 10 studs upward"
	)

	setStatus(
		"Waiting for Stinger...",
		Color3.fromRGB(80, 220, 130)
	)

	--==============================================
	-- WAIT FOR STINGER TO DISAPPEAR
	--==============================================

	while stinger.Parent do
		task.wait(0.2)
	end

	print(
		"❌ STINGER DISAPPEARED!"
	)

	setStatus(
		"Stinger gone!",
		Color3.fromRGB(255, 100, 100)
	)

	--==============================================
	-- SERVER HOP
	--==============================================

	serverHop()
end

--==================================================
-- INITIAL STINGER CHECK
--==================================================

task.spawn(function()

	task.wait(1)

	local stinger =
		Particles:FindFirstChild(
			STINGER_NAME
		)

	if stinger then

		processStinger(stinger)

	else

		print(
			"❌ No Stinger found"
		)

		setStatus(
			"No Stinger found!",
			Color3.fromRGB(255, 100, 100)
		)

		-- Server hop waits 10 seconds.
		serverHop()
	end
end)

--==================================================
-- STINGER COUNTER
--==================================================

local lastStingerValue = nil

task.spawn(function()

	while gui.Parent do

		task.wait(1)

		local leaderstats =
			LocalPlayer:FindFirstChild(
				"leaderstats"
			)

		if leaderstats then

			local value =
				leaderstats:FindFirstChild(
					"Stingers"
				)

			if value
				and (
					value:IsA("IntValue")
					or value:IsA("NumberValue")
				) then

				local current =
					tonumber(value.Value) or 0

				if lastStingerValue == nil then

					lastStingerValue =
						current

				elseif current >
					lastStingerValue then

					local difference =
						current
						- lastStingerValue

					stingers += difference

					lastStingerValue =
						current

					saveData()

				elseif current <
					lastStingerValue then

					lastStingerValue =
						current
				end
			end
		end

		stingerLabel.Text =
			"Stingers Gotten             "
			.. tostring(stingers)
	end
end)

--==================================================
-- RUNTIME
--==================================================

task.spawn(function()

	while gui.Parent do

		task.wait(1)

		sessionRuntime += 1
		totalRuntime += 1

		runtimeLabel.Text =
			"Runtime                 "
			.. formatTime(
				sessionRuntime
			)

		totalRuntimeLabel.Text =
			"Total Runtime       "
			.. formatTime(
				totalRuntime
			)

		-- Save every 30 seconds.
		if sessionRuntime % 30 == 0 then
			saveData()
		end
	end
end)

--==================================================
-- INITIAL SAVE
--==================================================

saveData()

print("====================================")
print("🟣 NoxiousHub Loaded")
print("🐝 Stinger automation enabled")
print("🏠 Auto hive claim enabled")
print("🌎 Server hop delay: 10 seconds")
print("💾 Persistent data enabled")
print("====================================")
