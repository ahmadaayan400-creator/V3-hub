--// AAYAN V3 - FULL SCRIPT
--// Premium GUI + aura + sound system + customizer + INFO tab
--// ROBLOX LOCAL SCRIPT

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TextChatService = game:GetService("TextChatService")
local StatsService = game:GetService("Stats")
local SoundService = game:GetService("SoundService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS YOU MAY WANT TO CHANGE
--==================================================

local SONG_ASSET_FILE = "ll_song7_5.mp3" -- created by aayan when Luz Roja is played once
-- Gap between every element. Roblox offsets are whole pixels,
-- so the requested 0.9 gap is rounded to 1 pixel.
local GAP = 1

--==================================================
-- CHARACTER HELPERS
--==================================================

local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

local function getRoot()
	local character = getCharacter()
	return character:FindFirstChild("HumanoidRootPart")
end

local function getHum()
	local character = getCharacter()
	return character:FindFirstChildOfClass("Humanoid")
end

--==================================================
-- CONFIG
--==================================================

local Config = {
	AntiVoid = false,
	AntiFling = false,
	AntiSit = false,
	Spd = false,
	Spin = false,
	InfJump = false,
	CurrentTroll = nil
}

--==================================================
-- THEME + REGISTRY (everything the customizer can change)
--==================================================

local Defaults = {
	A1 = Color3.fromRGB(0, 200, 255),
	A2 = Color3.fromRGB(160, 60, 255),
	Scale = 1,
	Opacity = 0.1,
	AuraPower = 0.75,
	Aura = true,
	Particles = true,
	Rainbow = false,
	Spin = true,
	Round = 1,
	FontIndex = 1,
	Volume = 0.6
}

local Theme = {}
for k, v in pairs(Defaults) do
	Theme[k] = v
end
Theme.Text = Color3.fromRGB(245, 247, 255)
Theme.Muted = Color3.fromRGB(160, 165, 205)

-- 40 valid Roblox fonts (names resolved safely, invalid ones are skipped)
local FontList = {
	{"GothamBold","GOTHAM"},{"FredokaOne","FREDOKA"},{"SciFi","SCI-FI"},{"Arcade","ARCADE"},{"Code","CODE"},
	{"Bangers","BANGERS"},{"LuckiestGuy","LUCKY GUY"},{"PermanentMarker","MARKER"},{"Creepster","CREEPSTER"},{"Michroma","MICHROMA"},
	{"Oswald","OSWALD"},{"Jura","JURA"},{"Sarpanch","SARPANCH"},{"SpecialElite","TYPEWRITER"},{"Ubuntu","UBUNTU"},
	{"DenkOne","DENK ONE"},{"Fondamento","FONDAMENTO"},{"Kalam","KALAM"},{"PatrickHand","PATRICK"},{"GothamBlack","GOTHAM BLACK"},
	{"AmaticSC","AMATIC"},{"IndieFlower","INDIE FLOWER"},{"JosefinSans","JOSEFIN"},{"Merriweather","MERRIWEATHER"},{"Nunito","NUNITO"},
	{"Roboto","ROBOTO"},{"RobotoCondensed","ROBOTO COND"},{"RobotoMono","ROBOTO MONO"},{"TitilliumWeb","TITILLIUM"},{"Balthazar","BALTHAZAR"},
	{"GrenzeGotisch","GOTHIC"},{"Highway","HIGHWAY"},{"Cartoon","CARTOON"},{"Fantasy","FANTASY"},{"Antique","ANTIQUE"},
	{"Garamond","GARAMOND"},{"Bodoni","BODONI"},{"GothamMedium","GOTHAM MED"},{"SourceSansBold","SOURCE SANS"},{"Arial","ARIAL"}
}
local Fonts, FontNames = {}, {}
for _, f in ipairs(FontList) do
	local ok, font = pcall(function() return Enum.Font[f[1]] end)
	if ok and font then
		table.insert(Fonts, font)
		table.insert(FontNames, f[2])
	end
end

local Reg = {
	grads = {},
	buttons = {},
	tabs = {},
	corners = {},
	texts = {},
	fields = {},
	cards = {},
	accentFns = {},
	lookFns = {}
}

local Hooks = {} -- per-frame effects run by one single driver loop
local activeTab = nil
local mainOpen = false
local mainTweens = {}

local function mixColor()
	return Theme.A1:Lerp(Theme.A2, 0.5)
end

local function shade(f)
	return mixColor():Lerp(Color3.new(0, 0, 0), 1 - f)
end

local function refreshShadeCache()
	Theme._n = shade(0.22)
	Theme._h = shade(0.36)
	Theme._a = shade(0.55)
	Theme._field = shade(0.14)
	Theme._card = shade(0.10)
end
refreshShadeCache()

-- ===== SAVED CUSTOMIZER SETTINGS (auto-load on every execute) =====
do
	local HS = game:GetService("HttpService")
	local SAVE_FILE = "AAYAN_HUB_V3_SETTINGS.json"
	local function enc(c) return { c.R, c.G, c.B } end
	local function dec(t)
		if type(t) == "table" and tonumber(t[1]) and tonumber(t[2]) and tonumber(t[3]) then
			return Color3.new(math.clamp(t[1], 0, 1), math.clamp(t[2], 0, 1), math.clamp(t[3], 0, 1))
		end
	end
	Theme._saved = false
	Theme._save = function()
		if type(writefile) ~= "function" then return false end
		local ok = pcall(function()
			writefile(SAVE_FILE, HS:JSONEncode({
				A1 = enc(Theme.A1), A2 = enc(Theme.A2),
				Scale = Theme.Scale, Opacity = Theme.Opacity, AuraPower = Theme.AuraPower,
				Round = Theme.Round, Volume = Theme.Volume, FontIndex = Theme.FontIndex,
				Aura = Theme.Aura, Particles = Theme.Particles, Rainbow = Theme.Rainbow, Spin = Theme.Spin
			}))
		end)
		if ok then Theme._saved = true end
		return ok
	end
	Theme._clear = function()
		if type(isfile) ~= "function" or type(delfile) ~= "function" then return false end
		local ok = pcall(function() if isfile(SAVE_FILE) then delfile(SAVE_FILE) end end)
		if ok then Theme._saved = false end
		return ok
	end
	pcall(function()
		if type(isfile) == "function" and type(readfile) == "function" and isfile(SAVE_FILE) then
			local d = HS:JSONDecode(readfile(SAVE_FILE))
			if type(d) ~= "table" then return end
			local a1, a2 = dec(d.A1), dec(d.A2)
			if a1 and a2 then Theme.A1, Theme.A2 = a1, a2 end
			local ranges = { Scale = { 0.6, 1.3 }, Opacity = { 0, 1 }, AuraPower = { 0, 1 }, Round = { 0, 2 }, Volume = { 0, 1 } }
			for k, r in pairs(ranges) do
				if type(d[k]) == "number" then Theme[k] = math.clamp(d[k], r[1], r[2]) end
			end
			for _, k in ipairs({ "Aura", "Particles", "Rainbow", "Spin" }) do
				if type(d[k]) == "boolean" then Theme[k] = d[k] end
			end
			if type(d.FontIndex) == "number" and Fonts[d.FontIndex] then Theme.FontIndex = d.FontIndex end
			Theme._saved = true
			refreshShadeCache()
		end
	end)
end

local function addGradient(parent, c0, c1, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c0, c1)
	g.Rotation = rotation or 0
	g.Parent = parent
	return g
end

local function tween(obj, t, props, style, dir)
	local tw = TweenService:Create(
		obj,
		TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

-- Scale that keeps the GUI usable on small phone screens
local function viewScale()
	local cam = workspace.CurrentCamera
	if not cam then return 1 end
	local v = cam.ViewportSize
	return math.clamp(math.min(v.Y / 420, v.X / 440), 0.55, 1)
end

local function baseScale()
	return viewScale() * Theme.Scale
end

-- Border stroke with an accent gradient (stroke gradients never tint text)
local function borderStroke(parent, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1.5
	s.Transparency = transparency or 0
	s.Color = Color3.new(1, 1, 1)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	local g = addGradient(s, Theme.A1, Theme.A2, 0)
	table.insert(Reg.grads, g)
	return s, g
end

local function regCorner(inst, base)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, math.floor(base * Theme.Round + 0.5))
	c.Parent = inst
	table.insert(Reg.corners, { c = c, base = base })
	return c
end

--==================================================
-- CLEAN OLD COPIES (no duplicates on re-execute)
--==================================================

local old = PlayerGui:FindFirstChild("AAYAN_PAPA_SPECIAL")
if old then
	old:Destroy()
end

local oldMusic = SoundService:FindFirstChild("AAYAN_V4_MUSIC")
if oldMusic then
	oldMusic:Destroy()
end

local sg = Instance.new("ScreenGui")
sg.Name = "AAYAN_PAPA_SPECIAL"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = PlayerGui

-- connections / objects that must be cleaned when the GUI is destroyed
local Cleanup = {}
sg.Destroying:Connect(function()
	for _, c in ipairs(Cleanup) do
		pcall(function() c:Disconnect() end)
	end
	local leftoverBlur = Lighting:FindFirstChild("KINGS_V3_BLUR")
	if leftoverBlur then leftoverBlur:Destroy() end
end)

--==================================================
-- CLICK SOUND (plays on every button / tab / toggle click)
--==================================================

local CLICK_SOUND_ID = 421058925

local clickSound
do
	local oldClick = SoundService:FindFirstChild("AAYAN_CLICK")
	if oldClick then oldClick:Destroy() end

	clickSound = Instance.new("Sound")
	clickSound.Name = "AAYAN_CLICK"
	clickSound.SoundId = "rbxassetid://" .. tostring(CLICK_SOUND_ID)
	clickSound.Volume = 0.8
	clickSound.Parent = SoundService

	table.insert(Cleanup, {
		Disconnect = function()
			if clickSound then clickSound:Destroy() end
		end
	})
end

local function playClick()
	pcall(function()
		clickSound.TimePosition = 0
		clickSound:Play()
	end)
end

--==================================================
-- BOOT ANIMATION (storm + lightning, logo, loading bar, tap to skip)
--==================================================
do
	pcall(function()
		local old = PlayerGui:FindFirstChild("AAYAN_BOOT")
		if old then old:Destroy() end
		local boot = Instance.new("ScreenGui")
		boot.Name = "AAYAN_BOOT"
		boot.ResetOnSpawn = false
		boot.IgnoreGuiInset = true
		boot.DisplayOrder = 1000
		boot.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		boot.Parent = PlayerGui

		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(800, 400)
		local glow = Theme.A1:Lerp(Color3.fromRGB(255, 40, 60), 0.5)

		local bg = Instance.new("TextButton", boot)
		bg.Size = UDim2.new(1, 0, 1, 0)
		bg.BackgroundColor3 = Color3.new(1, 1, 1)
		bg.BorderSizePixel = 0
		bg.Text = ""
		bg.AutoButtonColor = false
		bg.ClipsDescendants = true
		bg.ZIndex = 1
		local bgGrad = Instance.new("UIGradient", bg)
		bgGrad.Rotation = 90
		bgGrad.Color = ColorSequence.new(Color3.fromRGB(34, 6, 14), Color3.fromRGB(4, 3, 9))
		local skipped, finished = false, false
		bg.MouseButton1Click:Connect(function() skipped = true end)

		-- rain
		local drops = {}
		for i = 1, 34 do
			local d = Instance.new("Frame", bg)
			d.Size = UDim2.fromOffset(1, math.random(14, 26))
			d.Position = UDim2.fromOffset(math.random(0, math.floor(vp.X)), math.random(0, math.floor(vp.Y)))
			d.BackgroundColor3 = Color3.fromRGB(190, 200, 255)
			d.BackgroundTransparency = 0.75
			d.BorderSizePixel = 0
			d.ZIndex = 2
			drops[i] = { f = d, v = math.random(520, 900) }
		end

		local bolts = Instance.new("Frame", bg)
		bolts.Size = UDim2.new(1, 0, 1, 0)
		bolts.BackgroundTransparency = 1
		bolts.ZIndex = 3

		local flash = Instance.new("Frame", bg)
		flash.Size = UDim2.new(1, 0, 1, 0)
		flash.BackgroundColor3 = Color3.fromRGB(235, 235, 255)
		flash.BackgroundTransparency = 1
		flash.BorderSizePixel = 0
		flash.ZIndex = 4

		-- dark edges (vignette)
		for _, v in ipairs({ { 0, 0, 90 }, { 1, 1, 90 } }) do
			local e = Instance.new("Frame", bg)
			e.AnchorPoint = Vector2.new(0, v[2])
			e.Position = UDim2.new(0, 0, v[1], 0)
			e.Size = UDim2.new(1, 0, 0, v[3])
			e.BackgroundColor3 = Color3.new(0, 0, 0)
			e.BorderSizePixel = 0
			e.ZIndex = 5
			Instance.new("UIGradient", e).Transparency = NumberSequence.new(v[2] == 0 and 0.15 or 1, v[2] == 0 and 1 or 0.15)
		end

		local box = Instance.new("Frame", bg)
		box.AnchorPoint = Vector2.new(0.5, 0.5)
		box.Position = UDim2.new(0.5, 0, 0.5, 0)
		box.Size = UDim2.new(0, 360, 0, 160)
		box.BackgroundTransparency = 1
		box.ZIndex = 6
		local bscale = Instance.new("UIScale", box)
		bscale.Scale = math.clamp(math.min(vp.X / 520, vp.Y / 300), 0.6, 1.3)

		local function red(parent, y)
			local l = Instance.new("Frame", parent)
			l.AnchorPoint = Vector2.new(0.5, 0)
			l.Position = UDim2.new(0.5, 0, 0, y)
			l.Size = UDim2.new(0, 300, 0, 2)
			l.BackgroundColor3 = Color3.new(1, 1, 1)
			l.BackgroundTransparency = 1
			l.BorderSizePixel = 0
			l.ZIndex = 7
			local g = Instance.new("UIGradient", l)
			g.Color = ColorSequence.new(Color3.fromRGB(255, 40, 60))
			g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) })
			return l
		end
		local lineTop, lineBot = red(box, 0), red(box, 150)

		local title = Instance.new("TextLabel", box)
		title.Position = UDim2.new(0, 0, 0, 12)
		title.Size = UDim2.new(1, 0, 0, 56)
		title.BackgroundTransparency = 1
		title.Text = "AAYAN HUB"
		title.TextColor3 = Color3.new(1, 1, 1)
		title.Font = Enum.Font.GothamBlack
		title.TextSize = 46
		title.TextTransparency = 1
		title.ZIndex = 7
		addGradient(title, Theme.A1, Theme.A2, 0)

		local sub = Instance.new("TextLabel", box)
		sub.Position = UDim2.new(0, 0, 0, 70)
		sub.Size = UDim2.new(1, 0, 0, 18)
		sub.BackgroundTransparency = 1
		sub.Text = "V3  |  PREMIUM EDITION"
		sub.TextColor3 = Color3.fromRGB(200, 170, 185)
		sub.Font = Enum.Font.GothamBold
		sub.TextSize = 12
		sub.TextTransparency = 1
		sub.ZIndex = 7

		local barBg = Instance.new("Frame", box)
		barBg.AnchorPoint = Vector2.new(0.5, 0)
		barBg.Position = UDim2.new(0.5, 0, 0, 108)
		barBg.Size = UDim2.new(0, 260, 0, 6)
		barBg.BackgroundColor3 = Color3.fromRGB(40, 20, 30)
		barBg.BackgroundTransparency = 1
		barBg.BorderSizePixel = 0
		barBg.ZIndex = 7
		Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)
		local fill = Instance.new("Frame", barBg)
		fill.Size = UDim2.new(0, 0, 1, 0)
		fill.BackgroundColor3 = Color3.new(1, 1, 1)
		fill.BackgroundTransparency = 1
		fill.BorderSizePixel = 0
		fill.ZIndex = 8
		Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
		addGradient(fill, Theme.A1, Theme.A2, 0)

		local stat = Instance.new("TextLabel", box)
		stat.Position = UDim2.new(0, 0, 0, 122)
		stat.Size = UDim2.new(1, 0, 0, 16)
		stat.BackgroundTransparency = 1
		stat.Text = ""
		stat.TextColor3 = Color3.fromRGB(255, 120, 130)
		stat.Font = Enum.Font.GothamBold
		stat.TextSize = 11
		stat.ZIndex = 7

		-- lightning
		local function seg(a, b, th, col, tr)
			local d = b - a
			local f = Instance.new("Frame")
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
			f.Size = UDim2.fromOffset(d.Magnitude + th * 0.5, th)
			f.Rotation = math.deg(math.atan2(d.Y, d.X))
			f.BackgroundColor3 = col
			f.BackgroundTransparency = tr
			f.BorderSizePixel = 0
			f.ZIndex = 3
			f.Parent = bolts
			return f
		end
		local function strike()
			local frames = {}
			local function line(list, th)
				for i = 1, #list - 1 do
					table.insert(frames, seg(list[i], list[i + 1], th * 3, glow, 0.7))
					table.insert(frames, seg(list[i], list[i + 1], th, Color3.new(1, 1, 1), 0))
				end
			end
			local x, y = vp.X * (0.1 + math.random() * 0.8), 0
			local endY = vp.Y * (0.55 + math.random() * 0.3)
			local pts = {}
			while y < endY do
				table.insert(pts, Vector2.new(x, y))
				y = y + 28 + math.random() * 34
				x = x + (math.random() - 0.5) * 90
			end
			line(pts, 3)
			local bi = math.random(2, math.max(2, #pts - 2))
			local bp, bx, by = { pts[bi] }, pts[bi].X, pts[bi].Y
			local dir = (math.random() < 0.5) and -1 or 1
			for _ = 1, 4 do
				bx = bx + dir * (20 + math.random() * 30)
				by = by + 18 + math.random() * 28
				table.insert(bp, Vector2.new(bx, by))
			end
			line(bp, 2)
			flash.BackgroundTransparency = 0.55
			tween(flash, 0.4, { BackgroundTransparency = 1 })
			task.spawn(function()
				for _ = 1, 6 do
					box.Position = UDim2.new(0.5, math.random(-6, 6), 0.5, math.random(-4, 4))
					task.wait(0.03)
				end
				box.Position = UDim2.new(0.5, 0, 0.5, 0)
			end)
			task.delay(0.12, function()
				for _, f in ipairs(frames) do tween(f, 0.28, { BackgroundTransparency = 1 }) end
			end)
			task.delay(0.5, function()
				for _, f in ipairs(frames) do f:Destroy() end
			end)
		end

		task.spawn(function()
			task.wait(0.15)
			while not finished and boot.Parent do
				strike()
				if math.random() < 0.35 then task.wait(0.09) strike() end
				task.wait(0.35 + math.random() * 0.5)
			end
		end)
		task.spawn(function()
			while not finished and boot.Parent do
				for _, d in ipairs(drops) do
					local p = d.f.Position
					local ny = p.Y.Offset + d.v * 0.033
					if ny > vp.Y then ny = -30 end
					d.f.Position = UDim2.fromOffset(p.X.Offset, ny)
				end
				task.wait(0.033)
			end
		end)

		tween(title, 0.6, { TextTransparency = 0 })
		tween(sub, 0.8, { TextTransparency = 0 })
		tween(barBg, 0.5, { BackgroundTransparency = 0 })
		tween(fill, 0.5, { BackgroundTransparency = 0 })
		tween(lineTop, 0.6, { BackgroundTransparency = 0 })
		tween(lineBot, 0.6, { BackgroundTransparency = 0 })
		tween(fill, 3.2, { Size = UDim2.new(1, 0, 1, 0) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

		local steps = { "Charging the core...", "Injecting power...", "Unleashing the storm...", "READY" }
		for i = 1, #steps do
			if skipped then break end
			stat.Text = steps[i]
			local t0 = os.clock()
			while os.clock() - t0 < 0.85 and not skipped do task.wait(0.03) end
		end

		finished = true
		tween(bg, 0.5, { BackgroundTransparency = 1 })
		for _, o in ipairs(bg:GetDescendants()) do
			if o:IsA("Frame") then tween(o, 0.4, { BackgroundTransparency = 1 }) end
			if o:IsA("TextLabel") then tween(o, 0.4, { TextTransparency = 1 }) end
		end
		task.wait(0.55)
		boot:Destroy()
	end)
end

local function hookButton(inst)
	if inst:IsA("GuiButton") and not inst:GetAttribute("ClickHooked") then
		inst:SetAttribute("ClickHooked", true)
		inst.MouseButton1Click:Connect(playClick)
	end
end

-- hooks every button that exists now or is created later under `root`
local function hookClicks(root)
	for _, d in ipairs(root:GetDescendants()) do
		hookButton(d)
	end
	root.DescendantAdded:Connect(hookButton)
end

hookClicks(sg)

--==================================================
-- DRAG FUNCTION (handle = optional part of the frame used to grab it)
--==================================================

local function makeDraggable(frame, handle)
	local dragging = false
	local dragStart
	local startPos

	;(handle or frame).InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	table.insert(Cleanup, UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end

		if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then

			local delta = input.Position - dragStart

			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end))
end

--==================================================
-- AVATAR THUMBNAIL (real avatar of the local player)
--==================================================

local avatarImage = ""
do
	local ok, img = pcall(function()
		return Players:GetUserThumbnailAsync(
			player.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size150x150
		)
	end)
	if ok and img and img ~= "" then
		avatarImage = img
	else
		avatarImage = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
	end
end

--==================================================
-- INTRO: NAME -> GANG -> TARGET (3 compact GUIs)
--==================================================

local playerName, gangName, targetName, playerGender, hasTarget

do
	local oldSetup = PlayerGui:FindFirstChild("KINGS_V3_SETUP")
	if oldSetup then oldSetup:Destroy() end
	local oldBlur = Lighting:FindFirstChild("KINGS_V3_BLUR")
	if oldBlur then oldBlur:Destroy() end

	local setupGui = Instance.new("ScreenGui")
	setupGui.Name = "KINGS_V3_SETUP"
	setupGui.ResetOnSpawn = false
	setupGui.IgnoreGuiInset = true
	setupGui.DisplayOrder = 500
	setupGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	setupGui.Parent = PlayerGui
	hookClicks(setupGui)

	local blur = Instance.new("BlurEffect")
	blur.Name = "KINGS_V3_BLUR"
	blur.Size = 0
	blur.Parent = Lighting

	setupGui.Destroying:Connect(function()
		if blur and blur.Parent then blur:Destroy() end
	end)

	local FIELD = Color3.fromRGB(22, 24, 54)
	local BORDER_IDLE = Color3.fromRGB(110, 80, 230)

	local function runStep(heading, subtitle, placeholder, iconText, buttonText)
		local result = nil
		local submitted = false
		local finished = Instance.new("BindableEvent")

		-- CanvasGroup is only used for fading. NO gradient on the group itself
		-- (a UIGradient on a CanvasGroup tints everything inside = black GUI).
		local card = Instance.new("CanvasGroup")
		card.AnchorPoint = Vector2.new(0.5, 0.5)
		card.Position = UDim2.new(0.5, 0, 0.5, 0)
		card.Size = UDim2.new(0, 290, 0, 244)
		card.BackgroundTransparency = 1
		card.BorderSizePixel = 0
		card.GroupTransparency = 1
		card.Parent = setupGui

		local scale = Instance.new("UIScale")
		scale.Scale = viewScale() * 0.85
		scale.Parent = card

		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 18)

		local _, cardStrokeGrad = borderStroke(card, 2.5, 0)

		local bg = Instance.new("Frame")
		bg.Name = "Bg"
		bg.Size = UDim2.new(1, 0, 1, 0)
		bg.BackgroundColor3 = Color3.new(1, 1, 1)
		bg.BackgroundTransparency = 0.06
		bg.BorderSizePixel = 0
		bg.ZIndex = 1
		bg.Parent = card
		addGradient(bg, Color3.fromRGB(20, 22, 56), Color3.fromRGB(10, 10, 28), 90)

		-- vertical column, every element 1px apart
		local col = Instance.new("Frame")
		col.Size = UDim2.new(1, 0, 1, 0)
		col.BackgroundTransparency = 1
		col.ZIndex = 2
		col.Parent = card

		local list = Instance.new("UIListLayout")
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = UDim.new(0, GAP)
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.Parent = col

		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 12)
		pad.Parent = col

		-- avatar
		local ringHolder = Instance.new("Frame")
		ringHolder.LayoutOrder = 1
		ringHolder.Size = UDim2.new(1, 0, 0, 72)
		ringHolder.BackgroundTransparency = 1
		ringHolder.ZIndex = 3
		ringHolder.Parent = col

		local ring = Instance.new("Frame")
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Position = UDim2.new(0.5, 0, 0.5, 0)
		ring.Size = UDim2.new(0, 66, 0, 66)
		ring.BackgroundColor3 = Color3.fromRGB(16, 30, 80)
		ring.BorderSizePixel = 0
		ring.ZIndex = 3
		ring.Parent = ringHolder
		Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
		local _, ringGrad = borderStroke(ring, 3, 0)

		local avatar = Instance.new("ImageLabel")
		avatar.AnchorPoint = Vector2.new(0.5, 0.5)
		avatar.Position = UDim2.new(0.5, 0, 0.5, 0)
		avatar.Size = UDim2.new(1, -10, 1, -10)
		avatar.BackgroundTransparency = 1
		avatar.Image = avatarImage
		avatar.ScaleType = Enum.ScaleType.Crop
		avatar.ZIndex = 4
		avatar.Parent = ring
		Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

		-- heading
		local head = Instance.new("TextLabel")
		head.LayoutOrder = 2
		head.Size = UDim2.new(1, -30, 0, 28)
		head.BackgroundTransparency = 1
		head.Text = heading
		head.TextColor3 = Color3.new(1, 1, 1)
		head.Font = Enum.Font.GothamBlack
		head.TextScaled = true
		head.ZIndex = 3
		head.Parent = col
		local headLimit = Instance.new("UITextSizeConstraint")
		headLimit.MaxTextSize = 22
		headLimit.MinTextSize = 11
		headLimit.Parent = head
		addGradient(head, Color3.fromRGB(80, 220, 255), Color3.fromRGB(240, 130, 255), 0)

		local sub = Instance.new("TextLabel")
		sub.LayoutOrder = 3
		sub.Size = UDim2.new(1, -30, 0, 18)
		sub.BackgroundTransparency = 1
		sub.Text = subtitle
		sub.TextColor3 = Theme.Muted
		sub.Font = Enum.Font.Gotham
		sub.TextSize = 12
		sub.ZIndex = 3
		sub.Parent = col

		-- small name box
		local field = Instance.new("Frame")
		field.LayoutOrder = 4
		field.Size = UDim2.new(1, -44, 0, 34)
		field.BackgroundColor3 = FIELD
		field.BorderSizePixel = 0
		field.ZIndex = 3
		field.Parent = col
		Instance.new("UICorner", field).CornerRadius = UDim.new(0, 10)
		local fieldStroke = Instance.new("UIStroke")
		fieldStroke.Thickness = 1.5
		fieldStroke.Color = BORDER_IDLE
		fieldStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		fieldStroke.Parent = field

		local icon = Instance.new("TextLabel")
		icon.Position = UDim2.new(0, 8, 0, 0)
		icon.Size = UDim2.new(0, 24, 1, 0)
		icon.BackgroundTransparency = 1
		icon.Text = iconText
		icon.TextSize = 16
		icon.TextColor3 = Theme.Muted
		icon.Font = Enum.Font.GothamBold
		icon.ZIndex = 4
		icon.Parent = field

		local box = Instance.new("TextBox")
		box.Position = UDim2.new(0, 36, 0, 0)
		box.Size = UDim2.new(1, -44, 1, 0)
		box.BackgroundTransparency = 1
		box.PlaceholderText = placeholder
		box.PlaceholderColor3 = Color3.fromRGB(150, 155, 195)
		box.Text = ""
		box.TextColor3 = Color3.new(1, 1, 1)
		box.Font = Enum.Font.GothamMedium
		box.TextSize = 14
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.ClearTextOnFocus = false
		box.ClipsDescendants = true
		box.ZIndex = 4
		box.Parent = field

		-- solid colour button (a gradient would tint its text); gradient is on the border
		local button = Instance.new("TextButton")
		button.LayoutOrder = 5
		button.Size = UDim2.new(1, -44, 0, 36)
		button.BackgroundColor3 = Color3.fromRGB(40, 100, 235)
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Text = buttonText .. "  →"
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.GothamBlack
		button.TextSize = 16
		button.ZIndex = 3
		button.Parent = col
		Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)
		borderStroke(button, 1.8, 0)

		local hint = Instance.new("TextLabel")
		hint.LayoutOrder = 6
		hint.Size = UDim2.new(1, -30, 0, 18)
		hint.BackgroundTransparency = 1
		hint.Text = "Press Enter to continue"
		hint.TextColor3 = Theme.Muted
		hint.Font = Enum.Font.Gotham
		hint.TextSize = 11
		hint.ZIndex = 3
		hint.Parent = col

		local close = Instance.new("TextButton")
		close.Position = UDim2.new(1, -34, 0, 8)
		close.Size = UDim2.new(0, 26, 0, 26)
		close.BackgroundColor3 = FIELD
		close.Text = "✕"
		close.TextColor3 = Color3.new(1, 1, 1)
		close.Font = Enum.Font.GothamBold
		close.TextSize = 13
		close.AutoButtonColor = false
		close.ZIndex = 6
		close.Parent = card
		Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)
		local closeStroke = Instance.new("UIStroke")
		closeStroke.Thickness = 1
		closeStroke.Color = Color3.fromRGB(100, 100, 170)
		closeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		closeStroke.Parent = close

		local alive = true
		task.spawn(function()
			local rot = 0
			while alive and card.Parent do
				rot = (rot + 2) % 360
				cardStrokeGrad.Rotation = rot
				ringGrad.Rotation = -rot
				task.wait(0.03)
			end
		end)

		button.MouseEnter:Connect(function()
			tween(button, 0.15, { BackgroundColor3 = Color3.fromRGB(70, 130, 255) })
		end)
		button.MouseLeave:Connect(function()
			tween(button, 0.15, { BackgroundColor3 = Color3.fromRGB(40, 100, 235) })
		end)
		button.MouseButton1Down:Connect(function()
			tween(button, 0.08, { BackgroundColor3 = Color3.fromRGB(110, 60, 220) })
		end)
		box.Focused:Connect(function()
			tween(fieldStroke, 0.2, { Color = Color3.fromRGB(0, 210, 255) })
		end)
		box.FocusLost:Connect(function()
			tween(fieldStroke, 0.2, { Color = BORDER_IDLE })
		end)

		tween(blur, 0.5, { Size = 14 })
		tween(card, 0.45, { GroupTransparency = 0 })
		tween(scale, 0.5, { Scale = viewScale() }, Enum.EasingStyle.Back)

		local function closeCard(value)
			if submitted then return end
			submitted = true
			result = value
			alive = false
			tween(card, 0.3, { GroupTransparency = 1 })
			local out = tween(scale, 0.3, { Scale = viewScale() * 0.9 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			out.Completed:Wait()
			card:Destroy()
			finished:Fire()
		end

		local function shake()
			local origin = box.Position
			for _, dx in ipairs({ 8, -8, 5, -5, 0 }) do
				box.Position = origin + UDim2.new(0, dx, 0, 0)
				task.wait(0.03)
			end
			box.Position = origin
		end

		local function trySubmit()
			if submitted then return end
			local text = box.Text:gsub("^%s+", ""):gsub("%s+$", "")
			if text == "" then
				tween(fieldStroke, 0.1, { Color = Color3.fromRGB(255, 80, 100) })
				task.spawn(shake)
				box.PlaceholderText = "This field can't be empty"
				task.delay(0.8, function()
					if not submitted then
						tween(fieldStroke, 0.2, { Color = BORDER_IDLE })
						box.PlaceholderText = placeholder
					end
				end)
				return
			end
			task.spawn(closeCard, text)
		end

		button.Activated:Connect(trySubmit)
		box.FocusLost:Connect(function(enterPressed)
			if enterPressed then trySubmit() end
		end)
		close.Activated:Connect(function()
			task.spawn(closeCard, nil)
		end)

		finished.Event:Wait()
		finished:Destroy()
		return result
	end


	-- two-choice card (BOY/GIRL first, later YES/NO for the target question)
	local function runChoice(headText, subText, hintText, aText, aKey, aBase, aHover, bText, bKey, bBase, bHover)
		local result = nil
		local submitted = false
		local finished = Instance.new("BindableEvent")

		local card = Instance.new("CanvasGroup")
		card.AnchorPoint = Vector2.new(0.5, 0.5)
		card.Position = UDim2.new(0.5, 0, 0.5, 0)
		card.Size = UDim2.new(0, 290, 0, 232)
		card.BackgroundTransparency = 1
		card.BorderSizePixel = 0
		card.GroupTransparency = 1
		card.Parent = setupGui

		local scale = Instance.new("UIScale")
		scale.Scale = viewScale() * 0.85
		scale.Parent = card

		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 18)
		local _, cardStrokeGrad = borderStroke(card, 2.5, 0)

		local bg = Instance.new("Frame")
		bg.Size = UDim2.new(1, 0, 1, 0)
		bg.BackgroundColor3 = Color3.new(1, 1, 1)
		bg.BackgroundTransparency = 0.06
		bg.BorderSizePixel = 0
		bg.ZIndex = 1
		bg.Parent = card
		addGradient(bg, Color3.fromRGB(20, 22, 56), Color3.fromRGB(10, 10, 28), 90)

		local col = Instance.new("Frame")
		col.Size = UDim2.new(1, 0, 1, 0)
		col.BackgroundTransparency = 1
		col.ZIndex = 2
		col.Parent = card

		local list = Instance.new("UIListLayout")
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = UDim.new(0, GAP)
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.Parent = col

		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 12)
		pad.Parent = col

		local ringHolder = Instance.new("Frame")
		ringHolder.LayoutOrder = 1
		ringHolder.Size = UDim2.new(1, 0, 0, 72)
		ringHolder.BackgroundTransparency = 1
		ringHolder.ZIndex = 3
		ringHolder.Parent = col

		local ring = Instance.new("Frame")
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Position = UDim2.new(0.5, 0, 0.5, 0)
		ring.Size = UDim2.new(0, 66, 0, 66)
		ring.BackgroundColor3 = Color3.fromRGB(16, 30, 80)
		ring.BorderSizePixel = 0
		ring.ZIndex = 3
		ring.Parent = ringHolder
		Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
		local _, ringGrad = borderStroke(ring, 3, 0)

		local avatar = Instance.new("ImageLabel")
		avatar.AnchorPoint = Vector2.new(0.5, 0.5)
		avatar.Position = UDim2.new(0.5, 0, 0.5, 0)
		avatar.Size = UDim2.new(1, -10, 1, -10)
		avatar.BackgroundTransparency = 1
		avatar.Image = avatarImage
		avatar.ScaleType = Enum.ScaleType.Crop
		avatar.ZIndex = 4
		avatar.Parent = ring
		Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

		local head = Instance.new("TextLabel")
		head.LayoutOrder = 2
		head.Size = UDim2.new(1, -30, 0, 28)
		head.BackgroundTransparency = 1
		head.Text = headText
		head.TextColor3 = Color3.new(1, 1, 1)
		head.Font = Enum.Font.GothamBlack
		head.TextScaled = true
		head.ZIndex = 3
		head.Parent = col
		local headLimit = Instance.new("UITextSizeConstraint")
		headLimit.MaxTextSize = 22
		headLimit.MinTextSize = 11
		headLimit.Parent = head
		addGradient(head, Color3.fromRGB(80, 220, 255), Color3.fromRGB(240, 130, 255), 0)

		local sub = Instance.new("TextLabel")
		sub.LayoutOrder = 3
		sub.Size = UDim2.new(1, -30, 0, 18)
		sub.BackgroundTransparency = 1
		sub.Text = subText
		sub.TextColor3 = Theme.Muted
		sub.Font = Enum.Font.Gotham
		sub.TextSize = 12
		sub.ZIndex = 3
		sub.Parent = col

		local row = Instance.new("Frame")
		row.LayoutOrder = 4
		row.Size = UDim2.new(1, -36, 0, 76)
		row.BackgroundTransparency = 1
		row.ZIndex = 3
		row.Parent = col
		local rowList = Instance.new("UIListLayout")
		rowList.FillDirection = Enum.FillDirection.Horizontal
		rowList.Padding = UDim.new(0, 8)
		rowList.HorizontalAlignment = Enum.HorizontalAlignment.Center
		rowList.VerticalAlignment = Enum.VerticalAlignment.Center
		rowList.Parent = row

		local hint = Instance.new("TextLabel")
		hint.LayoutOrder = 5
		hint.Size = UDim2.new(1, -30, 0, 18)
		hint.BackgroundTransparency = 1
		hint.Text = hintText
		hint.TextColor3 = Theme.Muted
		hint.Font = Enum.Font.Gotham
		hint.TextSize = 11
		hint.ZIndex = 3
		hint.Parent = col

		local close = Instance.new("TextButton")
		close.Position = UDim2.new(1, -34, 0, 8)
		close.Size = UDim2.new(0, 26, 0, 26)
		close.BackgroundColor3 = FIELD
		close.Text = "✕"
		close.TextColor3 = Color3.new(1, 1, 1)
		close.Font = Enum.Font.GothamBold
		close.TextSize = 13
		close.AutoButtonColor = false
		close.ZIndex = 6
		close.Parent = card
		Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)
		local closeStroke = Instance.new("UIStroke")
		closeStroke.Thickness = 1
		closeStroke.Color = Color3.fromRGB(100, 100, 170)
		closeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		closeStroke.Parent = close

		local alive = true
		task.spawn(function()
			local rot = 0
			while alive and card.Parent do
				rot = (rot + 2) % 360
				cardStrokeGrad.Rotation = rot
				ringGrad.Rotation = -rot
				task.wait(0.03)
			end
		end)

		local function closeCard(value)
			if submitted then return end
			submitted = true
			result = value
			alive = false
			tween(card, 0.3, { GroupTransparency = 1 })
			local out = tween(scale, 0.3, { Scale = viewScale() * 0.9 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			out.Completed:Wait()
			card:Destroy()
			finished:Fire()
		end

		local function choice(text, key, base, hover)
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(0.5, -4, 1, 0)
			b.BackgroundColor3 = base
			b.BorderSizePixel = 0
			b.AutoButtonColor = false
			b.Text = text
			b.TextColor3 = Color3.new(1, 1, 1)
			b.Font = Enum.Font.GothamBlack
			b.TextSize = 20
			b.ZIndex = 3
			b.Parent = row
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
			borderStroke(b, 1.8, 0)
			b.MouseEnter:Connect(function() tween(b, 0.15, { BackgroundColor3 = hover }) end)
			b.MouseLeave:Connect(function() tween(b, 0.15, { BackgroundColor3 = base }) end)
			b.Activated:Connect(function() task.spawn(closeCard, key) end)
		end

		choice(aText, aKey, aBase, aHover)
		choice(bText, bKey, bBase, bHover)

		close.Activated:Connect(function()
			task.spawn(closeCard, nil)
		end)

		tween(blur, 0.5, { Size = 14 })
		tween(card, 0.45, { GroupTransparency = 0 })
		tween(scale, 0.5, { Scale = viewScale() }, Enum.EasingStyle.Back)

		finished.Event:Wait()
		finished:Destroy()
		return result
	end

	local function showStatus(text, good)
		local toast = Instance.new("CanvasGroup")
		toast.AnchorPoint = Vector2.new(0.5, 0)
		toast.Position = UDim2.new(0.5, 0, 0, -60)
		toast.Size = UDim2.new(0, 300, 0, 44)
		toast.BackgroundColor3 = Color3.fromRGB(14, 16, 38)
		toast.BorderSizePixel = 0
		toast.GroupTransparency = 1
		toast.Parent = setupGui
		Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 14)
		local s = Instance.new("UIStroke")
		s.Thickness = 2
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Color = good and Color3.fromRGB(0, 255, 170) or Color3.fromRGB(255, 170, 60)
		s.Parent = toast
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -16, 1, 0)
		l.Position = UDim2.new(0, 8, 0, 0)
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextColor3 = Color3.new(1, 1, 1)
		l.Font = Enum.Font.GothamBold
		l.TextSize = 13
		l.TextWrapped = true
		l.Parent = toast

		-- sits just under the sound bar
		tween(toast, 0.4, { Position = UDim2.new(0.5, 0, 0, 64), GroupTransparency = 0 }, Enum.EasingStyle.Back)
		task.delay(4, function()
			local out = tween(toast, 0.4, { Position = UDim2.new(0.5, 0, 0, -60), GroupTransparency = 1 })
			out.Completed:Wait()
			toast:Destroy()
			if setupGui and setupGui.Parent then
				setupGui:Destroy()
			end
		end)
	end

	local function getChannel()
		if TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
			return nil
		end
		local channels = TextChatService:FindFirstChild("TextChannels")
		if not channels then
			channels = TextChatService:WaitForChild("TextChannels", 5)
		end
		if not channels then return nil end
		return channels:FindFirstChild("RBXGeneral") or channels:WaitForChild("RBXGeneral", 5)
	end

	local function sendChat(channel, message)
		if not channel then return false end
		local ok, err = pcall(function()
			channel:SendAsync(message)
		end)
		if not ok then
			warn("[V4] Chat message failed: " .. tostring(err))
		end
		return ok
	end

	playerGender = runChoice("SELECT BOY OR GIRL", "Your intro message depends on this", "Tap one to continue",
		"♂  BOY", "boy", Color3.fromRGB(40, 100, 235), Color3.fromRGB(70, 135, 255),
		"♀  GIRL", "girl", Color3.fromRGB(205, 55, 145), Color3.fromRGB(240, 90, 180))
	if playerGender == "girl" then
		-- GIRL: pink (sakura) theme for the whole GUI; BOY keeps the default theme
		local pk1, pk2 = Color3.fromRGB(255, 120, 200), Color3.fromRGB(190, 90, 255)
		Defaults.A1, Defaults.A2 = pk1, pk2
		if not Theme._saved then -- a saved customizer theme always wins
			Theme.A1, Theme.A2 = pk1, pk2
			refreshShadeCache()
		end
	end
	if playerGender then
		playerName = runStep("ENTER YOUR NAME", "Your name will be used in the script", "Enter your name...", "👤", "ENTER")
	end
	if playerName then
		gangName = runStep("ENTER YOUR GANG NAME", "Your gang name will be used in the script", "Enter your gang name...", "👥", "ENTER")
	end
	if gangName then
		hasTarget = runChoice("DO YOU HAVE A TARGET?", "YES opens the target name box, NO skips it", "Tap one to continue",
			"YES", "yes", Color3.fromRGB(40, 150, 90), Color3.fromRGB(70, 190, 125),
			"NO", "no", Color3.fromRGB(170, 50, 70), Color3.fromRGB(210, 80, 100))
	end
	if hasTarget == "yes" then
		targetName = runStep("ENTER YOUR TARGET NAME", "Type the name you want to mention", "Enter target name...", "🎯", "ENTER")
	end

	local blurOut = tween(blur, 0.5, { Size = 0 })
	blurOut.Completed:Connect(function()
		if blur and blur.Parent then blur:Destroy() end
	end)

	if not (playerName and gangName and hasTarget and (hasTarget == "no" or targetName)) then
		-- setup was closed: stop the script cleanly
		task.delay(0.6, function()
			setupGui:Destroy()
			sg:Destroy()
		end)
		return
	end

	local channel = getChannel()

	-- chat allows 200 characters: the run of @ is shortened only if a very long name needs the room
	local function build(prefix, suffix)
		local free = 200 - (utf8.len(prefix) or #prefix) - (utf8.len(suffix) or #suffix)
		return prefix .. string.rep("@", math.clamp(free, 6, 52)) .. suffix
	end

	local royal = (playerGender == "girl") and "PRINCESS" or "KING"
	local messages = {
		build("SCRIPT BY " .. playerName .. " THE " .. royal .. " OF THE SERVER 👽 ", "V3 LOADED..."),
		gangName .. " ON TOP 👌🏼😍 BEST GANG EVER " .. gangName .. " X AE ⛩️ 😼",
	}
	if hasTarget == "yes" and targetName then
		if playerGender == "girl" then
			messages[3] = "SUN " .. targetName .. " AB TU GYI KYUKI 🎀 CUTIE " .. playerName .. " NE V3 LOAD KIYA 😍👌🏼"
		else
			messages[3] = "👽 " .. targetName .. " YOUR PAPA 😍 " .. playerName .. " NE APNA V3 LOAD KRLIYA 👽🫴🏼, ENJOY THE SHOW 👌🏼"
		end
	end

	local sentAll = true
	for i, message in ipairs(messages) do
		if not sendChat(channel, message) then
			sentAll = false
		end
		if i < #messages then
			task.wait(2)
		end
	end

	if sentAll then
		showStatus("V3 LOADED  •  by " .. playerName, true)
	else
		showStatus("V3 LOADED  •  by " .. playerName .. "  (chat message not sent)", false)
	end
end

--==================================================
-- SHARED UI WIDGETS (buttons, ripple, sliders)
--==================================================

-- click ripple that expands from the centre of a button
local function ripple(b)
	local r = Instance.new("Frame")
	r.AnchorPoint = Vector2.new(0.5, 0.5)
	r.Position = UDim2.new(0.5, 0, 0.5, 0)
	r.Size = UDim2.new(0, 0, 0, 0)
	r.BackgroundColor3 = Color3.new(1, 1, 1)
	r.BackgroundTransparency = 0.7
	r.BorderSizePixel = 0
	r.ZIndex = b.ZIndex + 1
	r.Parent = b
	Instance.new("UICorner", r).CornerRadius = UDim.new(1, 0)
	local tw = tween(r, 0.45, { Size = UDim2.new(1.2, 0, 2.6, 0), BackgroundTransparency = 1 })
	tw.Completed:Connect(function()
		r:Destroy()
	end)
end


--==================================================
-- PREMIUM NOTIFICATIONS (bottom centre toasts for every button)
--==================================================

do
	local holder = Instance.new("Frame")
	holder.Name = "Toasts"
	holder.AnchorPoint = Vector2.new(0.5, 1)
	holder.Position = UDim2.new(0.5, 0, 1, -22)
	holder.Size = UDim2.new(0, 270, 0, 240)
	holder.BackgroundTransparency = 1
	holder.ZIndex = 300
	holder.Parent = sg

	local lay = Instance.new("UIListLayout", holder)
	lay.VerticalAlignment = Enum.VerticalAlignment.Bottom
	lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lay.Padding = UDim.new(0, 6)
	lay.SortOrder = Enum.SortOrder.LayoutOrder

	local hs = Instance.new("UIScale", holder)
	local function fit()
		local cam = workspace.CurrentCamera
		if not cam then return end
		hs.Scale = math.clamp(cam.ViewportSize.X / 560, 0.7, 1)
	end
	fit()

	local order = 0
	local live = {}

	local function dismiss(w, card)
		if not w.Parent then return end
		local tw = tween(card, 0.3, { Position = UDim2.new(0, 0, 0, 40), BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		for _, d in ipairs(card:GetDescendants()) do
			if d:IsA("TextLabel") then tween(d, 0.25, { TextTransparency = 1 }) end
		end
		tw.Completed:Connect(function()
			if w.Parent then w:Destroy() end
		end)
	end

	Config.notify = function(title, state)
		order = order + 1

		local w = Instance.new("Frame")
		w.LayoutOrder = order
		w.Size = UDim2.new(1, 0, 0, 46)
		w.BackgroundTransparency = 1
		w.ZIndex = 300
		w.Parent = holder

		table.insert(live, w)
		while #live > 4 do
			local o = table.remove(live, 1)
			if o and o.Parent then o:Destroy() end
		end

		local card = Instance.new("Frame", w)
		card.Size = UDim2.new(1, 0, 1, 0)
		card.Position = UDim2.new(0, 0, 0, 40)
		card.BackgroundColor3 = Theme._card
		card.BackgroundTransparency = 1
		card.BorderSizePixel = 0
		card.ZIndex = 301
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
		local st = Instance.new("UIStroke", card)
		st.Thickness = 1.6
		st.Color = Color3.new(1, 1, 1)
		st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		addGradient(st, Theme.A1, Theme.A2, 0)

		local accent = Instance.new("Frame", card)
		accent.Position = UDim2.new(0, 8, 0.5, -14)
		accent.Size = UDim2.new(0, 4, 0, 28)
		accent.BackgroundColor3 = Color3.new(1, 1, 1)
		accent.BorderSizePixel = 0
		accent.ZIndex = 302
		Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)
		addGradient(accent, Theme.A1, Theme.A2, 90)

		local t1 = Instance.new("TextLabel", card)
		t1.Position = UDim2.new(0, 20, 0, 5)
		t1.Size = UDim2.new(1, -78, 0, 20)
		t1.BackgroundTransparency = 1
		t1.Text = title
		t1.TextColor3 = Theme.Text
		t1.Font = Enum.Font.GothamBold
		t1.TextSize = 13
		t1.TextXAlignment = Enum.TextXAlignment.Left
		t1.TextTruncate = Enum.TextTruncate.AtEnd
		t1.TextTransparency = 1
		t1.ZIndex = 303

		local sub = (state == "ON" and "Enabled") or (state == "OFF" and "Disabled") or "Executed"
		local subCol = (state == "ON" and Color3.fromRGB(90, 255, 150)) or (state == "OFF" and Color3.fromRGB(255, 100, 110)) or Theme.Muted

		local t2 = Instance.new("TextLabel", card)
		t2.Position = UDim2.new(0, 20, 0, 24)
		t2.Size = UDim2.new(1, -78, 0, 16)
		t2.BackgroundTransparency = 1
		t2.Text = sub
		t2.TextColor3 = subCol
		t2.Font = Enum.Font.Gotham
		t2.TextSize = 11
		t2.TextXAlignment = Enum.TextXAlignment.Left
		t2.TextTransparency = 1
		t2.ZIndex = 303

		local pill = Instance.new("TextLabel", card)
		pill.AnchorPoint = Vector2.new(1, 0.5)
		pill.Position = UDim2.new(1, -10, 0.5, 0)
		pill.Size = UDim2.new(0, 44, 0, 22)
		pill.BackgroundColor3 = subCol
		pill.BackgroundTransparency = 1
		pill.Text = state or "OK"
		pill.TextColor3 = Color3.fromRGB(10, 12, 24)
		pill.Font = Enum.Font.GothamBlack
		pill.TextSize = 11
		pill.TextTransparency = 1
		pill.ZIndex = 303
		Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

		tween(card, 0.35, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0.05 }, Enum.EasingStyle.Back)
		tween(t1, 0.3, { TextTransparency = 0 })
		tween(t2, 0.3, { TextTransparency = 0 })
		tween(pill, 0.3, { TextTransparency = 0, BackgroundTransparency = 0 })

		task.delay(2.2, function()
			dismiss(w, card)
		end)
	end
end

local function notifyFromButton(b)
	local raw = b.Text or ""
	if raw == "" then return end
	local base, state = raw:match("^(.-)%s*:%s*(ON)$")
	if not base then base, state = raw:match("^(.-)%s*:%s*(OFF)$") end
	local title = (base or raw):gsub("%s+", " ")
	pcall(Config.notify, title, state)
end

local function makeButton(parent, text, size, textSize, callback)
	local b = Instance.new("TextButton")
	b.Parent = parent
	b.Size = size
	b.BackgroundColor3 = Theme._n
	b.BackgroundTransparency = 0
	b.BorderSizePixel = 0
	b.ClipsDescendants = true

	b.Text = text
	b.TextColor3 = Theme.Text
	b.Font = Fonts[Theme.FontIndex]
	b.TextSize = textSize
	b.TextWrapped = true
	b.AutoButtonColor = false
	b.ZIndex = 15

	regCorner(b, 8)
	local stroke = borderStroke(b, 1.3, 0.15)

	table.insert(Reg.buttons, b)
	table.insert(Reg.texts, b)

	b.MouseEnter:Connect(function()
		tween(b, 0.15, { BackgroundColor3 = Theme._h })
		tween(stroke, 0.15, { Thickness = 2 })
	end)

	b.MouseLeave:Connect(function()
		tween(b, 0.15, { BackgroundColor3 = Theme._n })
		tween(stroke, 0.15, { Thickness = 1.3 })
	end)

	b.MouseButton1Down:Connect(function()
		tween(b, 0.07, { BackgroundColor3 = Theme._a })
		ripple(b)
	end)

	b.MouseButton1Up:Connect(function()
		tween(b, 0.12, { BackgroundColor3 = Theme._h })
	end)

	if typeof(callback) == "function" then
		b.MouseButton1Click:Connect(function()
			callback(b)
			notifyFromButton(b)
		end)
	end

	return b
end

-- slider: returns { set = function(value, silent), get = function() }
local function makeSlider(parent, label, min, max, default, fmt, onChange, scroller)
	local item = Instance.new("Frame")
	item.Size = UDim2.new(1, -12, 0, 34)
	item.BackgroundTransparency = 1
	local Z = (parent:IsA("GuiObject") and parent.ZIndex >= 100) and 130 or 15
	item.ZIndex = Z
	item.Parent = parent

	local nameL = Instance.new("TextLabel")
	nameL.Position = UDim2.new(0, 2, 0, 0)
	nameL.Size = UDim2.new(0.62, 0, 0, 14)
	nameL.BackgroundTransparency = 1
	nameL.Text = label
	nameL.TextColor3 = Theme.Muted
	nameL.Font = Enum.Font.GothamBold
	nameL.TextSize = 9
	nameL.TextXAlignment = Enum.TextXAlignment.Left
	nameL.ZIndex = Z + 1
	nameL.Parent = item

	local valL = Instance.new("TextLabel")
	valL.Position = UDim2.new(0.62, 0, 0, 0)
	valL.Size = UDim2.new(0.38, -2, 0, 14)
	valL.BackgroundTransparency = 1
	valL.Text = ""
	valL.TextColor3 = Theme.Text
	valL.Font = Enum.Font.GothamBold
	valL.TextSize = 9
	valL.TextXAlignment = Enum.TextXAlignment.Right
	valL.ZIndex = Z + 1
	valL.Parent = item

	local track = Instance.new("Frame")
	track.Position = UDim2.new(0, 30, 0, 19)
	track.Size = UDim2.new(1, -60, 0, 6)
	track.BackgroundColor3 = Color3.fromRGB(34, 36, 70)
	track.BorderSizePixel = 0
	track.ZIndex = Z + 1
	track.Parent = item
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	fill.BorderSizePixel = 0
	fill.ZIndex = Z + 2
	fill.Parent = track
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	table.insert(Reg.grads, addGradient(fill, Theme.A1, Theme.A2, 0))

	local knob = Instance.new("Frame")
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(0, 0, 0.5, 0)
	knob.Size = UDim2.new(0, 13, 0, 13)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.BorderSizePixel = 0
	knob.ZIndex = Z + 3
	knob.Parent = track
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
	borderStroke(knob, 1.5, 0)

	local value = default

	local function setValue(v, silent)
		v = math.clamp(v, min, max)
		value = v
		local alpha = (v - min) / (max - min)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		valL.Text = fmt(v)
		if not silent then
			onChange(v)
		end
	end

	-- no dragging (it glitched with scrolling): "-" and "+" buttons step the value
	local STEP = (max - min) / 20

	local function stepButton(text, xPos, dir)
		local b = makeButton(item, text, UDim2.new(0, 24, 0, 18), 14, nil)
		b.Position = xPos
		b.ZIndex = Z + 10
		b.Font = Enum.Font.GothamBlack

		local held = 0
		b.MouseButton1Down:Connect(function()
			held += 1
			local id = held
			setValue(value + dir * STEP)
			task.spawn(function()
				task.wait(0.4)
				while held == id and b.Parent do
					setValue(value + dir * STEP)
					task.wait(0.07)
				end
			end)
		end)
		local function release() held += 1 end
		b.MouseButton1Up:Connect(release)
		b.MouseLeave:Connect(release)
		return b
	end

	stepButton("−", UDim2.new(0, 0, 0, 13), -1)
	stepButton("+", UDim2.new(1, -24, 0, 13), 1)

	setValue(default, true)

	return {
		frame = item,
		set = setValue,
		get = function() return value end
	}
end

--==================================================
-- MAIN GUI
-- CanvasGroup (for fade) + background frame child.
-- The gradient is on the background frame, never on the group.
--==================================================

local Main = Instance.new("CanvasGroup", sg)

Main.Name = "MainWindow"
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Size = UDim2.new(0,420,0,340)
Main.Position = UDim2.new(.5,0,.5,0)

Main.BackgroundTransparency = 1
Main.BorderSizePixel = 0
Main.Active = true
Main.ZIndex = 10
Main.Visible = false
Main.GroupTransparency = 1

regCorner(Main, 16)

local MainScale = Instance.new("UIScale", Main)
MainScale.Scale = baseScale() * 0.9

makeDraggable(Main)

local MainBg = Instance.new("Frame", Main)
MainBg.Name = "Bg"
MainBg.Size = UDim2.new(1,0,1,0)
MainBg.BackgroundColor3 = Color3.new(1,1,1)
MainBg.BackgroundTransparency = Theme.Opacity
MainBg.BorderSizePixel = 0
MainBg.ZIndex = 1
local MainBgGrad = addGradient(MainBg, shade(0.14), shade(0.24), 60)

local MainStroke, MainStrokeGrad = borderStroke(Main, 2.5, 0)

--==================================================
-- AURA (glow + pulse rings + particles coming out of the GUI)
--==================================================

local AuraRoot = Instance.new("Frame", sg)
AuraRoot.Name = "Aura"
AuraRoot.AnchorPoint = Vector2.new(0.5, 0.5)
AuraRoot.Size = UDim2.new(0, 420, 0, 340)
AuraRoot.Position = Main.Position
AuraRoot.BackgroundTransparency = 1
AuraRoot.ZIndex = 5
AuraRoot.Visible = false

local AuraScale = Instance.new("UIScale", AuraRoot)
AuraScale.Scale = MainScale.Scale

do
	local layers = {}
	local baseTrans = { 0.72, 0.82, 0.90, 0.95 }

	for i = 1, 4 do
		local layer = Instance.new("Frame")
		layer.AnchorPoint = Vector2.new(0.5, 0.5)
		layer.Position = UDim2.new(0.5, 0, 0.5, 0)
		layer.Size = UDim2.new(1, i * 8, 1, i * 8)
		layer.BackgroundTransparency = 1
		layer.BorderSizePixel = 0
		layer.ZIndex = 1
		layer.Parent = AuraRoot
		Instance.new("UICorner", layer).CornerRadius = UDim.new(0, 16 + i * 6)
		local stroke = borderStroke(layer, 4 + i * 7, baseTrans[i])
		table.insert(layers, { stroke = stroke, base = baseTrans[i] })
	end

	-- energy rings that spread out of the window
	local rings = {}
	for i = 1, 3 do
		local ringF = Instance.new("Frame")
		ringF.AnchorPoint = Vector2.new(0.5, 0.5)
		ringF.Position = UDim2.new(0.5, 0, 0.5, 0)
		ringF.Size = UDim2.new(1, 0, 1, 0)
		ringF.BackgroundTransparency = 1
		ringF.BorderSizePixel = 0
		ringF.ZIndex = 2
		ringF.Parent = AuraRoot
		Instance.new("UICorner", ringF).CornerRadius = UDim.new(0, 18)
		local stroke = borderStroke(ringF, 2, 0.3)
		table.insert(rings, ringF)

		local info = TweenInfo.new(2.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, -1, false, (i - 1) * 0.9)
		TweenService:Create(ringF, info, { Size = UDim2.new(1, 120, 1, 120) }):Play()
		TweenService:Create(stroke, info, { Transparency = 1 }):Play()
	end

	-- rising particles
	local PCOUNT = 18
	local particles = {}

	for i = 1, PCOUNT do
		local p = Instance.new("Frame")
		p.AnchorPoint = Vector2.new(0.5, 0.5)
		p.Size = UDim2.new(0, 5, 0, 5)
		p.BackgroundColor3 = (i % 2 == 0) and Theme.A1 or Theme.A2
		p.BackgroundTransparency = 1
		p.BorderSizePixel = 0
		p.ZIndex = 3
		p.Parent = AuraRoot
		Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
		particles[i] = p

		task.spawn(function()
			task.wait(math.random() * 2)
			while sg.Parent do
				local allowed = math.ceil(PCOUNT * math.max(Theme.AuraPower, 0.15))
				if Theme.Aura and Theme.Particles and AuraRoot.Visible and i <= allowed then
					local side = math.random(1, 4)
					local px, py, dx, dy
					if side == 1 then
						px, py, dx, dy = math.random(), 0, 0, -1
					elseif side == 2 then
						px, py, dx, dy = math.random(), 1, 0, 1
					elseif side == 3 then
						px, py, dx, dy = 0, math.random(), -1, 0
					else
						px, py, dx, dy = 1, math.random(), 1, 0
					end
					local dist = math.random(50, 115)
					local sizePx = math.random(3, 7)
					p.Size = UDim2.new(0, sizePx, 0, sizePx)
					p.Position = UDim2.new(px, 0, py, 0)
					p.BackgroundTransparency = 0.15
					local dur = 1.4 + math.random() * 1.4
					tween(p, dur, {
						Position = UDim2.new(px, dx * dist + math.random(-14, 14), py, dy * dist + math.random(-14, 14)),
						BackgroundTransparency = 1,
						Size = UDim2.new(0, 1, 0, 1)
					}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					task.wait(dur * (0.5 + math.random() * 0.4))
				else
					task.wait(0.4)
				end
			end
		end)
	end

	table.insert(Reg.accentFns, function()
		for i, p in ipairs(particles) do
			p.BackgroundColor3 = (i % 2 == 0) and Theme.A1 or Theme.A2
		end
	end)

	table.insert(Reg.lookFns, function()
		local power = math.clamp(Theme.AuraPower, 0, 1)
		for _, l in ipairs(layers) do
			l.stroke.Transparency = 1 - (1 - l.base) * power * 1.35
		end
		for _, r in ipairs(rings) do
			r.Visible = Theme.Aura and power > 0.05
		end
		AuraRoot.Visible = Main.Visible and Theme.Aura
	end)
end

local function syncAura()
	AuraRoot.Position = Main.Position
	AuraScale.Scale = MainScale.Scale
	AuraRoot.Visible = Main.Visible and Theme.Aura
end

Main:GetPropertyChangedSignal("Position"):Connect(syncAura)
Main:GetPropertyChangedSignal("Visible"):Connect(syncAura)
MainScale:GetPropertyChangedSignal("Scale"):Connect(syncAura)

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel",Main)

Title.Size = UDim2.new(1,-20,0,30)
Title.Position = UDim2.new(0,10,0,4)

Title.BackgroundTransparency = 1
-- title = [PLAYER NAME] V3 (the name typed in the first box)
Title.Text = string.upper(playerName) .. " V3"
Title.TextColor3 = Color3.new(1, 1, 1)

Title.Font = Fonts[Theme.FontIndex]
Title.TextScaled = true
Title.TextXAlignment = Enum.TextXAlignment.Center

Title.ZIndex = 12

local TitleLimit = Instance.new("UITextSizeConstraint", Title)
TitleLimit.MaxTextSize = 21
TitleLimit.MinTextSize = 10
table.insert(Reg.texts, Title)

local TitleGrad = Instance.new("UIGradient", Title)
Reg.titleGrad = TitleGrad

--==================================================
-- SUB TITLE
--==================================================

local SubTitle = Instance.new("TextLabel",Main)

SubTitle.Size = UDim2.new(1,-20,0,18)
SubTitle.Position = UDim2.new(0,10,0,34)

SubTitle.BackgroundTransparency = 1
SubTitle.RichText = true

-- subtitle = [GANG NAME] ON TOP (the gang typed in the second box)
local function richSafe(s)
	s = s:gsub("&", "&amp;")
	s = s:gsub("<", "&lt;")
	s = s:gsub(">", "&gt;")
	return s
end

SubTitle.Text =
'<font color="#FFD700">' .. richSafe(string.upper(gangName)) .. '</font> <font color="#FF2D55">ON TOP</font> 💀😼'

SubTitle.Font = Fonts[Theme.FontIndex]
SubTitle.TextScaled = true

SubTitle.ZIndex = 12

local SubLimit = Instance.new("UITextSizeConstraint", SubTitle)
SubLimit.MaxTextSize = 12
SubLimit.MinTextSize = 7
table.insert(Reg.texts, SubTitle)

-- glowing divider under the title
local Divider = Instance.new("Frame", Main)
Divider.Position = UDim2.new(0, 10, 0, 55)
Divider.Size = UDim2.new(1, -20, 0, 2)
Divider.BackgroundColor3 = Color3.new(1, 1, 1)
Divider.BorderSizePixel = 0
Divider.ZIndex = 12
Instance.new("UICorner", Divider).CornerRadius = UDim.new(1, 0)
table.insert(Reg.grads, addGradient(Divider, Theme.A1, Theme.A2, 0))

--==================================================
-- SIDEBAR
--==================================================

local Sidebar = Instance.new("ScrollingFrame",Main)

Sidebar.Size = UDim2.new(0,125,1,-70)
Sidebar.Position = UDim2.new(0,10,0,60)

Sidebar.BackgroundColor3 = Color3.fromRGB(8,10,28)
Sidebar.BackgroundTransparency = .25
Sidebar.BorderSizePixel = 0

Sidebar.ScrollBarThickness = 2
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
Sidebar.CanvasSize = UDim2.new(0,0,0,0)

Sidebar.ZIndex = 11

regCorner(Sidebar, 12)
borderStroke(Sidebar, 1, 0.5)

local SideList = Instance.new("UIListLayout",Sidebar)

SideList.Padding = UDim.new(0,GAP)
SideList.HorizontalAlignment =
Enum.HorizontalAlignment.Center

local SidePadding = Instance.new("UIPadding",Sidebar)

SidePadding.PaddingTop = UDim.new(0,GAP)
SidePadding.PaddingBottom = UDim.new(0,GAP)

--==================================================
-- PAGES
--==================================================

local Pages = Instance.new("Frame",Main)
Pages.Size = UDim2.new(1,-160,1,-70)
Pages.Position = UDim2.new(0,148,0,60)
Pages.BackgroundTransparency = 1
Pages.ZIndex = 11

local function createPage()
	local p = Instance.new("ScrollingFrame",Pages)

	p.Size = UDim2.new(1,0,1,0)
	p.BackgroundTransparency = 1
	p.BorderSizePixel = 0
	p.Visible = false
	p.ScrollBarThickness = 3
	p.AutomaticCanvasSize = Enum.AutomaticSize.Y
	p.CanvasSize = UDim2.new(0,0,0,0)
	p.ZIndex = 11

	local layout = Instance.new("UIListLayout",p)
	layout.Padding = UDim.new(0,GAP)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	return p
end

-- page number = tab number (same order as the tab list below)
local P1 = createPage() -- INFO
local P2 = createPage() -- OWNER
local P3 = createPage() -- FEATURES
local P4 = createPage() -- PANEL
local P5 = createPage() -- SPAMMER
local P6 = createPage() -- FUN
local P7 = createPage() -- DJ SYSTEM
local P8 = createPage() -- SHIELD
local P9 = createPage() -- NOTE
local P10 = createPage() -- OTHERS
local P11 = createPage() -- VOIDOUT
local P12 = createPage() -- MINI GAMES
local P13 = createPage() -- SPECIAL
local P14 = createPage() -- ALPHA EMPIRE
for i, pg in ipairs({ P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, P14 }) do
	pg.Name = "Page" .. i
end

--==================================================
-- THEME APPLY FUNCTIONS
--==================================================

local function applyAccent()
	local seq = ColorSequence.new(Theme.A1, Theme.A2)
	for i = #Reg.grads, 1, -1 do
		local g = Reg.grads[i]
		if g.Parent then
			g.Color = seq
		else
			table.remove(Reg.grads, i)
		end
	end

	if Reg.titleGrad then
		Reg.titleGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Theme.A1),
			ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, Theme.A2)
		})
	end

	-- button text + tab text follow the theme
	local tc = Theme.A1:Lerp(Theme.A2, 0.5):Lerp(Color3.new(1, 1, 1), 0.5)
	Theme.Text2 = tc
	for _, list in ipairs({ Reg.buttons, Reg.tabs }) do
		for _, b in ipairs(list) do
			if b.Parent then
				b.TextColor3 = tc
			end
		end
	end

	for _, fn in ipairs(Reg.accentFns) do
		fn()
	end
end

local function applyShades()
	refreshShadeCache()

	MainBgGrad.Color = ColorSequence.new(shade(0.14), shade(0.24))

	for i = #Reg.buttons, 1, -1 do
		local b = Reg.buttons[i]
		if b.Parent then
			b.BackgroundColor3 = Theme._n
		else
			table.remove(Reg.buttons, i)
		end
	end

	for _, b in ipairs(Reg.tabs) do
		b.BackgroundColor3 = (b == activeTab) and Theme._a or Theme._n
	end

	for _, f in ipairs(Reg.fields) do
		f.BackgroundColor3 = Theme._field
	end

	for _, c in ipairs(Reg.cards) do
		c.BackgroundColor3 = Theme._card
	end
end

local function applyLook()
	local font = Fonts[Theme.FontIndex]
	for i = #Reg.texts, 1, -1 do
		local t = Reg.texts[i]
		if t.Parent then
			t.Font = font
		else
			table.remove(Reg.texts, i)
		end
	end

	for i = #Reg.corners, 1, -1 do
		local c = Reg.corners[i]
		if c.c.Parent then
			c.c.CornerRadius = UDim.new(0, math.floor(c.base * Theme.Round + 0.5))
		else
			table.remove(Reg.corners, i)
		end
	end

	MainBg.BackgroundTransparency = Theme.Opacity

	if mainOpen then
		for _, t in ipairs(mainTweens) do
			t:Cancel()
		end
		table.clear(mainTweens)
		Main.GroupTransparency = 0
		MainScale.Scale = baseScale()
	end

	for _, fn in ipairs(Reg.lookFns) do
		fn()
	end
end

local function applyAll()
	applyShades()
	applyAccent()
	applyLook()
end

--==================================================
-- TAB FUNCTION
--==================================================

local function setTabLook(b, mode)
	local c = Theme._n
	if mode == "active" then
		c = Theme._a
	elseif mode == "hover" then
		c = Theme._h
	end
	tween(b, 0.15, { BackgroundColor3 = c })

	local bar = b:FindFirstChild("AccentBar")
	if bar then
		local show = (mode == "active")
		if show and not bar.Visible then
			bar.Size = UDim2.new(0, 3, 0, 0)
			tween(bar, 0.25, { Size = UDim2.new(0, 3, 0.6, 0) }, Enum.EasingStyle.Back)
		end
		bar.Visible = show
	end
end

local function tab(name, page)
	local b = Instance.new("TextButton", Sidebar)

	b.Size = UDim2.new(1, -8, 0, 36)
	b.BackgroundColor3 = Theme._n
	b.BorderSizePixel = 0
	b.Text = name
	b.TextColor3 = Theme.Text
	b.Font = Fonts[Theme.FontIndex]
	b.TextSize = 13
	b.TextWrapped = true
	b.ZIndex = 15
	b.AutoButtonColor = false
	b.ClipsDescendants = true

	regCorner(b, 8)
	borderStroke(b, 1.3, 0.2)

	table.insert(Reg.tabs, b)
	table.insert(Reg.texts, b)

	-- accent bar shown on the active tab
	local bar = Instance.new("Frame", b)
	bar.Name = "AccentBar"
	bar.AnchorPoint = Vector2.new(0, 0.5)
	bar.Position = UDim2.new(0, 3, 0.5, 0)
	bar.Size = UDim2.new(0, 3, 0.6, 0)
	bar.BackgroundColor3 = Color3.new(1, 1, 1)
	bar.BorderSizePixel = 0
	bar.Visible = false
	bar.ZIndex = 16
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
	table.insert(Reg.grads, addGradient(bar, Theme.A1, Theme.A2, 90))

	b.MouseEnter:Connect(function()
		if activeTab ~= b then setTabLook(b, "hover") end
	end)

	b.MouseLeave:Connect(function()
		if activeTab ~= b then setTabLook(b, "normal") end
	end)

	b.MouseButton1Down:Connect(function()
		ripple(b)
	end)

	b.MouseButton1Click:Connect(function()
		for _, v in ipairs(Pages:GetChildren()) do
			if v:IsA("ScrollingFrame") then
				v.Visible = false
			end
		end

		if activeTab and activeTab ~= b then
			setTabLook(activeTab, "normal")
		end
		activeTab = b
		setTabLook(b, "active")

		page.Position = UDim2.new(0, 18, 0, 0)
		page.Visible = true
		tween(page, 0.25, { Position = UDim2.new(0, 0, 0, 0) })
	end)

	return b
end

--==================================================
-- BUTTON FUNCTION
--==================================================

-- registry of every hub button (used by FAVORITES / SEARCH / KEYBINDS / quick bar)
do
	Theme._all, Theme._ids, Theme._fav, Theme._favEdit = {}, {}, {}, true
	Theme._reg = function(b, text, parent, cb)
		local p = parent
		while p and p.Parent ~= Pages do p = p.Parent end
		local key = (p and p.Name or "x") .. "|" .. tostring(text)
		local n = (Theme._ids[key] or 0) + 1
		Theme._ids[key] = n
		local id = (n == 1) and key or (key .. "#" .. n)
		local e = { b = b, id = id, cb = cb, text0 = tostring(text) }
		table.insert(Theme._all, e)

		local st = Instance.new("TextButton")
		st.Name = "FavStar"
		st.Size = UDim2.new(0, 34, 0, 20)
		st.AnchorPoint = Vector2.new(1, 0.5)
		st.Position = UDim2.new(1, -4, 0.5, 0)
		st.BackgroundColor3 = Color3.new(0, 0, 0)
		st.BackgroundTransparency = 0.45
		st.BorderSizePixel = 0
		st.Text = "FAV"
		st.TextSize = 10
		st.Font = Enum.Font.GothamBold
		st.TextColor3 = Color3.new(1, 1, 1)
		st.AutoButtonColor = false
		st.ZIndex = 18
		st.Visible = Theme._favEdit
		Instance.new("UICorner", st).CornerRadius = UDim.new(0, 5)
		st.Parent = b
		e.star = st
		st.MouseButton1Click:Connect(function()
			if Theme._favToggle then Theme._favToggle(e) end
		end)
		return e
	end
end

local function btn(text, parent, callback)
	local b = makeButton(parent, text, UDim2.new(1, -10, 0, 36), 13, callback)
	pcall(Theme._reg, b, text, parent, callback)
	return b
end

--==================================================
-- TABS
--==================================================

tab("INFO 📊",P1)
tab("OWNER 🚩",P2)
tab("ADMIN 🔲",P3)
tab("PANEL 💀",P4)
tab("SPAMMER 🌀",P5)
tab("BANGS 💥",P6)
tab("DJ SYSTEM 🎶",P7)
tab("SHIELD 🤖",P8)
tab("NOTE 🔷",P14)
tab("OTHERS ☣",P10)
tab("VOIDOUT 🗿",P11)
tab("MINI GAMES 🎮",P12)
tab("SPECIAL 💖",P13)
tab("ALPHA EMPIRE ⛩️",P9)

--==================================================
-- ADD HERE P1 (INFO is the first tab)
--==================================================
P1.Visible = true
do
	-- highlight the first tab (INFO) as active
	local first
	for _, v in ipairs(Sidebar:GetChildren()) do
		if v:IsA("TextButton") then first = v break end
	end
	if first then
		activeTab = first
		first.BackgroundColor3 = Theme._a
		local bar = first:FindFirstChild("AccentBar")
		if bar then bar.Visible = true end
	end
end

-- smaller target name box
local targetBox = Instance.new("TextBox", P4)
targetBox.Size = UDim2.new(1, -10, 0, 30)
targetBox.PlaceholderText = "⚡ Enter Target Name..."
targetBox.PlaceholderColor3 = Color3.fromRGB(150, 155, 195)
targetBox.Text = ""
targetBox.BackgroundColor3 = Theme._field
targetBox.TextColor3 = Theme.Text
targetBox.Font = Enum.Font.GothamMedium
targetBox.TextSize = 13
targetBox.ClearTextOnFocus = false
targetBox.ZIndex = 15
regCorner(targetBox, 8)
borderStroke(targetBox, 1.3, 0.1)
table.insert(Reg.fields, targetBox)

local function getT()
	local n = targetBox.Text:lower()
	if n == "" then return nil end
	for _, v in pairs(Players:GetPlayers()) do
		if v ~= player and (v.Name:lower():find(n) or v.DisplayName:lower():find(n)) then return v end
	end
end
--==================================================
-- YOU WILL ADD HERE
-- (the troll-mode function startTroll(mode) goes here)
--==================================================

local function startTroll(mode)
Config.CurrentTroll = mode
task.spawn(function()
while Config.CurrentTroll == mode do
local t = getT()
local root = getRoot()
local hum = getHum()

if t and t.Character and root and hum then
local tRoot = t.Character:FindFirstChild("HumanoidRootPart")
local tHead = t.Character:FindFirstChild("Head")

if mode == "facebang" and tHead then
root.CFrame = tHead.CFrame * CFrame.new(0, 0, -0.8) * CFrame.Angles(0, math.pi, 0) + tHead.CFrame.LookVector * math.sin(tick() * 25) * 0.6
elseif mode == "bang" and tRoot then
root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 1.2 + math.sin(tick() * 25) * 0.8)
elseif mode == "headsit" and tHead then
hum.Sit = true
root.CFrame = tHead.CFrame * CFrame.new(0, 1, 0)
elseif mode == "frontsit" and tHead then
hum.Sit = true
root.CFrame = tHead.CFrame * CFrame.new(0, 0.5, -1) * CFrame.Angles(0, math.pi, 0)
elseif mode == "annoy" and tRoot then
root.CFrame = tRoot.CFrame * CFrame.new(math.random(-4, 4), math.random(-2, 4), math.random(-4, 4))
end
end
RunService.Heartbeat:Wait()
end

end)

end


btn("GO TO 👤", P4, function()
	local t = getT()
	local root = getRoot()
	if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") and root then
		root.CFrame = t.Character.HumanoidRootPart.CFrame
	end
end)

btn("🚀 GOTO", P4, function()
	local t = getT()
	if t and t.Character and t.Character.HumanoidRootPart then
		pcall(function()
			player.Character.HumanoidRootPart.CFrame = t.Character.HumanoidRootPart.CFrame
		end)
	end
end)


btn("FACE BANG 👄", P4, function() startTroll("facebang") end)

btn("VIEW 👀", P4, function()
	local t = getT()
	if t and t.Character and t.Character:FindFirstChildOfClass("Humanoid") then
		workspace.CurrentCamera.CameraSubject = t.Character:FindFirstChildOfClass("Humanoid")
	end
end)

btn("BANG ⚠️", P4, function() startTroll("bang") end)
btn("HEADSIT 👽", P4, function() startTroll("headsit") end)
btn("FRONT SIT 💢", P4, function() startTroll("frontsit") end)

btn("👺 FRONT HEADSIT", P4, function()
    _G.Loop = true
    local t = getT()
    spawn(function()
        while _G.Loop and t and t.Character and t.Character.Head do
            RunService.Heartbeat:Wait()
            pcall(function()
                player.Character.Humanoid.Sit = true
                player.Character.HumanoidRootPart.CFrame = t.Character.Head.CFrame * CFrame.new(0,0.5,-1) * CFrame.Angles(0,math.pi,0)
            end)
        end
    end)
end)

btn("ANNOY🍁", P4, function() startTroll("annoy") end)




do
-- movement controls (use the target name box above)
-- only ONE troll / movement runs at a time: starting any mode stops the previous one
local Tr = { speed = 5, dist = 8, height = 2, angle = 0, target = nil, last = nil }


local MOVE = {}      -- mode -> { button, label }
local isMove = {}    -- mode -> true

local function moveButton(label, mode)
	isMove[mode] = true
	local b = btn(label .. ": OFF", P4, function(self)
		if Config.CurrentTroll == mode then
			Config.CurrentTroll = nil
			return
		end
		local t = getT()
		if not t then return end
		_G.Loop = false            -- stops the old _G.Loop style trolls
		Tr.target = t
		Tr.angle = 0
		Config.CurrentTroll = mode -- this also stops every other mode
		self.Text = label .. ": ON"
	end)
	MOVE[mode] = { b = b, label = label }
end

moveButton("🌀 ORBIT 360°", "orbit")
moveButton("🌪️ SPIRAL", "spiral")
moveButton("🛸 HOVER", "hover")
moveButton("🧲 FOLLOW", "follow")
moveButton("🧢 HEADSIT", "headsit")

local function myRoot()
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart"), c
end

-- smooth movement (own Heartbeat, not the slow shared loop)
local wasActive = false
RunService.Heartbeat:Connect(function(dt)
	local mode = Config.CurrentTroll

	-- keep the ON/OFF text of every button correct
	for m, d in pairs(MOVE) do
		local want = d.label .. (mode == m and ": ON" or ": OFF")
		if d.b.Text ~= want then d.b.Text = want end
	end

	local active = isMove[mode] == true

	if not active then
		if wasActive then
			wasActive = false
			Tr.target = nil
			local h = getHum()
			if h and h.Sit then h.Sit = false end
		end
		return
	end
	wasActive = true

	local tp = Tr.target
	local tc = tp and tp.Character
	local troot = tc and tc:FindFirstChild("HumanoidRootPart")
	local root, char = myRoot()
	if not (troot and root) then
		if not (tp and tp.Parent) then Config.CurrentTroll = nil end
		return
	end

	-- no pushing / flinging while we move around the target
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	Tr.angle = Tr.angle + Tr.speed * dt * 0.6
	local tpos = troot.Position

	if mode == "orbit" then
		local pos = tpos + Vector3.new(math.cos(Tr.angle), 0, math.sin(Tr.angle)) * Tr.dist + Vector3.new(0, Tr.height, 0)
		root.CFrame = CFrame.lookAt(pos, Vector3.new(tpos.X, pos.Y, tpos.Z))

	elseif mode == "spiral" then
		local r = Tr.dist * (0.55 + 0.45 * math.sin(Tr.angle * 0.5))
		local y = Tr.height + math.sin(Tr.angle * 0.7) * Tr.dist * 0.4
		local pos = tpos + Vector3.new(math.cos(Tr.angle), 0, math.sin(Tr.angle)) * r + Vector3.new(0, y, 0)
		root.CFrame = CFrame.lookAt(pos, tpos)

	elseif mode == "hover" then
		local pos = tpos + Vector3.new(0, Tr.height + 4, 0)
		root.CFrame = CFrame.new(pos) * CFrame.Angles(0, Tr.angle * 1.5, 0)

	elseif mode == "follow" then
		local look = troot.CFrame.LookVector
		local side = troot.CFrame.RightVector
		local pos = tpos - look * Tr.dist * 0.5 + side * Tr.dist * 0.5 + Vector3.new(0, Tr.height - 2, 0)
		root.CFrame = CFrame.lookAt(pos, pos + look)

	elseif mode == "headsit" then
		local head = tc:FindFirstChild("Head") or troot
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.Sit = true end
		root.CFrame = head.CFrame * CFrame.new(0, head.Size.Y / 2 + 1.6, 0)
	end
end)

-- own body must not collide while a movement is active
RunService.Stepped:Connect(function()
	if not isMove[Config.CurrentTroll] then return end
	local c = player.Character
	if not c then return end
	for _, d in ipairs(c:GetChildren()) do
		if d:IsA("BasePart") and d.CanCollide then d.CanCollide = false end
	end
end)

end

btn("STOP TROLL 💢", P4, function()
	Config.CurrentTroll = nil
	_G.Loop = false
	local hum = getHum()
	if hum then
		hum.Sit = false
		workspace.CurrentCamera.CameraSubject = hum
	end
end)


--==================================================
-- P5 : SPAMMER
--==================================================

btn("CUSTOM SPAM 😎👺",P5,function()
local message = "SCRIPT BY " .. playerName
    .. " _______//_______//______💀🎀_______//______//______"
    .. "MADE BY " .. playerName
    .. "_________________COUSTAM SPAM V1 LOADED 💀🔥..."

local channel = game:GetService("TextChatService")
    :FindFirstChild("TextChannels")

channel = channel and channel:FindFirstChild("RBXGeneral")

if channel then
    pcall(function()
        channel:SendAsync(message)
    end)
		end		

		
loadstring(game:HttpGet("https://pastebin.com/raw/Desuspvr"))()end)

btn("CUSTOM SPAM 2 😾💢",P5,function()
local message = "SCRIPT BY " .. playerName
    .. " _______//_______//______💀🎀_______//______//______"
    .. "MADE BY " .. playerName
    .. "_________________COUSTAM SPAM V2 LOADED 💀🔥..."

local channel = game:GetService("TextChatService")
    :FindFirstChild("TextChannels")

channel = channel and channel:FindFirstChild("RBXGeneral")

if channel then
    pcall(function()
        channel:SendAsync(message)
    end)
		end		
		
loadstring(game:HttpGet("https://pastebin.com/raw/TstyMhsU"))()end)

btn("CUSTOM SPAM 3 😈🌚",P5,function()
		
loadstring(game:HttpGet("https://pastebin.com/raw/0J61KcB0"))()end)

btn("PATTERN SPAM 👻👹",P5,function()
local message = "SCRIPT BY " .. playerName
    .. " _______//_______//______💀🎀_______//______//______"
    .. "MADE BY " .. playerName
    .. "_________________COUSTOM PATTERN SPAM LOADED 💀🔥..."

local channel = game:GetService("TextChatService")
    :FindFirstChild("TextChannels")

channel = channel and channel:FindFirstChild("RBXGeneral")

if channel then
    pcall(function()
        channel:SendAsync(message)
    end)
		end			
loadstring(game:HttpGet("https://pastebin.com/raw/RKiQvL04"))()end)


btn("2 TARGET SPAM 😤💢",P5,function()
local message = "SCRIPT BY " .. playerName
    .. " _______//_______//______//______"
    .. "//______//______MADE BY " .. playerName
    .. "_________________2 TARGET SPAM LOADED 💀🔥..."

local channel = game:GetService("TextChatService")
    :FindFirstChild("TextChannels")

channel = channel and channel:FindFirstChild("RBXGeneral")

if channel then
    pcall(function()
        channel:SendAsync(message)
    end)
		end
		
loadstring(game:HttpGet("https://pastebin.com/raw/T71436Kd"))()end)

btn("5 TARGET SPAM 👻👹",P5,function()
local message = "SCRIPT BY " .. playerName
    .. " _______//_______//______//______"
    .. "//______//______MADE BY " .. playerName
    .. "_________________5 TARGET SPAM LOADED 💀🔥..."

local channel = game:GetService("TextChatService")
    :FindFirstChild("TextChannels")

channel = channel and channel:FindFirstChild("RBXGeneral")

if channel then
    pcall(function()
        channel:SendAsync(message)
    end)
		end
		
loadstring(game:HttpGet("https://pastefy.app/VUD8pvut/raw"))()end)




btn("ROAST SPAM 💢🤬",P5,function()
local message = "SCRIPT BY " .. playerName
    .. " _______//_______//______💀🎀_______//______//______"
    .. "LEAVE KRJA 💀😈 MADE BY " .. playerName
    .. "________________ROAST SPAM LOADED BETE 😂 💀🔥..."

local channel = game:GetService("TextChatService")
    :FindFirstChild("TextChannels")

channel = channel and channel:FindFirstChild("RBXGeneral")

if channel then
    pcall(function()
        channel:SendAsync(message)
    end)
		end			
loadstring(game:HttpGet("https://pastebin.com/raw/crWrmZMT"))()end)

btn("ROAST SPAM 2 💢😤",P5,function()
local message = "SCRIPT BY " .. playerName
    .. " _______//_______😼💢______//_______"
    .. " CHAL LEAVE MAR BETE NHI TO HAG DEGA👺🌚 MADE BY " .. playerName
    .. "_________________ROAST SPAM V2 💀🔥..."

local channel = game:GetService("TextChatService")
    :FindFirstChild("TextChannels")

channel = channel and channel:FindFirstChild("RBXGeneral")

if channel then
    pcall(function()
        channel:SendAsync(message)
    end)
		end				
loadstring(game:HttpGet("https://pastebin.com/raw/BUpdET3L"))()end)



btn("3 TARGET SPAM (NEW)👺⚠️",P5,function()
local message = "SCRIPT BY " .. playerName
    .. " _______//_______//______💀🎀_______//______//______"
    .. " BEST 3 TARGET EVER 🥸😎 MADE BY " .. playerName
    .. "_________________3 TARGET SPAM 💀🔥..."

local channel = game:GetService("TextChatService")
    :FindFirstChild("TextChannels")

channel = channel and channel:FindFirstChild("RBXGeneral")

if channel then
    pcall(function()
        channel:SendAsync(message)
    end)
		end				
loadstring(game:HttpGet("https://pastebin.com/raw/ZND1sJu3"))()end)



btn("ULTIMATE SPAM 💥⚠️",P5,function()
local message = "SCRIPT BY " .. playerName
    .. " _______//_______//______💀🎀_______//______//______"
    .. "MADE BY " .. playerName
    .. "_________________ULTIMATE SPAM LOADED 😈🔥..."

local channel = game:GetService("TextChatService")
    :FindFirstChild("TextChannels")

channel = channel and channel:FindFirstChild("RBXGeneral")

if channel then
    pcall(function()
        channel:SendAsync(message)
    end)
		end				
loadstring(game:HttpGet("https://pastebin.com/raw/BKt9y40g"))()end)

btn("ALPHA EMPIRE ⛩️😼",P5,function()
		
loadstring(game:HttpGet("https://pastebin.com/raw/Bm3p4tnh"))()end)

btn("FORBID 🚫☣️",P5,function()
	
loadstring(game:HttpGet("https://gist.githubusercontent.com/forbidtherobloxscripter/3e1a67cdf3f22192307218825c8469ea/raw/d16fabac096433b08eb63170274af33c8345603e/fm%25201.5.txt"))()end)



--==================================================
-- P10 : OTHERS
--==================================================


btn("😋 AAYAN EMOTE", P10, function()
	loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-7yd7-I-Emote-Script-48024"))()
end)

-- native abilities (fly / noclip / speed / spin / inf jump / esp ...)
local Ab = { fly = false, noclip = false, speed = false, spin = false, esp = false, fb = false }
local AbV = { flySpeed = 80, walk = 100, spinSpeed = 300, fov = 70 }
local AbRef = {}

btn("🕊️ FLY: OFF", P10, function(self)
	Ab.fly = not Ab.fly
	self.Text = "🕊️ FLY: " .. (Ab.fly and "ON" or "OFF")
	if not Ab.fly then AbRef.stopFly() end
end)
AbRef.flySlider = makeSlider(P10, "FLY SPEED", 20, 300, AbV.flySpeed, function(v) return tostring(math.floor(v)) end, function(v) AbV.flySpeed = v end, P10)

btn("👻 NOCLIP: OFF", P10, function(self)
	Ab.noclip = not Ab.noclip
	self.Text = "👻 NOCLIP: " .. (Ab.noclip and "ON" or "OFF")
end)

btn("🏃 SPEED: OFF", P10, function(self)
	Ab.speed = not Ab.speed
	self.Text = "🏃 SPEED: " .. (Ab.speed and "ON" or "OFF")
	if not Ab.speed then
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if h then h.WalkSpeed = 16 end
	end
end)
AbRef.speedSlider = makeSlider(P10, "WALK SPEED", 16, 300, AbV.walk, function(v) return tostring(math.floor(v)) end, function(v) AbV.walk = v end, P10)

btn("🌀 SPIN: OFF", P10, function(self)
	Config.Spin = not Config.Spin
	self.Text = "🌀 SPIN: " .. (Config.Spin and "ON" or "OFF")
end)
AbRef.spinSlider = makeSlider(P10, "SPIN SPEED", 60, 1200, AbV.spinSpeed, function(v) return tostring(math.floor(v)) end, function(v) AbV.spinSpeed = v end, P10)

btn("🚀 INF JUMP: OFF", P10, function(self)
	Config.InfJump = not Config.InfJump
	self.Text = "🚀 INF JUMP: " .. (Config.InfJump and "ON" or "OFF")
end)

btn("🔦 FULLBRIGHT: OFF", P10, function(self)
	Ab.fb = not Ab.fb
	self.Text = "🔦 FULLBRIGHT: " .. (Ab.fb and "ON" or "OFF")
	AbRef.applyFB()
end)

btn("👁️ ESP: OFF", P10, function(self)
	Ab.esp = not Ab.esp
	self.Text = "👁️ ESP: " .. (Ab.esp and "ON" or "OFF")
	AbRef.refreshESP()
end)

AbRef.fovSlider = makeSlider(P10, "FIELD OF VIEW", 40, 120, AbV.fov, function(v) return tostring(math.floor(v)) end, function(v)
	AbV.fov = v
	local cam = workspace.CurrentCamera
	if cam then cam.FieldOfView = v end
end, P10)

btn("💃 COPY EMOTE AND MORE", P10, function()
	loadstring(game:HttpGet("https://rawscripts.net/raw/Ro-vibes-ROVibes-95220"))()
end)

btn("🪓 SKY DESTROYER", P10, function()
	loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-sky-destroyer-V2-AXEZZ-110640"))()
end)

btn("🧍‍♂️ STAND BY", P10, function()
	loadstring(game:HttpGet("https://pastebin.com/raw/10c0XURE"))()
end)

btn("🎈 HEADSTAND", P10, function()
	loadstring(game:HttpGet("https://pastebin.com/raw/1zxuPzS4"))()
end)

btn("🍁 GAZE EMOTES", P10, function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/Gazer-Ha/Gaze-stuff/refs/heads/main/Gaze%20emote"))()
end)

--==================================================
-- P8 : SHIELD
--==================================================
btn("ALPHA SHIELD++ 🛡️", P8, function()
		
loadstring(game:HttpGet("https://pastebin.com/raw/0vvNWB3b"))() end)
btn("ULTRA ENGINE 🎛️", P8, function() loadstring(game:HttpGet("https://pastebin.com/raw/tdXfMj6y"))() end)
btn("BEST ANTI BANG 👺",P8,function()
	
loadstring(game:HttpGet("https://pastebin.com/raw/mZGPu2F4"))()end)


btn("AAYAN ANTI BANG 😈",P8,function()
	
loadstring(game:HttpGet("https://pastebin.com/raw/XFi5TrS9"))()end)

btn("👑 ANTI-VOID", P8, function(self)
	Config.AntiVoid = not Config.AntiVoid
	self.Text = "👑 ANTI-VOID: " .. (Config.AntiVoid and "ON" or "OFF")
end)

btn("🚫 ANTI-SIT", P8, function(self)
	Config.AntiSit = not Config.AntiSit
	self.Text = "🚫 ANTI-SIT: " .. (Config.AntiSit and "ON" or "OFF")
end)

btn("😴 ANTI-AFK", P8, function(self)
	Config.AntiAFK = not Config.AntiAFK
	self.Text = "😴 ANTI-AFK: " .. (Config.AntiAFK and "ON" or "OFF")
end)
btn("🔄 REVERSE FLING", P8, function() local hrp = player.Character.HumanoidRootPart; local s = Instance.new("BodyAngularVelocity", hrp); s.MaxTorque = Vector3.new(math.huge,math.huge,math.huge); s.AngularVelocity = Vector3.new(0,999999,0) end)
btn("🔥  ANTI-FLING", P8, function() for _,v in pairs(player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end)

-- ===== 10 MORE SHIELDS (protect only your own character) =====
local Sh = {
	ragdoll = false, freeze = false, knock = false, heal = false, nofall = false,
	attach = false, glue = false, spin = false, tpsnap = false, fx = false,
}
local shFxOff = {}
local function shToggle(label, key, onChange)
	btn(label .. ": OFF", P8, function(self)
		Sh[key] = not Sh[key]
		self.Text = label .. ": " .. (Sh[key] and "ON" or "OFF")
		if onChange then pcall(onChange, Sh[key]) end
	end)
end
shToggle("ANTI-RAGDOLL", "ragdoll", function(on)
	local h = getHum()
	if h then
		h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, not on)
		h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not on)
	end
end)
shToggle("ANTI-FREEZE", "freeze")
shToggle("ANTI-KNOCKBACK", "knock")
shToggle("AUTO HEAL", "heal")
shToggle("NO FALL DAMAGE", "nofall")
shToggle("ANTI-ATTACH", "attach")
shToggle("ANTI-GLUE HOP", "glue")
shToggle("ANTI-SPIN", "spin")
shToggle("ANTI-TELEPORT", "tpsnap")
shToggle("ANTI-SCREEN FX", "fx", function(on)
	if not on then
		for inst, was in pairs(shFxOff) do
			if inst.Parent then inst.Enabled = was end
		end
		table.clear(shFxOff)
	end
end)

do
	local rayP = RaycastParams.new()
	rayP.FilterType = Enum.RaycastFilterType.Exclude
	local lastPos, glueT, hopCool, scanT, fxT = nil, {}, 0, 0, 0
	table.insert(Cleanup, RunService.Heartbeat:Connect(function(dt)
		local char = player.Character
		local h = char and char:FindFirstChildOfClass("Humanoid")
		local r = char and char:FindFirstChild("HumanoidRootPart")
		if not (h and r) then lastPos = nil return end

		if Sh.ragdoll then
			h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			local st = h:GetState()
			if st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
				h:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end
		if Sh.freeze and r.Anchored then r.Anchored = false end
		if Sh.heal and h.Health > 0 and h.Health < h.MaxHealth then h.Health = h.MaxHealth end

		local v = r.AssemblyLinearVelocity
		if Sh.knock then
			local cap = math.max(h.WalkSpeed * 1.8, 45)
			local hv = Vector3.new(v.X, 0, v.Z)
			if hv.Magnitude > cap then
				local c = hv.Unit * cap
				r.AssemblyLinearVelocity = Vector3.new(c.X, v.Y, c.Z)
			elseif math.abs(v.Y) > 260 then
				r.AssemblyLinearVelocity = Vector3.new(v.X, math.sign(v.Y) * 260, v.Z)
			end
		end
		if Sh.nofall and v.Y < -80 then
			rayP.FilterDescendantsInstances = { char }
			local hit = workspace:Raycast(r.Position, Vector3.new(0, -14, 0), rayP)
			if hit then r.AssemblyLinearVelocity = Vector3.new(v.X, -25, v.Z) end
		end
		if Sh.spin and not Config.Spin then
			local av = r.AssemblyAngularVelocity
			if av.Magnitude > 40 then r.AssemblyAngularVelocity = Vector3.zero end
		end
		if Sh.tpsnap then
			if lastPos and (r.Position - lastPos).Magnitude > 120 and v.Magnitude < 300 then
				r.CFrame = CFrame.new(lastPos) * (r.CFrame - r.CFrame.Position)
				r.AssemblyLinearVelocity = Vector3.zero
			else
				lastPos = r.Position
			end
		else
			lastPos = r.Position
		end

		hopCool = math.max(0, hopCool - dt)
		if Sh.glue then
			for _, p in ipairs(Players:GetPlayers()) do
				local pr = p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if pr then
					local rel = r.CFrame:PointToObjectSpace(pr.Position)
					if rel.Magnitude < 4 and rel.Z > 0.2 and math.abs(rel.X) < 2.4 and math.abs(rel.Y) < 3.2 then
						glueT[p] = (glueT[p] or 0) + dt
						if glueT[p] > 0.8 and hopCool <= 0 then
							glueT[p] = 0
							hopCool = 2.5
							local d = r.CFrame.LookVector
							local t = r.Position + d * 38 + Vector3.new(0, 4, 0)
							char:PivotTo(CFrame.new(t, t + d))
							r.AssemblyLinearVelocity = Vector3.zero
							pcall(Config.notify, "GLUE HOP from " .. p.Name)
						end
					else
						glueT[p] = 0
					end
				end
			end
		end

		scanT = scanT + dt
		if Sh.attach and scanT > 0.4 then
			scanT = 0
			local function other(part)
				if not part then return nil end
				local m = part:FindFirstAncestorOfClass("Model")
				if m and m ~= char then
					local p = Players:GetPlayerFromCharacter(m)
					if p and p ~= player then return p end
				end
			end
			local function check(d)
				if d:IsA("JointInstance") or d:IsA("WeldConstraint") then
					local a, b = d.Part0, d.Part1
					local mineA = a and a:IsDescendantOf(char)
					local mineB = b and b:IsDescendantOf(char)
					if (mineA and other(b)) or (mineB and other(a)) then d:Destroy() return true end
				elseif d:IsA("Constraint") then
					local a0, a1 = d.Attachment0, d.Attachment1
					local pa, pb = a0 and a0.Parent, a1 and a1.Parent
					if pa and pb and ((pa:IsDescendantOf(char) and other(pb)) or (pb:IsDescendantOf(char) and other(pa))) then d:Destroy() return true end
				end
			end
			for _, d in ipairs(char:GetDescendants()) do check(d) end
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player and p.Character then
					for _, d in ipairs(p.Character:GetDescendants()) do
						if d:IsA("JointInstance") or d:IsA("WeldConstraint") or d:IsA("Constraint") then check(d) end
					end
				end
			end
		end

		fxT = fxT + dt
		if Sh.fx and fxT > 0.5 then
			fxT = 0
			local function sweep(parent)
				for _, e in ipairs(parent:GetChildren()) do
					if (e:IsA("BlurEffect") or e:IsA("DepthOfFieldEffect") or e:IsA("SunRaysEffect"))
						and e.Enabled and not e.Name:find("KINGS_V3") and not e.Name:find("AAYAN") then
						shFxOff[e] = true
						e.Enabled = false
					end
				end
			end
			sweep(Lighting)
			if workspace.CurrentCamera then sweep(workspace.CurrentCamera) end
		end
	end))
end

--==================================================
-- P11 : VOIDOUT
--==================================================
btn("FAKEOUT 1 🌚", P11, function() loadstring(game:HttpGet("https://pastebin.com/raw/67KEqzjv"))() end)

btn("FAKEOUT 2 🗿", P11, function() loadstring(game:HttpGet("https://pastebin.com/raw/meJYGz4a"))() end)

btn("FAKEOUT 3🤬", P11, function() loadstring(game:HttpGet("https://pastebin.com/raw/y8H6TqE6"))() end)

btn("ULTIMATE FAKEOUT 👺👀", P11, function() loadstring(game:HttpGet("https://pastebin.com/raw/X0ehhyKc"))() end)

btn("VOID FALLER 🕳️",P11,function()
	
loadstring(game:HttpGet("https://pastefy.app/m48WKxUJ/raw"))()end)

btn("SNAKE FAKEOUT 🐍",P11,function()
	
loadstring(game:HttpGet("https://pastebin.com/raw/6G05EvDE"))()end)
btn("FAKEOUT + ANTI BANG 😎",P11,function()
	
loadstring(game:HttpGet("https://pastebin.com/raw/bDSvuPb4"))()end)


btn("VOIDSTRIKER 🗿", P11, function() loadstring(game:HttpGet("https://pastebin.com/raw/c3R861CE"))() end)
btn("🪐 LOW GRAVITY", P11, function() workspace.Gravity = 15 end)
btn("🌌 ZERO GRAVITY", P11, function() workspace.Gravity = 0 end)
btn("🌍 NORMAL GRAVITY", P11, function() workspace.Gravity = 196.2 end)
btn("AURA GLOW 🌟", P11, function() loadstring(game:HttpGet("https://pastebin.com/raw/SEEgQyMg"))() end)
btn("PATROL👽", P11, function()
	loadstring(game:HttpGet("https://pastebin.com/raw/XhKJMEqj"))() end)

btn("PATROL V2 👽",P11,function()
	
loadstring(game:HttpGet("https://pastebin.com/raw/QZgf1Veu"))()end)

btn("VOID WALKER ✨👀",P11,function()
	
loadstring(game:HttpGet("https://pastefy.app/RdQmPLSO/raw"))()end)


btn("TELEPORTER V1 👾", P11, function() loadstring(game:HttpGet("https://pastebin.com/raw/EUSknnAF"))() end)

btn("TELEPORTER V2 👾", P11, function() loadstring(game:HttpGet("https://pastebin.com/raw/216FSAFS"))() end)

-- YOU WILL ADD HERE  (UNIVERSAL BANG 3F button)


--==================================================
-- P7 : DJ SYSTEM
--==================================================

btn("🎵 DJ PLAYER",P7,function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/Music-/refs/heads/main/Aayan_Music_System.lua"))()end)


btn("BACK BANG 🍑",P6,function()
local message = "SCRIPT BY " .. playerName
    .. " -----[ BACK BANG ]----- "
    .. "______//______BACK MODE ACTIVATED________//_________ 💀👽 "
    .. "MADE BY 👽👋🏼 " .. playerName
    .. " | BEST--BACK---BANG----LOADED ⚡🔥..."

local channel = game:GetService("TextChatService")
    :FindFirstChild("TextChannels")

channel = channel and channel:FindFirstChild("RBXGeneral")

if channel then
    pcall(function()
        channel:SendAsync(message)
    end)
		end
		
loadstring(game:HttpGet("https://pastebin.com/raw/0eFj3xPf"))()end)

btn("FACE BANG 👄",P6,function()

local message = "SCRIPT BY " .. playerName
    .. " -----[ FACE 👄 ]----- "
    .. "______//______REAR MODE ACTIVATED________//_________ 💀👽 "
    .. "MADE BY 👽👋🏼 " .. playerName
    .. " | BEST--FACE👄---BANG----LOADED ⚡🔥..."

local channel = game:GetService("TextChatService")
    :FindFirstChild("TextChannels")

channel = channel and channel:FindFirstChild("RBXGeneral")

if channel then
    pcall(function()
        channel:SendAsync(message)
    end)
		end
		
loadstring(game:HttpGet("https://pastefy.app/cVCW0R18/raw"))()end)

btn("BANGER 1💀", P6, function() 
local message = "SCRIPT BY " .. playerName
    .. " //----------\\-------//-----------\\ "
    .. "BEST-BANGER-IN-THE-WORLD 👽@@@@ "
    .. "TARGET BE LIKE: AB KYA KARU 😭😂~~~×~~~ "
    .. "MADE BY " .. playerName
    .. " V1 BANGER LOADED 💀..."

local channel = game:GetService("TextChatService")
    :FindFirstChild("TextChannels")

channel = channel and channel:FindFirstChild("RBXGeneral")

if channel then
    pcall(function()
        channel:SendAsync(message)
    end)
		end		
		
loadstring(game:HttpGet("https://pastebin.com/raw/rnZWws3z"))() end)

btn("BANGER 2💀", P6, function() 
local message = "SCRIPT BY " .. playerName
.. " \----------//----------\----------// "
.. "BANGER 2 💀"
.. "~~~~×~~~~"
.. "TARGET BE LIKE: AB TO MERI C ME 😭😂 "
.. "-+-+-+- "
.. "MADE BY " .. playerName
.. " | BANGER V2 LOADED 💀🔥..."

local channel = game:GetService("TextChatService")
:FindFirstChild("TextChannels")

channel = channel and channel:FindFirstChild("RBXGeneral")

if channel then
pcall(function()
channel:SendAsync(message)
end)
		end
		
loadstring(game:HttpGet("https://pastebin.com/raw/X73d41m6"))() end)
btn("BANGER 3 💀", P6, function() 
local message = "SCRIPT BY " .. playerName
    .. " \\----------//----------\\----------// "
    .. "BANGER V3../\ "
    .. ""
    .. "----//----"
    .. "TARGET BE LIKE: YE KYA AA GAYA 😭👽"
    .. "___"
    .. "MADE BY 🗿 " .. playerName
    .. " ~~~~BANGER 3 LOADED 🥶🔥..."

local channel = game:GetService("TextChatService")
    :FindFirstChild("TextChannels")

channel = channel and channel:FindFirstChild("RBXGeneral")

if channel then
    pcall(function()
        channel:SendAsync(message)
    end)
		end		
loadstring(game:HttpGet("https://pastebin.com/raw/TsLFDeKw"))() end)
btn("MULTI TARGET 💥🕷️ (0.1 delay)", P6, function() 
local message = "SCRIPT BY " .. playerName
    .. " ____//____MULTI TARGET BANGER 💀🔥____//____ "
    .. "~~~~~~~~~👽☠️ "
    .. "BEST MULTI TARGET BANG EVER 😈⚡ "
    .. "_____"
    .. ""
    .. "MADE BY " .. playerName
    .. "____MULTI BANGER LOADED 💥👀..."

local channel = game:GetService("TextChatService")
    :FindFirstChild("TextChannels")

channel = channel and channel:FindFirstChild("RBXGeneral")

if channel then
    pcall(function()
        channel:SendAsync(message)
    end)
		end		
		
loadstring(game:HttpGet("https://pastebin.com/raw/BHYtZjgL"))() end)
btn("0 DELAY BANG 💥🕷️", P6, function() 
	
		
loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/0-DELAY/refs/heads/main/AAYAN_GREEN_THEME.lua"))() end)


btn("VOICE BANG 🗣️", P6, function() 
local message = "SCRIPT BY " .. playerName
    .. " ____//____VOICE BANG  💀🔥____//____ "
    .. "~~~~~~~~~👽☠️ "
    .. "VOICE BANG LOADED AB AAYEGA MAJA 😝😈⚡ "
    .. "_____"
    .. ""
    .. "MADE BY " .. playerName
    .. "____VOICE BANGER LOADED 💥👀..."

local channel = game:GetService("TextChatService")
    :FindFirstChild("TextChannels")

channel = channel and channel:FindFirstChild("RBXGeneral")

if channel then
    pcall(function()
        channel:SendAsync(message)
    end)
		end		
		
loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/MUSIC-BANG-/refs/heads/main/gistfile1%20(1).txt"))() end)



btn("BANGER 4 🔥💢", P6, function() 
local message = "SCRIPT BY " .. playerName
    .. " _______//_______ B-A-N-G-E-R----V4 💀⚡ ______//_______ "
    .. "~~~~~×~~~~~MADE BY~~~~~×~~~~~" .. playerName
    .. " |---+---+---+---+---+---+ V4 LOADED 👽🔥..."

local channel = game:GetService("TextChatService")
    :FindFirstChild("TextChannels")

channel = channel and channel:FindFirstChild("RBXGeneral")

if channel then
    pcall(function()
        channel:SendAsync(message)
    end)
		end		
		
loadstring(game:HttpGet("https://pastebin.com/raw/EgVAYt7U"))() end)

btn("BANG R15 👽👺", P6, function() 
local message = "SCRIPT BY " .. playerName
    .. " ______X______ R15 BANG 👽⚡ ______X______ "
    .. "TARGET KI FADO AB 👋🏼💀___//___//___ BHAI AB TO GYA TU "
    .. "MADE BY~~~~~~×~~~~~~~×~~~~~~~ " .. playerName
    .. " | R15 LOADED |👀..."

local channel = game:GetService("TextChatService")
    :FindFirstChild("TextChannels")

channel = channel and channel:FindFirstChild("RBXGeneral")

if channel then
    pcall(function()
        channel:SendAsync(message)
    end)
		end	
		
loadstring(game:HttpGet("https://raw.githubusercontent.com/ririantiskid/troll/refs/heads/main/troll"))() end)


--==================================================
-- P14 : ALPHA EMPIRE
--==================================================

btn("ALPHA HISTORY 📜", P9, function() loadstring(game:HttpGet("https://pastefy.app/VlheRB4L/raw"))() end)
btn("JOIN EMPIRE ⛩️", P9, function() loadstring(game:HttpGet("https://pastefy.app/62LGo4kD/raw"))() end)
btn("ALPHA CASTLE 🏰", P9, function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/Castle-v3/main/CASTLE_OF_MAXU-4.lua"))() end)
btn("AMUSEMENT PARK 🎢", P9, function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/AMUSEMENT-PARK-/refs/heads/main/MAXU_AMUSEMENT_PARK-1.lua"))() end)
btn("POOKIE PARK 🎀🏞️", P9, function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/Pookie-park-/refs/heads/main/POOKIE_PARK.lua"))() end)

--==================================================
-- P12 : MINI GAMES
--==================================================

btn("TIC TAC TOE 🎮", P12, function() 
		
loadstring(game:HttpGet("https://pastebin.com/raw/r4DyGkWT"))() end)

btn("JET DEFENDER ✈️", P12, function() 
	
loadstring(game:HttpGet("https://pastebin.com/raw/KEjtCtpP"))() end)

btn("CANDY BOM 💥", P12, function()
	
loadstring(game:HttpGet("https://pastebin.com/raw/tTCmn7FS"))() end)

btn("FLAPPY BIRD 🐦", P12, function()

loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/FLAPPY-BIRD-/main/AAYAN_V3_FLAPPY_BIRD.lua"))() end)

btn("CANDY CRUSH 🍭", P12, function()

loadstring(game:HttpGet("https://pastebin.com/raw/DU4rLjrK"))() end)

btn("BALL BOUNCE ⚽", P12, function() 
		
loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/Aayann/main/Alpha_Boat_Bounce_V1.lua"))() end)

btn("MEMORY CARD 🟨", P12, function() 
		
loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/MEMORY-GAME-/refs/heads/main/Aayan_Memory.lua"))() end)

btn("REACTION MASTER 🔴", P12, function() 
		
loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/Reaction-/refs/heads/main/Aayan_Reaction_Master.lua"))() end)

btn("BLOCK BLAST 💠", P12, function() 
		
loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/Block-blast/refs/heads/main/Aayan_Block_Blast.lua"))() end)

btn("FEED THE SNAKE 🐍", P12, function() 
		
loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/Snake-master-/refs/heads/main/Aayan_Snake_Master.lua"))() end)

btn("CIRCUIT MASTER ⚡", P12, function() 
		
loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/Circuit-/refs/heads/main/Aayan_Circuit_Connect.lua"))() end)




--==================================================
-- P2 : OWNER
--==================================================

local info = Instance.new("TextLabel", P2)

info.Name = "CreditsInfo"
info.Size = UDim2.new(1, -10, 1, 0)
info.Position = UDim2.new(0, 5, 0, 0)
info.BackgroundTransparency = 1
info.TextSize = 15
info.Font = Enum.Font.GothamBold
info.TextWrapped = true
info.TextYAlignment = Enum.TextYAlignment.Top
info.TextXAlignment = Enum.TextXAlignment.Center
info.RichText = true
info.TextColor3 = Color3.fromRGB(220, 235, 255)

info.Text = [[
<font face="GothamBlack" color="#FFD700" size="20">👑</font> <font face="FredokaOne" color="#FFD700" size="20">OWNER</font> <font face="Bangers" color="#FFD700" size="20">👑</font>
<font face="LuckiestGuy" color="#FFF2B0" size="22">AAYAN</font> <font face="Oswald" color="#FFF2B0" size="22">🗿⛩️</font>
<font face="Michroma" color="#FFE27A">SNAP</font> <font face="PermanentMarker" color="#FFE27A">-</font> <font face="Jura" color="#FFE27A">aayanzz123</font>
<font face="Sarpanch" color="#FFE27A">ROBLOX</font> <font face="Nunito" color="#FFE27A">-</font> <font face="DenkOne" color="#FFE27A">AAYAN_ZZZZ</font>

<font face="TitilliumWeb" color="#B77BFF" size="19">♛</font> <font face="SpecialElite" color="#B77BFF" size="19">2ND</font> <font face="Ubuntu" color="#B77BFF" size="19">OWNER</font> <font face="GothamBlack" color="#B77BFF" size="19">♛</font>
<font face="FredokaOne" color="#E4D0FF" size="21">AE_MAX</font> <font face="Bangers" color="#E4D0FF" size="21">💎</font>
<font face="LuckiestGuy" color="#CFA8FF">SNAP</font> <font face="Oswald" color="#CFA8FF">-</font> <font face="Michroma" color="#CFA8FF">snapuser78432</font>
<font face="PermanentMarker" color="#CFA8FF">ROBLOX</font> <font face="Jura" color="#CFA8FF">ID</font> <font face="Sarpanch" color="#CFA8FF">-</font> <font face="Nunito" color="#CFA8FF">mr_king7809</font>

<font face="DenkOne" color="#3DD9FF" size="18">✦</font> <font face="TitilliumWeb" color="#3DD9FF" size="18">.</font> <font face="SpecialElite" color="#3DD9FF" size="18">CREDIT</font> <font face="Ubuntu" color="#3DD9FF" size="18">✦</font>
<font face="GothamBlack" color="#C4F5FF" size="20">REHAN</font> <font face="FredokaOne" color="#C4F5FF" size="20">SARKAR</font> <font face="Bangers" color="#C4F5FF" size="20">⚡</font>
<font face="LuckiestGuy" color="#7FE7FF">SNAP</font> <font face="Oswald" color="#7FE7FF">-</font> <font face="Michroma" color="#7FE7FF">mirza001856</font>
<font face="PermanentMarker" color="#7FE7FF">ROBLOX</font> <font face="Jura" color="#7FE7FF">ID</font> <font face="Sarpanch" color="#7FE7FF">-</font> <font face="Nunito" color="#7FE7FF">Rehan_mirzaa</font>

<font face="DenkOne" color="#6B5C99">━━━━━━━━━━━━━━━━━━</font>
<font face="TitilliumWeb" color="#FF8AD8" size="14">♣</font> <font face="SpecialElite" color="#FF8AD8" size="14">THANK</font> <font face="Ubuntu" color="#FF8AD8" size="14">YOU</font> <font face="GothamBlack" color="#FF8AD8" size="14">FOR</font> <font face="FredokaOne" color="#FF8AD8" size="14">USING</font> <font face="Bangers" color="#FF8AD8" size="14">AAYAN</font> <font face="LuckiestGuy" color="#FF8AD8" size="14">V3</font> <font face="Oswald" color="#FF8AD8" size="14">♠</font>
]]

--==================================================
-- P9 : NOTE
--==================================================
local InfoFrame = Instance.new("Frame", P14)
InfoFrame.Size = UDim2.new(1,0,1,0)
InfoFrame.BackgroundTransparency = 1

local function AddInfoText(Text, Color, Size, Bold)
	local Label = Instance.new("TextLabel")
	Label.Parent = InfoFrame
	Label.Size = UDim2.new(1,-10,0,Size)
	Label.BackgroundTransparency = 1
	Label.Text = Text
	Label.TextColor3 = Color
	Label.TextSize = 15
	Label.Font = Bold and Enum.Font.GothamBold or Enum.Font.Gotham
	Label.TextWrapped = true
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.TextYAlignment = Enum.TextYAlignment.Center
	return Label
end

local Cyan = Color3.fromRGB(0,255,255)
local Purple = Color3.fromRGB(190,70,255)
local Red = Color3.fromRGB(255,70,90)
local White = Color3.fromRGB(240,240,245)

-- MAIN TITLE
local InfoTitle = AddInfoText(
	"👽🎀 WELCOME TO AAYAN V3 🎀👽",
	Cyan,
	32,
	true
)
InfoTitle.Position = UDim2.new(0,5,0,5)

-- SUBTITLE
local InfoSub = AddInfoText(
	"💜 YOUR HUB • ALWAYS EVOLVING 💜",
	Purple,
	26,
	true
)
InfoSub.Position = UDim2.new(0,5,0,38)

-- NOTE TITLE
local NoteTitle = AddInfoText(
	"📢 IMPORTANT NOTE",
	Red,
	25,
	true
)
NoteTitle.Position = UDim2.new(0,5,0,72)

-- NOTE MESSAGE
local NoteMessage = AddInfoText(
    "So, this is my hub, and I'll keep updating it with new features! 🚀 If you face any bugs or problems, please let me know so I can fix them and make the hub even better luv u all ALPHA EMPIRE ⛩️ members 🫠 and all Thanks for supporting AAYAN V3! 👽💜",
    White,
    100,
    false
)
NoteMessage.Position = UDim2.new(0,5,0,103)
NoteMessage.TextSize = 14
NoteMessage.TextYAlignment = Enum.TextYAlignment.Top

local ThanksMessage = AddInfoText(
    "AND THANKS TO MAXU (AE_MAX( AGAR TU NA HOTA TO AJJ MAI YAHAN NHI HOTA BHAI THANK YOU 💗 FOR SUPPORTING ME IN EVERY SITUATION 🎀🤧",
    Color3.fromRGB(180,100,255),
    100,
    false
)
ThanksMessage.Position = UDim2.new(0,5,0,190)
ThanksMessage.TextSize = 14
ThanksMessage.TextYAlignment = Enum.TextYAlignment.Top





btn("AAYAN ADMIN 🔲", P3, function()
		
loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/AAYAN-ADMIN-PROTECT-/main/obfuscated.lua%20(8).txt"))() end)

btn("CLAUDE AI (AE) 🤖", P3, function()
		
loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/Aayan-/refs/heads/main/AURA%20AI.lua"))() end)

btn("SCRIPT SEARCH 🔍", P3, function()
		
loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/Script-/main/AAYAN_IS_KING.lua"))() end)

btn("3F STALKER 🌱", P3, function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Universal-Script-3Fs-236312"))() end)


btn("UTILITY ☠️", P3, function()
		
loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/AAYAN-utility-/refs/heads/main/AAYAN_V1_UTILITY.lua"))() end)

btn("INFINITE YEILD 🔲", P3, function() 

loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end)

btn("ULTIMATE ADMIN 🔲", P3, function()
		
loadstring(game:HttpGet("https://raw.githubusercontent.com/Veaquach/kruel/refs/heads/main/kruel%20obf.txt"))() end)


--==================================================
-- P13 : SPECIAL
--==================================================

btn("EXECUTOR 😾", P13, function() 
		
loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/Zz-EXECUTOR-/refs/heads/main/executor.lua"))() end)
btn("AAYAN EMOTE (BEST) ", P13, function() 
		
loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/AAYAN-EMOTE-/refs/heads/main/AAYAN_EMOTE.lua"))() end)


btn("SPECIAL MODES 😋 ", P13, function() 
		
loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/Modes-/main/ALPHA_MODES_S.lua"))() end)

btn("FOV VIEW 👁️ ", P13, function() loadstring(game:HttpGet("https://pastefy.app/wBDTCnNa/raw"))() end)

btn("DRONE CONTROLLER 🚁", P13, function() loadstring(game:HttpGet("https://pastebin.com/raw/0Uc7CA86"))() end)

btn("AURA GLITCH 🎭", P13, function() loadstring(game:HttpGet("https://pastebin.com/raw/Uq7htgyG"))() end)

btn("OUTFIT REVELER V3😈", P13, function() 
		
loadstring(game:HttpGet("https://raw.githubusercontent.com/ahmadaayan400-creator/Reveal-/main/AAYAN%20OUTFIT%20V4.lua"))() end)

btn("🦖 Giant Mode", P13, function() if player.Character and player.Character:FindFirstChild("Humanoid") then for _, scale in pairs({"BodyHeightScale", "BodyWidthScale", "BodyDepthScale", "HeadScale"}) do local obj = player.Character.Humanoid:FindFirstChild(scale); if obj then obj.Value = 2.5 end end end end, false)

btn("FAKE CHAT ☠️", P13, function() loadstring(game:HttpGet("https://pastebin.com/raw/96AH9Dcr"))() end)

btn("TRAIL 🏳️‍🌈", P13, function() loadstring(game:HttpGet("https://pastebin.com/raw/xhXTB61N"))() end)

btn("AUTO CLICKER ↗️", P13, function() loadstring(game:HttpGet("https://pastebin.com/raw/4b3HeU6Q"))() end)

--==================================================
-- P1 : INFO TAB
--==================================================

do
	-- avatar + welcome section
	local header = Instance.new("Frame", P1)
	header.Size = UDim2.new(1, -10, 0, 150)
	header.BackgroundTransparency = 1
	header.ZIndex = 12

	local ring = Instance.new("Frame", header)
	ring.AnchorPoint = Vector2.new(0.5, 0)
	ring.Position = UDim2.new(0.5, 0, 0, 4)
	ring.Size = UDim2.new(0, 84, 0, 84)
	ring.BackgroundColor3 = Color3.fromRGB(16, 30, 80)
	ring.BorderSizePixel = 0
	ring.ZIndex = 13
	Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
	local _, ringGrad = borderStroke(ring, 3, 0)

	local av = Instance.new("ImageLabel", ring)
	av.AnchorPoint = Vector2.new(0.5, 0.5)
	av.Position = UDim2.new(0.5, 0, 0.5, 0)
	av.Size = UDim2.new(1, -10, 1, -10)
	av.BackgroundTransparency = 1
	av.Image = avatarImage
	av.ScaleType = Enum.ScaleType.Crop
	av.ZIndex = 14
	Instance.new("UICorner", av).CornerRadius = UDim.new(1, 0)

	local welcome = Instance.new("TextLabel", header)
	welcome.Position = UDim2.new(0, 0, 0, 94)
	welcome.Size = UDim2.new(1, 0, 0, 28)
	welcome.BackgroundTransparency = 1
	welcome.Text = "WELCOME, " .. player.Name
	welcome.TextColor3 = Theme.Text
	welcome.Font = Enum.Font.GothamBlack
	welcome.TextScaled = true
	welcome.ZIndex = 13
	local wLimit = Instance.new("UITextSizeConstraint", welcome)
	wLimit.MaxTextSize = 18
	wLimit.MinTextSize = 10

	local display = Instance.new("TextLabel", header)
	display.Position = UDim2.new(0, 0, 0, 124)
	display.Size = UDim2.new(1, 0, 0, 18)
	display.BackgroundTransparency = 1
	display.Text = "Display name: " .. player.DisplayName
	display.TextColor3 = Theme.Muted
	display.Font = Enum.Font.Gotham
	display.TextSize = 12
	display.ZIndex = 13

	table.insert(Hooks, function(t, dt)
		-- only animate while the INFO page is actually visible
		if P1.Visible and Main.Visible then
			ringGrad.Rotation = (ringGrad.Rotation + 120 * dt) % 360
		end
	end)

	-- info cards
	local function makeCard(iconText, labelText)
		local card = Instance.new("Frame", P1)
		card.Size = UDim2.new(1, -10, 0, 46)
		card.BackgroundColor3 = Theme._card
		card.BackgroundTransparency = 0.05
		card.BorderSizePixel = 0
		card.ZIndex = 12
		regCorner(card, 10)
		borderStroke(card, 1.2, 0.25)
		table.insert(Reg.cards, card)

		local icon = Instance.new("TextLabel", card)
		icon.Position = UDim2.new(0, 8, 0, 0)
		icon.Size = UDim2.new(0, 30, 1, 0)
		icon.BackgroundTransparency = 1
		icon.Text = iconText
		icon.TextSize = 20
		icon.TextColor3 = Theme.Text
		icon.Font = Enum.Font.GothamBold
		icon.ZIndex = 13

		local label = Instance.new("TextLabel", card)
		label.Position = UDim2.new(0, 44, 0, 5)
		label.Size = UDim2.new(1, -52, 0, 14)
		label.BackgroundTransparency = 1
		label.Text = labelText
		label.TextColor3 = Theme.Muted
		label.Font = Enum.Font.GothamBold
		label.TextSize = 11
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 13

		local value = Instance.new("TextLabel", card)
		value.Position = UDim2.new(0, 44, 0, 21)
		value.Size = UDim2.new(1, -52, 0, 20)
		value.BackgroundTransparency = 1
		value.Text = "..."
		value.TextColor3 = Theme.Text
		value.Font = Enum.Font.GothamBold
		value.TextSize = 15
		value.TextXAlignment = Enum.TextXAlignment.Left
		value.TextTruncate = Enum.TextTruncate.AtEnd
		value.ZIndex = 13

		return value
	end

	local fpsValue = makeCard("⚡", "FPS")
	local pingValue = makeCard("📶", "PING (LATENCY)")
	local speedValue = makeCard("🌐", "NETWORK SPEED")
	local timeValue = makeCard("🕒", "LOCAL TIME")
	local dayValue = makeCard("📅", "DAY")
	local dateValue = makeCard("🗓️", "DATE")

	-- Roblox LocalScripts cannot measure real download/upload throughput
	speedValue.Text = "N/A (not measurable in Roblox)"
	speedValue.TextSize = 12
	speedValue.TextColor3 = Theme.Muted

	-- FPS counter: one lightweight Heartbeat connection, labels refreshed once per second
	local frames = 0
	table.insert(Cleanup, RunService.Heartbeat:Connect(function()
		frames += 1
	end))

	local function readPing()
		local ok, val = pcall(function()
			return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
		end)
		if ok and typeof(val) == "number" then
			return math.floor(val + 0.5)
		end
		return nil
	end

	local function refresh(fps)
		if fps then
			fpsValue.Text = tostring(fps) .. " FPS"
			if fps >= 50 then
				fpsValue.TextColor3 = Color3.fromRGB(80, 255, 150)
			elseif fps >= 30 then
				fpsValue.TextColor3 = Color3.fromRGB(255, 200, 70)
			else
				fpsValue.TextColor3 = Color3.fromRGB(255, 90, 90)
			end
		end

		local ping = readPing()
		pingValue.Text = ping and (tostring(ping) .. " ms") or "N/A"

		timeValue.Text = os.date("%I:%M:%S %p")
		dayValue.Text = os.date("%A")
		dateValue.Text = os.date("%d %B %Y")
	end

	refresh(nil)

	-- refresh immediately when the INFO page becomes visible
	P1:GetPropertyChangedSignal("Visible"):Connect(function()
		if P1.Visible then refresh(nil) end
	end)

	task.spawn(function()
		local last = os.clock()
		while sg.Parent do
			task.wait(1)
			local now = os.clock()
			local dt = now - last
			last = now
			local fps = math.floor(frames / math.max(dt, 0.001) + 0.5)
			frames = 0

			if Main.Visible and P1.Visible then
				refresh(fps)
			end
		end
	end)
end

--==================================================
-- DANGER TOGGLE BUTTON
--==================================================

local ToggleBtn = Instance.new("ImageButton")
ToggleBtn:SetAttribute("ClickHooked", true) -- its click sound is played below (drag-safe)
ToggleBtn.Parent = sg

ToggleBtn.Name = "ToggleButton"
ToggleBtn.Size = UDim2.new(0,70,0,70)
ToggleBtn.Position = UDim2.new(0,18,0.5,12)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(26,0,0)
ToggleBtn.BackgroundTransparency = 0.05
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Image = avatarImage
ToggleBtn.ImageTransparency = 0
task.spawn(function()
	task.wait(3)
	if ToggleBtn.Parent and not ToggleBtn.IsLoaded then
		local alt = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
		if ToggleBtn.Image == alt then
			alt = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"
		end
		ToggleBtn.Image = alt
	end
end)
ToggleBtn.ScaleType = Enum.ScaleType.Crop
ToggleBtn.Visible = true
ToggleBtn.ZIndex = 200
ToggleBtn.Active = true
ToggleBtn.AutoButtonColor = false

Instance.new("UICorner",ToggleBtn).CornerRadius = UDim.new(1,0)

local ToggleStroke = Instance.new("UIStroke",ToggleBtn)
ToggleStroke.Thickness = 3
ToggleStroke.Color = Theme.A1
ToggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local ToggleScale = Instance.new("UIScale", ToggleBtn)

-- premium outer ring: slowly rotating accent gradient
do
	local glow = Instance.new("Frame", ToggleBtn)
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.new(0.5, 0, 0.5, 0)
	glow.Size = UDim2.new(1, 14, 1, 14)
	glow.BackgroundTransparency = 1
	glow.BorderSizePixel = 0
	glow.ZIndex = 198
	Instance.new("UICorner", glow).CornerRadius = UDim.new(1, 0)
	local _, glowGrad = borderStroke(glow, 2.5, 0.35)
	table.insert(Hooks, function(t, dt)
		glowGrad.Rotation = (glowGrad.Rotation + 140 * dt) % 360
	end)
end

local ToggleRings = {}
-- danger ripple rings
for i = 1, 2 do
	local dr = Instance.new("Frame", ToggleBtn)
	dr.AnchorPoint = Vector2.new(0.5, 0.5)
	dr.Position = UDim2.new(0.5, 0, 0.5, 0)
	dr.Size = UDim2.new(1, 0, 1, 0)
	dr.BackgroundTransparency = 1
	dr.BorderSizePixel = 0
	dr.ZIndex = 199
	Instance.new("UICorner", dr).CornerRadius = UDim.new(1, 0)
	local drs = Instance.new("UIStroke", dr)
	ToggleRings[i] = drs
	drs.Thickness = 2
	drs.Color = Color3.fromRGB(255, 40, 40)
	drs.Transparency = 0.2
	drs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local dinfo = TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1, false, (i - 1) * 0.9)
	TweenService:Create(dr, dinfo, { Size = UDim2.new(1, 44, 1, 44) }):Play()
	TweenService:Create(drs, dinfo, { Transparency = 1 }):Play()
end

-- skull badge
local Badge = Instance.new("TextLabel", ToggleBtn)
Badge.AnchorPoint = Vector2.new(0.5, 0.5)
Badge.Position = UDim2.new(0.86, 0, 0.14, 0)
Badge.Size = UDim2.new(0, 26, 0, 26)
Badge.BackgroundColor3 = Color3.fromRGB(10, 0, 0)
Badge.Text = "V3"
Badge.TextColor3 = Color3.fromRGB(255, 60, 60)
Badge.TextSize = 10
Badge.Font = Enum.Font.GothamBlack
Badge.ZIndex = 202
Instance.new("UICorner", Badge).CornerRadius = UDim.new(1, 0)
local BadgeStroke = Instance.new("UIStroke", Badge)
BadgeStroke.Color = Color3.fromRGB(255, 40, 40)
BadgeStroke.Thickness = 1.5
BadgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- danger caption
local Caption = Instance.new("TextLabel", ToggleBtn)
Caption.AnchorPoint = Vector2.new(0.5, 0)
Caption.Position = UDim2.new(0.5, 0, 1, 9)
Caption.Size = UDim2.new(0, 90, 0, 17)
Caption.BackgroundColor3 = Color3.fromRGB(8, 8, 20)
Caption.BackgroundTransparency = 0.1
Instance.new("UICorner", Caption).CornerRadius = UDim.new(1, 0)
borderStroke(Caption, 1.4, 0.2)
Caption.Text = "AAYAN V3"
Caption.TextColor3 = Color3.fromRGB(255, 50, 50)
Caption.Font = Enum.Font.GothamBlack
Caption.TextSize = 10
Caption.TextStrokeTransparency = 0.3
Caption.TextStrokeColor3 = Color3.new(0, 0, 0)
Caption.ZIndex = 202

-- the toggle follows the selected theme
local function themeToggle()
	ToggleBtn.BackgroundColor3 = shade(0.14)
	Badge.BackgroundColor3 = shade(0.08)
	Badge.TextColor3 = Theme.A1
	Caption.TextColor3 = Theme.A1
	Caption.BackgroundColor3 = shade(0.08)
	Caption.Text = "✦ " .. string.upper(string.sub(playerName, 1, 12)) .. " ✦"
	for _, r in ipairs(ToggleRings) do
		r.Color = Theme.A1
	end
end
table.insert(Reg.accentFns, themeToggle)
themeToggle()

ToggleBtn.MouseEnter:Connect(function()
	tween(ToggleScale, 0.15, { Scale = 1.1 })
end)
ToggleBtn.MouseLeave:Connect(function()
	tween(ToggleScale, 0.15, { Scale = 1 })
end)
ToggleBtn.MouseButton1Down:Connect(function()
	tween(ToggleScale, 0.08, { Scale = 0.92 })
end)
ToggleBtn.MouseButton1Up:Connect(function()
	tween(ToggleScale, 0.12, { Scale = 1.1 })
end)

makeDraggable(ToggleBtn)

--==================================================
-- OPEN / CLOSE ANIMATION
--==================================================

local function setMain(open)
	mainOpen = open

	for _, t in ipairs(mainTweens) do
		t:Cancel()
	end
	table.clear(mainTweens)

	local base = baseScale()

	if open then
		if not Main.Visible then
			Main.GroupTransparency = 1
			MainScale.Scale = base * 0.9
			Main.Visible = true
		end

		table.insert(mainTweens, tween(Main, 0.3, { GroupTransparency = 0 }))
		table.insert(mainTweens, tween(MainScale, 0.35, { Scale = base }, Enum.EasingStyle.Back))
	else
		table.insert(mainTweens, tween(Main, 0.22, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
		local closing = tween(MainScale, 0.22, { Scale = base * 0.9 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		table.insert(mainTweens, closing)

		closing.Completed:Connect(function(state)
			if state == Enum.PlaybackState.Completed and not mainOpen then
				Main.Visible = false
			end
		end)
	end
end

-- keep the GUI sized correctly if the screen size changes
do
	local cam = workspace.CurrentCamera
	if cam then
		table.insert(Cleanup, cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if mainOpen and #mainTweens > 0 then
				MainScale.Scale = baseScale()
			end
		end))
	end
end

-- ignore toggle clicks that were really drags
local toggleDownPos = nil

ToggleBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		toggleDownPos = ToggleBtn.AbsolutePosition
	end
end)

ToggleBtn.Activated:Connect(function()
	if toggleDownPos and (ToggleBtn.AbsolutePosition - toggleDownPos).Magnitude > 6 then
		return
	end
	playClick()
	setMain(not mainOpen)
end)

--==================================================
-- OVERHEAD TAG: avatar + username + AAYAN V3 (shown after the setup is finished)
-- It is a client-side BillboardGui, so only YOU can see it.
--==================================================

local tagOn = false
local setTag

do
	local oldTag = PlayerGui:FindFirstChild("AAYAN_TAG")
	if oldTag then oldTag:Destroy() end

	local bb = Instance.new("BillboardGui")
	bb.Name = "AAYAN_TAG"
	bb.Size = UDim2.new(0, 180, 0, 48)
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.ResetOnSpawn = false
	bb.Enabled = false
	bb.Parent = PlayerGui

	table.insert(Cleanup, {
		Disconnect = function()
			bb:Destroy()
		end
	})

	local group = Instance.new("CanvasGroup", bb)
	group.Size = UDim2.new(1, 0, 1, 0)
	group.BackgroundTransparency = 1
	group.GroupTransparency = 1
	local groupScale = Instance.new("UIScale", group)
	groupScale.Scale = 0.6

	local card = Instance.new("Frame", group)
	card.Position = UDim2.new(0, 3, 0, 3)
	card.Size = UDim2.new(1, -6, 1, -6)
	card.BackgroundColor3 = Theme._card
	card.BackgroundTransparency = 0.06
	card.BorderSizePixel = 0
	regCorner(card, 13)
	table.insert(Reg.cards, card)
	local _, cardGrad = borderStroke(card, 2, 0)

	-- soft gloss on the upper half
	local gloss = Instance.new("Frame", card)
	gloss.Size = UDim2.new(1, 0, 0.5, 0)
	gloss.BackgroundColor3 = Color3.new(1, 1, 1)
	gloss.BackgroundTransparency = 0.92
	gloss.BorderSizePixel = 0
	Instance.new("UICorner", gloss).CornerRadius = UDim.new(0, 12)

	local ring = Instance.new("Frame", card)
	ring.AnchorPoint = Vector2.new(0, 0.5)
	ring.Position = UDim2.new(0, 6, 0.5, 0)
	ring.Size = UDim2.new(0, 34, 0, 34)
	ring.BackgroundColor3 = Color3.fromRGB(12, 14, 34)
	ring.BorderSizePixel = 0
	Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
	borderStroke(ring, 2, 0)

	local face = Instance.new("ImageLabel", ring)
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.new(0.5, 0, 0.5, 0)
	face.Size = UDim2.new(1, -5, 1, -5)
	face.BackgroundTransparency = 1
	face.Image = avatarImage
	face.ScaleType = Enum.ScaleType.Crop
	Instance.new("UICorner", face).CornerRadius = UDim.new(1, 0)

	local nameL = Instance.new("TextLabel", card)
	nameL.BackgroundTransparency = 1
	nameL.Position = UDim2.new(0, 46, 0, 5)
	nameL.Size = UDim2.new(1, -52, 0, 17)
	nameL.Text = player.Name
	nameL.TextColor3 = Theme.Text
	nameL.Font = Enum.Font.GothamBold
	nameL.TextSize = 13
	nameL.TextXAlignment = Enum.TextXAlignment.Left
	nameL.TextTruncate = Enum.TextTruncate.AtEnd

	local brandL = Instance.new("TextLabel", card)
	brandL.BackgroundTransparency = 1
	brandL.Position = UDim2.new(0, 46, 0, 22)
	brandL.Size = UDim2.new(1, -52, 0, 16)
	brandL.Text = "AAYAN V3"
	brandL.TextColor3 = Color3.new(1, 1, 1)
	brandL.Font = Enum.Font.GothamBlack
	brandL.TextSize = 12
	brandL.TextXAlignment = Enum.TextXAlignment.Left
	table.insert(Reg.grads, addGradient(brandL, Theme.A1, Theme.A2, 0))

	local function attach()
		local character = player.Character
		if not character then return end
		local head = character:FindFirstChild("Head") or character:WaitForChild("Head", 8)
		if head then
			bb.Adornee = head
		end
	end
	table.insert(Cleanup, player.CharacterAdded:Connect(function()
		task.spawn(attach)
	end))
	task.spawn(attach)

	local tagTweens = {}
	function setTag(on)
		tagOn = on
		for _, t in ipairs(tagTweens) do t:Cancel() end
		table.clear(tagTweens)

		if on then
			bb.Enabled = true
			if not bb.Adornee then task.spawn(attach) end
			table.insert(tagTweens, tween(group, 0.35, { GroupTransparency = 0 }))
			table.insert(tagTweens, tween(groupScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back))
		else
			table.insert(tagTweens, tween(group, 0.2, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
			local closing = tween(groupScale, 0.2, { Scale = 0.6 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			table.insert(tagTweens, closing)
			closing.Completed:Connect(function(state)
				if state == Enum.PlaybackState.Completed and not tagOn then
					bb.Enabled = false
				end
			end)
		end
	end

	table.insert(Hooks, function(t, dt)
		if tagOn then
			cardGrad.Rotation = (cardGrad.Rotation + 100 * dt) % 360
		end
	end)
end


--==================================================
-- GAME CARD (top right, fixed): game logo + name
--==================================================

do
	local gc = Instance.new("Frame", sg)
	gc.Name = "GameCard"
	-- fixed spot: top right, just under the music bar (not draggable)
	gc.AnchorPoint = Vector2.new(1, 0)
	gc.Position = UDim2.new(1, -58, 0, 58)
	gc.Size = UDim2.new(0, 240, 0, 56)
	gc.BackgroundColor3 = Theme._card
	gc.BackgroundTransparency = 0.05
	gc.BorderSizePixel = 0
	gc.ZIndex = 110
	regCorner(gc, 14)
	borderStroke(gc, 1.8, 0)
	table.insert(Reg.cards, gc)

	local gs = Instance.new("UIScale", gc)
	local function fit()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local v = cam.ViewportSize
		gs.Scale = math.clamp(math.min(v.X / 700, v.Y / 380), 0.6, 1)
	end
	fit()
	if workspace.CurrentCamera then
		table.insert(Cleanup, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit))
	end

	local logo = Instance.new("ImageLabel", gc)
	logo.Position = UDim2.new(0, 8, 0.5, -20)
	logo.Size = UDim2.new(0, 40, 0, 40)
	logo.BackgroundColor3 = Theme._n
	logo.BorderSizePixel = 0
	logo.Image = "rbxthumb://type=GameIcon&id=" .. tostring(game.GameId) .. "&w=150&h=150"
	logo.ScaleType = Enum.ScaleType.Crop
	logo.ZIndex = 112
	Instance.new("UICorner", logo).CornerRadius = UDim.new(0, 10)
	local ls = Instance.new("UIStroke", logo)
	ls.Thickness = 1.6
	ls.Color = Color3.new(1, 1, 1)
	ls.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	table.insert(Reg.grads, addGradient(ls, Theme.A1, Theme.A2, 45))

	local cap = Instance.new("TextLabel", gc)
	cap.Position = UDim2.new(0, 58, 0, 7)
	cap.Size = UDim2.new(1, -66, 0, 12)
	cap.BackgroundTransparency = 1
	cap.Text = "NOW PLAYING"
	cap.TextColor3 = Theme.Muted
	cap.Font = Enum.Font.GothamBold
	cap.TextSize = 10
	cap.TextXAlignment = Enum.TextXAlignment.Left
	cap.ZIndex = 112

	local gname = Instance.new("TextLabel", gc)
	gname.Position = UDim2.new(0, 58, 0, 20)
	gname.Size = UDim2.new(1, -66, 0, 30)
	gname.BackgroundTransparency = 1
	gname.Text = game.Name
	gname.TextColor3 = Theme.Text
	gname.Font = Enum.Font.GothamBlack
	gname.TextSize = 13
	gname.TextWrapped = true
	gname.TextXAlignment = Enum.TextXAlignment.Left
	gname.TextYAlignment = Enum.TextYAlignment.Top
	gname.TextTruncate = Enum.TextTruncate.AtEnd
	gname.ZIndex = 112
	table.insert(Reg.texts, gname)


	task.spawn(function()
		local ok, res = pcall(function()
			return MarketplaceService:GetProductInfo(game.PlaceId)
		end)
		if ok and res and res.Name and res.Name ~= "" then
			gname.Text = res.Name
		end
	end)
end

--==================================================
-- SOUND SYSTEM (top bar) + CUSTOMIZER PANEL (cog button)
--==================================================

do
	local music = Instance.new("Sound")
	music.Name = "AAYAN_V4_MUSIC"
	music.SoundId = "" -- set to the local Luz Roja audio asset below
	music.Volume = Theme.Volume
	music.Looped = true
	music.Parent = SoundService

	table.insert(Cleanup, {
		Disconnect = function()
			music:Destroy()
		end
	})

	-- top bar
	local bar = Instance.new("Frame", sg)
	bar.Name = "SoundBar"
	-- top RIGHT corner of the screen
	bar.AnchorPoint = Vector2.new(1, 0)
	bar.Position = UDim2.new(1, -10, 0, -70)
	bar.Size = UDim2.new(0, 372, 0, 46)
	bar.BackgroundColor3 = Theme._card
	bar.BackgroundTransparency = 0.05
	bar.BorderSizePixel = 0
	bar.ZIndex = 120
	regCorner(bar, 14)
	borderStroke(bar, 1.8, 0)
	table.insert(Reg.cards, bar)

	local barScale = Instance.new("UIScale", bar)
	local function updateBarScale()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local v = cam.ViewportSize
		barScale.Scale = math.clamp(math.min(v.X / 450, v.Y / 340), 0.5, 1)
	end
	updateBarScale()
	if workspace.CurrentCamera then
		table.insert(Cleanup, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateBarScale))
	end

	local row = Instance.new("UIListLayout", bar)
	row.FillDirection = Enum.FillDirection.Horizontal
	row.Padding = UDim.new(0, 7)
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	row.HorizontalAlignment = Enum.HorizontalAlignment.Center
	row.SortOrder = Enum.SortOrder.LayoutOrder


	-- spinning disc (also the handle used to drag the bar)
	local disc = Instance.new("TextButton", bar)
	disc.LayoutOrder = 1
	disc.Size = UDim2.new(0, 38, 0, 38)
	disc.BackgroundTransparency = 1
	disc.AutoButtonColor = false
	disc.Text = "💿"
	disc.TextSize = 26
	disc.TextColor3 = Theme.Text
	disc.ZIndex = 122

	makeDraggable(bar, disc)

	-- song info
	local infoF = Instance.new("Frame", bar)
	infoF.LayoutOrder = 2
	infoF.Size = UDim2.new(0, 116, 0, 38)
	infoF.BackgroundTransparency = 1
	infoF.ZIndex = 121

	local nameL = Instance.new("TextLabel", infoF)
	nameL.Position = UDim2.new(0, 0, 0, 1)
	nameL.Size = UDim2.new(1, 0, 0, 16)
	nameL.BackgroundTransparency = 1
	nameL.Text = "♪ Loading song..."
	nameL.TextColor3 = Theme.Text
	nameL.Font = Enum.Font.GothamBold
	nameL.TextSize = 11
	nameL.TextXAlignment = Enum.TextXAlignment.Left
	nameL.TextTruncate = Enum.TextTruncate.AtEnd
	nameL.ZIndex = 122

	local prog = Instance.new("Frame", infoF)
	prog.Position = UDim2.new(0, 0, 0, 19)
	prog.Size = UDim2.new(1, 0, 0, 4)
	prog.BackgroundColor3 = Color3.fromRGB(34, 36, 70)
	prog.BorderSizePixel = 0
	prog.ZIndex = 122
	Instance.new("UICorner", prog).CornerRadius = UDim.new(1, 0)

	local progFill = Instance.new("Frame", prog)
	progFill.Size = UDim2.new(0, 0, 1, 0)
	progFill.BackgroundColor3 = Color3.new(1, 1, 1)
	progFill.BorderSizePixel = 0
	progFill.ZIndex = 123
	Instance.new("UICorner", progFill).CornerRadius = UDim.new(1, 0)
	table.insert(Reg.grads, addGradient(progFill, Theme.A1, Theme.A2, 0))

	local timeL = Instance.new("TextLabel", infoF)
	timeL.Position = UDim2.new(0, 0, 0, 24)
	timeL.Size = UDim2.new(1, 0, 0, 13)
	timeL.BackgroundTransparency = 1
	timeL.Text = "0:00 / 0:00"
	timeL.TextColor3 = Theme.Muted
	timeL.Font = Enum.Font.Gotham
	timeL.TextSize = 10
	timeL.TextXAlignment = Enum.TextXAlignment.Left
	timeL.ZIndex = 122

	-- equalizer (driven by the real loudness of the song)
	local eqF = Instance.new("Frame", bar)
	eqF.LayoutOrder = 3
	eqF.Size = UDim2.new(0, 40, 0, 30)
	eqF.BackgroundTransparency = 1
	eqF.ZIndex = 121

	local eqList = Instance.new("UIListLayout", eqF)
	eqList.FillDirection = Enum.FillDirection.Horizontal
	eqList.Padding = UDim.new(0, GAP + 2)
	eqList.VerticalAlignment = Enum.VerticalAlignment.Bottom
	eqList.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local eqBars = {}
	local eqHeights = {}
	for i = 1, 5 do
		local eb = Instance.new("Frame", eqF)
		eb.Size = UDim2.new(0, 5, 0, 3)
		eb.BackgroundColor3 = Color3.new(1, 1, 1)
		eb.BorderSizePixel = 0
		eb.ZIndex = 122
		Instance.new("UICorner", eb).CornerRadius = UDim.new(1, 0)
		table.insert(Reg.grads, addGradient(eb, Theme.A1, Theme.A2, 90))
		eqBars[i] = eb
		eqHeights[i] = 3
	end

	-- play / pause + customizer buttons
	local musicOn = false
	local songAssetReady = false

	local playBtn = makeButton(bar, "", UDim2.new(0, 34, 0, 34), 15, nil)
	playBtn.LayoutOrder = 4
	playBtn.ZIndex = 125

	-- realistic speaker icon drawn from frames (no emoji): body + cone + sound waves / mute cross
	local iconParts, iconStrokes = {}, {}
	local waveClip, mute1, mute2
	do
		local function part(x, y, w, h, r)
			local f = Instance.new("Frame", playBtn)
			f.Position = UDim2.new(0, x, 0, y)
			f.Size = UDim2.new(0, w, 0, h)
			f.BackgroundColor3 = Theme.Text
			f.BorderSizePixel = 0
			f.ZIndex = 127
			if r then Instance.new("UICorner", f).CornerRadius = UDim.new(0, r) end
			table.insert(iconParts, f)
			return f
		end

		part(7, 13, 5, 8, 1)                       -- speaker body
		local heights = { 10, 14, 18, 22 }         -- cone (stepped slivers)
		for i, h in ipairs(heights) do
			part(11 + (i - 1) * 2, 17 - h / 2, 2, h, 0)
		end

		waveClip = Instance.new("Frame", playBtn)
		waveClip.BackgroundTransparency = 1
		waveClip.ClipsDescendants = true
		waveClip.Position = UDim2.new(0, 21, 0, 4)
		waveClip.Size = UDim2.new(0, 12, 0, 26)
		waveClip.ZIndex = 127
		for _, d in ipairs({ 10, 20 }) do
			local w = Instance.new("Frame", waveClip)
			w.BackgroundTransparency = 1
			w.Position = UDim2.new(0, -d / 2, 0, 13 - d / 2)
			w.Size = UDim2.new(0, d, 0, d)
			w.ZIndex = 127
			Instance.new("UICorner", w).CornerRadius = UDim.new(1, 0)
			local st = Instance.new("UIStroke", w)
			st.Thickness = 2
			st.Color = Theme.Text
			st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			table.insert(iconStrokes, st)
		end

		local function cross(rot)
			local c = Instance.new("Frame", playBtn)
			c.AnchorPoint = Vector2.new(0.5, 0.5)
			c.Position = UDim2.new(0, 27, 0, 17)
			c.Size = UDim2.new(0, 12, 0, 2)
			c.Rotation = rot
			c.BackgroundColor3 = Color3.fromRGB(255, 70, 90)
			c.BorderSizePixel = 0
			c.ZIndex = 128
			Instance.new("UICorner", c).CornerRadius = UDim.new(1, 0)
			return c
		end
		mute1, mute2 = cross(45), cross(-45)
	end

	table.insert(Reg.accentFns, function()
		local c = Theme.Text2 or Theme.Text
		for _, f in ipairs(iconParts) do f.BackgroundColor3 = c end
		for _, st in ipairs(iconStrokes) do st.Color = c end
	end)

	-- TAG on / off (hides or shows the overhead tag)
	local tagBtn = makeButton(bar, "TAG\nON", UDim2.new(0, 38, 0, 34), 9, nil)
	tagBtn.LayoutOrder = 5
	tagBtn.ZIndex = 125
	tagBtn.Font = Enum.Font.GothamBlack

	local function refreshTagBtn()
		tagBtn.Text = tagOn and "TAG\nON" or "TAG\nOFF"
		tagBtn.TextTransparency = tagOn and 0 or 0.45
	end
	tagBtn.MouseButton1Click:Connect(function()
		setTag(not tagOn)
		refreshTagBtn()
	end)

	local gearBtn = makeButton(bar, "", UDim2.new(0, 34, 0, 34), 16, nil)
	do
		-- realistic cog drawn from frames: 8 teeth + thick ring with a real hole
		local cog = Instance.new("Frame", gearBtn)
		cog.AnchorPoint = Vector2.new(0.5, 0.5)
		cog.Position = UDim2.new(0.5, 0, 0.5, 0)
		cog.Size = UDim2.new(0, 34, 0, 34)
		cog.BackgroundTransparency = 1
		cog.ZIndex = 127

		local cogParts = {}
		for i = 0, 7 do
			local ang = math.rad(i * 45)
			local tooth = Instance.new("Frame", cog)
			tooth.AnchorPoint = Vector2.new(0.5, 0.5)
			tooth.Position = UDim2.new(0, 17 + math.cos(ang) * 9.5, 0, 17 + math.sin(ang) * 9.5)
			tooth.Size = UDim2.new(0, 6, 0, 4.5)
			tooth.Rotation = i * 45
			tooth.BackgroundColor3 = Theme.Text
			tooth.BorderSizePixel = 0
			tooth.ZIndex = 127
			Instance.new("UICorner", tooth).CornerRadius = UDim.new(0, 1)
			table.insert(cogParts, tooth)
		end

		local ringF = Instance.new("Frame", cog)
		ringF.AnchorPoint = Vector2.new(0.5, 0.5)
		ringF.Position = UDim2.new(0.5, 0, 0.5, 0)
		ringF.Size = UDim2.new(0, 16, 0, 16)
		ringF.BackgroundTransparency = 1
		ringF.ZIndex = 128
		Instance.new("UICorner", ringF).CornerRadius = UDim.new(1, 0)
		local ringStroke = Instance.new("UIStroke", ringF)
		ringStroke.Thickness = 4
		ringStroke.Color = Theme.Text
		ringStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		table.insert(Reg.accentFns, function()
			local c = Theme.Text2 or Theme.Text
			for _, f in ipairs(cogParts) do f.BackgroundColor3 = c end
			ringStroke.Color = c
		end)

		gearBtn.MouseEnter:Connect(function()
			tween(cog, 0.5, { Rotation = 90 }, Enum.EasingStyle.Quint)
		end)
		gearBtn.MouseLeave:Connect(function()
			tween(cog, 0.5, { Rotation = 0 }, Enum.EasingStyle.Quint)
		end)
	end
	gearBtn.LayoutOrder = 6
	gearBtn.ZIndex = 125

	local function setMusic(on)
		musicOn = on
		if on then
			if songAssetReady then music:Play() end
		else
			music:Pause()
		end
		waveClip.Visible = on
		mute1.Visible = not on
		mute2.Visible = not on
	end

	playBtn.MouseButton1Click:Connect(function()
		setMusic(not musicOn)
	end)

	-- Luz Roja is loaded from the local MP3 created by the NOX script.
	nameL.Text = "♪ LUZ ROJA VIP MIX (SLOWED)"
	task.spawn(function()
		local getAsset = getcustomasset or getsynasset
		if type(getAsset) ~= "function" then
			nameL.Text = "⚠ Executor asset API required"
			return
		end
		local ok, asset = pcall(function()
			return getAsset(SONG_ASSET_FILE)
		end)
		if not ok or not asset then
			nameL.Text = "⚠ Play Luz Roja in NOX once"
			return
		end
		music.SoundId = asset
		songAssetReady = true
		if musicOn then music:Play() end
		local t0 = os.clock()
		while not music.IsLoaded and os.clock() - t0 < 12 do
			task.wait(0.25)
		end
		if not music.IsLoaded then
			nameL.Text = "⚠ Audio unavailable"
		end
	end)

	local function fmtTime(s)
		s = math.max(0, math.floor(s))
		return string.format("%d:%02d", math.floor(s / 60), s % 60)
	end

	table.insert(Hooks, function(t, dt)
		local playing = musicOn and music.IsPlaying

		if playing then
			disc.Rotation = (disc.Rotation + 180 * dt) % 360
		end

		local len = music.TimeLength
		if len and len > 0 then
			progFill.Size = UDim2.new(math.clamp(music.TimePosition / len, 0, 1), 0, 1, 0)
			timeL.Text = fmtTime(music.TimePosition) .. " / " .. fmtTime(len)
		end

		local loud = math.clamp(music.PlaybackLoudness / 500, 0, 1)
		for i, eb in ipairs(eqBars) do
			local target = 3
			if playing then
				target = 3 + loud * 24 * (0.55 + 0.45 * math.abs(math.sin(t * 5 + i * 1.7)))
			end
			eqHeights[i] = eqHeights[i] + (target - eqHeights[i]) * 0.5
			eb.Size = UDim2.new(0, 5, 0, math.floor(eqHeights[i] + 0.5))
		end
	end)

	--==================================================
	-- CUSTOMIZER PANEL (opens beside the main GUI)
	--==================================================

	-- invisible holder that always mirrors the main window (position, size, scale)
	local holder = Instance.new("Frame", sg)
	holder.Name = "CustomizerHolder"
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.ClipsDescendants = false
	holder.Active = false
	holder.ZIndex = 60
	holder.AnchorPoint = Main.AnchorPoint
	holder.Position = Main.Position
	holder.Size = Main.Size
	holder.Visible = false
	local holderScale = Instance.new("UIScale", holder)
	holderScale.Scale = MainScale.Scale

	local panel = Instance.new("CanvasGroup", holder)
	panel.Name = "Customizer"
	panel.AnchorPoint = Vector2.new(0, 0)
	panel.Size = UDim2.new(0, 290, 0, 314)
	panel.BackgroundTransparency = 1
	panel.BorderSizePixel = 0
	panel.GroupTransparency = 1
	panel.Visible = true
	panel.Active = true
	panel.ZIndex = 60
	regCorner(panel, 14)
	borderStroke(panel, 2, 0)

	local panelScale = Instance.new("UIScale", panel)
	panelScale.Scale = 1


	local panelBg = Instance.new("Frame", panel)
	panelBg.Size = UDim2.new(1, 0, 1, 0)
	panelBg.BackgroundColor3 = Color3.new(1, 1, 1)
	panelBg.BackgroundTransparency = 0.04
	panelBg.BorderSizePixel = 0
	panelBg.ZIndex = 1
	local panelBgGrad = addGradient(panelBg, shade(0.12), shade(0.2), 70)
	table.insert(Reg.accentFns, function()
		panelBgGrad.Color = ColorSequence.new(shade(0.12), shade(0.2))
	end)

	local pTitle = Instance.new("TextLabel", panel)
	pTitle.Position = UDim2.new(0, 10, 0, 4)
	pTitle.Size = UDim2.new(1, -52, 0, 26)
	pTitle.BackgroundTransparency = 1
	pTitle.Text = "⚙️ CUSTOMIZE"
	pTitle.TextColor3 = Theme.Text
	pTitle.Font = Enum.Font.GothamBlack
	pTitle.TextSize = 14
	pTitle.TextXAlignment = Enum.TextXAlignment.Left
	pTitle.ZIndex = 5

	local pClose = makeButton(panel, "✕", UDim2.new(0, 26, 0, 24), 13, nil)
	pClose.Position = UDim2.new(1, -34, 0, 5)
	pClose.ZIndex = 8

	local pDiv = Instance.new("Frame", panel)
	pDiv.Position = UDim2.new(0, 10, 0, 31)
	pDiv.Size = UDim2.new(1, -20, 0, 2)
	pDiv.BackgroundColor3 = Color3.new(1, 1, 1)
	pDiv.BorderSizePixel = 0
	pDiv.ZIndex = 5
	table.insert(Reg.grads, addGradient(pDiv, Theme.A1, Theme.A2, 0))

	-- one scrolling column: presets, sliders, effects
	local scroller = Instance.new("ScrollingFrame", panel)
	scroller.Position = UDim2.new(0, 8, 0, 36)
	scroller.Size = UDim2.new(1, -30, 1, -42)
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.ScrollBarThickness = 0
	scroller.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
	scroller.VerticalScrollBarInset = Enum.ScrollBarInset.None
	scroller.ElasticBehavior = Enum.ElasticBehavior.Never
	scroller.ScrollBarImageColor3 = Color3.fromRGB(0, 230, 255)
	scroller.ScrollBarImageTransparency = 0.2
	scroller.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	scroller.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	scroller.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroller.ScrollingDirection = Enum.ScrollingDirection.Y
	scroller.ZIndex = 5

	local sList = Instance.new("UIListLayout", scroller)
	sList.Padding = UDim.new(0, GAP)
	sList.SortOrder = Enum.SortOrder.LayoutOrder
	sList.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local sPad = Instance.new("UIPadding", scroller)
	sPad.PaddingRight = UDim.new(0, 4)
	sPad.PaddingLeft = UDim.new(0, 2)
	sPad.PaddingTop = UDim.new(0, 2)
	sPad.PaddingBottom = UDim.new(0, 6)

	local function sectionLabel(text, order)
		local l = Instance.new("TextLabel", scroller)
		l.LayoutOrder = order
		l.Size = UDim2.new(1, 0, 0, 14)
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextColor3 = Theme.Muted
		l.Font = Enum.Font.GothamBold
		l.TextSize = 10
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.ZIndex = 6
		return l
	end

	local sliders = {}
	local chips = {}

	local function hueOf(c)
		local h = c:ToHSV()
		return h
	end

	local function pct(v)
		return string.format("%d%%", math.floor(v * 100 + 0.5))
	end

	local function deg(v)
		return string.format("%d°", math.floor(v * 360))
	end

	local function refreshSliders()
		sliders.h1.set(hueOf(Theme.A1), true)
		sliders.h2.set(hueOf(Theme.A2), true)
		sliders.size.set(Theme.Scale, true)
		sliders.opacity.set(1 - Theme.Opacity, true)
		sliders.aura.set(Theme.AuraPower, true)
		sliders.round.set(Theme.Round, true)
		sliders.volume.set(Theme.Volume, true)
	end

	local function refreshChips()
		chips.aura.Text = "AURA: " .. (Theme.Aura and "ON" or "OFF")
		chips.particles.Text = "SPARKS: " .. (Theme.Particles and "ON" or "OFF")
		chips.rainbow.Text = "RAINBOW: " .. (Theme.Rainbow and "ON" or "OFF")
		chips.spin.Text = "SPIN: " .. (Theme.Spin and "ON" or "OFF")
		chips.font.Text = "FONT " .. Theme.FontIndex .. "/" .. #Fonts .. ": " .. FontNames[Theme.FontIndex]
	end

	-- 1) theme presets
	sectionLabel("THEME PRESETS", 1)

	local presetRow = Instance.new("Frame", scroller)
	presetRow.LayoutOrder = 2
	presetRow.AutomaticSize = Enum.AutomaticSize.Y
	presetRow.Size = UDim2.new(1, 0, 0, 0)
	presetRow.BackgroundTransparency = 1
	presetRow.ZIndex = 6
	local presetGrid = Instance.new("UIGridLayout", presetRow)
	presetGrid.CellSize = UDim2.new(0, 34, 0, 28)
	presetGrid.CellPadding = UDim2.new(0, 6, 0, 5)
	presetGrid.SortOrder = Enum.SortOrder.LayoutOrder

	local presets = {
		{ Color3.fromRGB(0, 200, 255), Color3.fromRGB(160, 60, 255) },  -- cyber
		{ Color3.fromRGB(255, 40, 60), Color3.fromRGB(120, 0, 40) },    -- blood
		{ Color3.fromRGB(60, 255, 120), Color3.fromRGB(0, 150, 100) },  -- toxic
		{ Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 100, 0) },  -- sunset
		{ Color3.fromRGB(255, 120, 200), Color3.fromRGB(190, 90, 255) },-- sakura
		{ Color3.fromRGB(130, 235, 255), Color3.fromRGB(60, 110, 255) },-- ice
		{ Color3.fromRGB(255, 90, 0), Color3.fromRGB(255, 0, 90) },     -- lava
		{ Color3.fromRGB(0, 255, 200), Color3.fromRGB(0, 90, 200) },    -- ocean
		{ Color3.fromRGB(140, 80, 255), Color3.fromRGB(20, 0, 120) },   -- galaxy
		{ Color3.fromRGB(190, 255, 60), Color3.fromRGB(0, 160, 40) },   -- matrix
		{ Color3.fromRGB(255, 255, 255), Color3.fromRGB(110, 110, 130) },-- mono
		{ Color3.fromRGB(255, 215, 110), Color3.fromRGB(170, 90, 20) },  -- royal gold
		{ Color3.fromRGB(180, 255, 0), Color3.fromRGB(0, 120, 60) },     -- venom
		{ Color3.fromRGB(255, 60, 0), Color3.fromRGB(255, 200, 0) },     -- inferno
		{ Color3.fromRGB(220, 0, 70), Color3.fromRGB(70, 0, 110) },      -- vampire
		{ Color3.fromRGB(255, 0, 200), Color3.fromRGB(0, 200, 255) },    -- plasma
		{ Color3.fromRGB(255, 0, 110), Color3.fromRGB(255, 120, 0) },    -- danger pink
		{ Color3.fromRGB(0, 130, 255), Color3.fromRGB(0, 20, 100) },     -- abyss
		{ Color3.fromRGB(235, 255, 0), Color3.fromRGB(255, 110, 0) },    -- radioactive
		{ Color3.fromRGB(205, 230, 255), Color3.fromRGB(120, 90, 210) }, -- ghost
		{ Color3.fromRGB(255, 40, 0), Color3.fromRGB(130, 0, 60) },      -- dragon
		{ Color3.fromRGB(0, 255, 130), Color3.fromRGB(255, 215, 0) },    -- emerald king
		{ Color3.fromRGB(140, 0, 255), Color3.fromRGB(255, 0, 80) },     -- shadow
		{ Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 0, 0) }       -- warning
,
		{ Color3.fromRGB(120, 255, 190), Color3.fromRGB(110, 70, 40) },  -- mint choco
		{ Color3.fromRGB(255, 150, 220), Color3.fromRGB(120, 210, 255) },-- cotton candy
		{ Color3.fromRGB(60, 255, 150), Color3.fromRGB(150, 60, 255) },  -- aurora
		{ Color3.fromRGB(255, 170, 120), Color3.fromRGB(255, 70, 150) }, -- peach
		{ Color3.fromRGB(40, 90, 255), Color3.fromRGB(255, 40, 90) },    -- sapphire ruby
		{ Color3.fromRGB(190, 255, 0), Color3.fromRGB(210, 0, 255) },    -- lime berry
		{ Color3.fromRGB(255, 120, 100), Color3.fromRGB(0, 205, 205) },  -- coral reef
		{ Color3.fromRGB(255, 140, 0), Color3.fromRGB(0, 200, 170) },    -- orange teal
		{ Color3.fromRGB(210, 170, 255), Color3.fromRGB(120, 255, 200) },-- lavender mint
		{ Color3.fromRGB(210, 0, 45), Color3.fromRGB(255, 205, 0) },     -- crimson gold
		{ Color3.fromRGB(0, 165, 255), Color3.fromRGB(255, 85, 0) },     -- blue fire
		{ Color3.fromRGB(255, 105, 185), Color3.fromRGB(100, 225, 255) },-- bubblegum
		{ Color3.fromRGB(0, 170, 90), Color3.fromRGB(210, 255, 120) },   -- forest
		{ Color3.fromRGB(255, 175, 155), Color3.fromRGB(200, 95, 135) }, -- rose gold
		{ Color3.fromRGB(255, 105, 175), Color3.fromRGB(255, 245, 105) },-- pink lemon
		{ Color3.fromRGB(25, 35, 130), Color3.fromRGB(0, 220, 255) }     -- midnight sky
	}

	for _, p in ipairs(presets) do
		local sw = Instance.new("TextButton", presetRow)
		sw.Size = UDim2.new(0, 34, 0, 28)
		sw.BackgroundColor3 = Color3.new(1, 1, 1)
		sw.Text = ""
		sw.AutoButtonColor = false
		sw.ZIndex = 7
		Instance.new("UICorner", sw).CornerRadius = UDim.new(0, 7)
		addGradient(sw, p[1], p[2], 45)
		local sws = Instance.new("UIStroke", sw)
		sws.Color = Color3.new(1, 1, 1)
		sws.Transparency = 0.5
		sws.Thickness = 1
		sws.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		sw.MouseButton1Click:Connect(function()
			Theme.A1 = p[1]
			Theme.A2 = p[2]
			Theme.Rainbow = false
			applyAll()
			refreshSliders()
			refreshChips()
		end)
	end

	-- 2) sliders
	sliders.h1 = makeSlider(scroller, "ACCENT COLOR 1", 0, 1, hueOf(Theme.A1), deg, function(v)
		Theme.A1 = Color3.fromHSV(v, 0.85, 1)
		Theme.Rainbow = false
		applyAll()
		refreshChips()
	end, scroller)
	sliders.h1.frame.LayoutOrder = 3

	sliders.h2 = makeSlider(scroller, "ACCENT COLOR 2", 0, 1, hueOf(Theme.A2), deg, function(v)
		Theme.A2 = Color3.fromHSV(v, 0.85, 1)
		Theme.Rainbow = false
		applyAll()
		refreshChips()
	end, scroller)
	sliders.h2.frame.LayoutOrder = 4

	sliders.size = makeSlider(scroller, "GUI SIZE", 0.6, 1.3, Theme.Scale, pct, function(v)
		Theme.Scale = v
		applyLook()
	end, scroller)
	sliders.size.frame.LayoutOrder = 5

	sliders.opacity = makeSlider(scroller, "GUI OPACITY", 0, 1, 1 - Theme.Opacity, pct, function(v)
		Theme.Opacity = 1 - v
		applyLook()
	end, scroller)
	sliders.opacity.frame.LayoutOrder = 6

	sliders.aura = makeSlider(scroller, "AURA POWER", 0, 1, Theme.AuraPower, pct, function(v)
		Theme.AuraPower = v
		applyLook()
	end, scroller)
	sliders.aura.frame.LayoutOrder = 7

	sliders.round = makeSlider(scroller, "ROUNDNESS", 0, 2, Theme.Round, pct, function(v)
		Theme.Round = v
		applyLook()
	end, scroller)
	sliders.round.frame.LayoutOrder = 8

	sliders.volume = makeSlider(scroller, "MUSIC VOLUME", 0, 1, Theme.Volume, pct, function(v)
		Theme.Volume = v
		music.Volume = v
	end, scroller)
	sliders.volume.frame.LayoutOrder = 9

	-- 3) effects + buttons
	sectionLabel("EFFECTS", 10)

	local function twoRow(order)
		local r = Instance.new("Frame", scroller)
		r.LayoutOrder = order
		r.Size = UDim2.new(1, 0, 0, 28)
		r.BackgroundTransparency = 1
		r.ZIndex = 6
		local rl = Instance.new("UIListLayout", r)
		rl.FillDirection = Enum.FillDirection.Horizontal
		rl.Padding = UDim.new(0, GAP)
		return r
	end

	local half = UDim2.new(0.5, -1, 1, 0)

	local row1 = twoRow(11)
	chips.aura = makeButton(row1, "", half, 11, function()
		Theme.Aura = not Theme.Aura
		applyLook()
		refreshChips()
	end)
	chips.particles = makeButton(row1, "", half, 11, function()
		Theme.Particles = not Theme.Particles
		refreshChips()
	end)

	local row2 = twoRow(12)
	chips.rainbow = makeButton(row2, "", half, 11, function()
		Theme.Rainbow = not Theme.Rainbow
		if not Theme.Rainbow then
			Theme.A1 = Defaults.A1
			Theme.A2 = Defaults.A2
			applyAll()
			refreshSliders()
		end
		refreshChips()
	end)
	chips.spin = makeButton(row2, "", half, 11, function()
		Theme.Spin = not Theme.Spin
		refreshChips()
	end)

	local row3 = twoRow(13)
	chips.font = makeButton(row3, "", UDim2.new(1, 0, 1, 0), 11, function()
		Theme.FontIndex = (Theme.FontIndex % #Fonts) + 1
		applyLook()
		refreshChips()
	end)

	local row4 = twoRow(14)
	makeButton(row4, "🎲 RANDOM", half, 11, function()
		local h = math.random()
		Theme.A1 = Color3.fromHSV(h, 0.8, 1)
		Theme.A2 = Color3.fromHSV((h + 0.25 + math.random() * 0.3) % 1, 0.85, 1)
		Theme.Rainbow = false
		applyAll()
		refreshSliders()
		refreshChips()
	end)
	makeButton(row4, "SAVE", half, 11, function(btnSave)
		local ok = Theme._save and Theme._save()
		btnSave.Text = ok and "SAVED" or "SAVE FAILED"
		task.delay(1.6, function() if btnSave.Parent then btnSave.Text = "SAVE" end end)
	end)

	Theme._refresh = function()
		music.Volume = Theme.Volume
		refreshSliders()
		refreshChips()
	end

	refreshChips()

	-- custom scrollbar (right side, outside the content so nothing overlaps it)
	do
		local track = Instance.new("Frame", panel)
		track.Name = "ScrollTrack"
		track.Position = UDim2.new(1, -18, 0, 40)
		track.Size = UDim2.new(0, 8, 1, -50)
		track.BackgroundColor3 = Color3.new(0, 0, 0)
		track.BackgroundTransparency = 0.55
		track.BorderSizePixel = 0
		track.ZIndex = 20
		Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

		local thumb = Instance.new("Frame", track)
		thumb.Name = "Thumb"
		thumb.Size = UDim2.new(1, 0, 0, 40)
		thumb.BackgroundColor3 = Color3.new(1, 1, 1)
		thumb.BorderSizePixel = 0
		thumb.ZIndex = 21
		Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)
		table.insert(Reg.grads, addGradient(thumb, Theme.A1, Theme.A2, 90))

		local function metrics()
			local S = math.max(holderScale.Scale * panelScale.Scale, 0.01)
			local win = scroller.AbsoluteWindowSize.Y / S
			local canvas = scroller.AbsoluteCanvasSize.Y / S
			local trackH = track.AbsoluteSize.Y / S
			return win, canvas, trackH
		end

		local function updateThumb()
			local win, canvas, trackH = metrics()
			if canvas <= win + 1 or trackH <= 0 then
				thumb.Visible = false
				return
			end
			thumb.Visible = true
			local th = math.max(28, trackH * (win / canvas))
			local maxScroll = canvas - win
			local pos = math.clamp(scroller.CanvasPosition.Y / maxScroll, 0, 1)
			thumb.Size = UDim2.new(1, 0, 0, th)
			thumb.Position = UDim2.new(0, 0, 0, pos * (trackH - th))
		end

		scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(updateThumb)
		scroller:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateThumb)
		scroller:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateThumb)
		track:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateThumb)
		task.defer(updateThumb)

		local dragging, startY, startCanvas = false, 0, 0
		local function begin(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				startY = input.Position.Y
				startCanvas = scroller.CanvasPosition.Y
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end
		thumb.InputBegan:Connect(begin)

		-- tapping the track jumps there
		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
				local win, canvas, trackH = metrics()
				if canvas <= win then return end
				local S = math.max(holderScale.Scale * panelScale.Scale, 0.01)
				local rel = math.clamp((input.Position.Y - track.AbsolutePosition.Y) / S / trackH, 0, 1)
				scroller.CanvasPosition = Vector2.new(0, rel * (canvas - win))
			end
		end)

		table.insert(Cleanup, UserInputService.InputChanged:Connect(function(input)
			if not dragging then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
				local win, canvas, trackH = metrics()
				local th = math.max(28, trackH * (win / canvas))
				local maxScroll = canvas - win
				local free = math.max(trackH - th, 1)
				local S = math.max(holderScale.Scale * panelScale.Scale, 0.01)
				local dy = (input.Position.Y - startY) / S
				scroller.CanvasPosition = Vector2.new(0, math.clamp(startCanvas + dy * (maxScroll / free), 0, maxScroll))
			end
		end))
	end

	-- panel docks exactly beside the main window (same top, same height)
	local panelOpen = false
	local panelShown = false
	local panelTweens = {}
	local panelOffset = Vector2.new(0, 0) -- extra offset after the user drags the panel
	local panelSlide = Instance.new("NumberValue", panel)
	panelSlide.Value = 0 -- small slide-out animation (pixels)
	local PANEL_W, PANEL_H, PANEL_GAP, PANEL_TOP = 290, 314, 3, 26

	local function syncPanel()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local vp = cam.ViewportSize
		local S = MainScale.Scale
		local vs = viewScale() -- customizer keeps its own size; only the main GUI follows the size slider
		panelScale.Scale = vs / math.max(S, 0.01)

		holder.AnchorPoint = Main.AnchorPoint
		holder.Position = Main.Position
		holder.Size = Main.Size
		holderScale.Scale = S
		holder.Visible = panelShown and Main.Visible
		if not holder.Visible then return end

		-- where the main window sits on screen (screen px)
		local mw, mh = 420 * S, 340 * S
		local cx = Main.Position.X.Scale * vp.X + Main.Position.X.Offset
		local cy = Main.Position.Y.Scale * vp.Y + Main.Position.Y.Offset
		local mLeft = cx - mw * Main.AnchorPoint.X
		local mTop = cy - mh * Main.AnchorPoint.Y
		local pw, ph = PANEL_W * vs, PANEL_H * vs

		local rightSide = (mLeft + mw + PANEL_GAP * vs + pw <= vp.X) or (mLeft - PANEL_GAP * vs - pw < 0)
		local baseX = rightSide and (mLeft + mw + PANEL_GAP * vs) or (mLeft - PANEL_GAP * vs - pw)
		local baseY = mTop + PANEL_TOP * S

		-- keep the dragged offset on screen
		local ox = math.clamp(baseX + panelOffset.X, 0, math.max(vp.X - pw, 0)) - baseX
		local oy = math.clamp(baseY + panelOffset.Y, 0, math.max(vp.Y - ph, 0)) - baseY
		panelOffset = Vector2.new(ox, oy)

		-- offsets are in holder space (already scaled by the same UIScale as Main)
		local ux, uy = ox / S, oy / S
		if rightSide then
			panel.AnchorPoint = Vector2.new(0, 0)
			panel.Position = UDim2.new(1, PANEL_GAP - panelSlide.Value + ux, 0, PANEL_TOP + uy)
		else
			panel.AnchorPoint = Vector2.new(1, 0)
			panel.Position = UDim2.new(0, -PANEL_GAP + panelSlide.Value + ux, 0, PANEL_TOP + uy)
		end
	end

	Main:GetPropertyChangedSignal("Position"):Connect(syncPanel)
	Main:GetPropertyChangedSignal("Size"):Connect(syncPanel)
	Main:GetPropertyChangedSignal("AnchorPoint"):Connect(syncPanel)
	Main:GetPropertyChangedSignal("Visible"):Connect(syncPanel)
	MainScale:GetPropertyChangedSignal("Scale"):Connect(syncPanel)
	panelSlide:GetPropertyChangedSignal("Value"):Connect(syncPanel)
	if workspace.CurrentCamera then
		table.insert(Cleanup, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(syncPanel))
	end

	-- drag the customizer by its title bar
	do
		local dragging = false
		local startMouse, startOffset
		local handle = Instance.new("TextButton", panel)
		handle.Name = "DragHandle"
		handle.Position = UDim2.new(0, 0, 0, 0)
		handle.Size = UDim2.new(1, -42, 0, 32)
		handle.BackgroundTransparency = 1
		handle.Text = ""
		handle.AutoButtonColor = false
		handle.ZIndex = 9

		handle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				startMouse = input.Position
				startOffset = panelOffset
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)

		table.insert(Cleanup, UserInputService.InputChanged:Connect(function(input)
			if not dragging then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
				local d = input.Position - startMouse
				panelOffset = startOffset + Vector2.new(d.X, d.Y)
				syncPanel()
			end
		end))
	end

	local function setPanel(open)
		panelOpen = open
		for _, t in ipairs(panelTweens) do
			t:Cancel()
		end
		table.clear(panelTweens)

		if open then
			panelOffset = Vector2.new(0, 0) -- always opens exactly beside the main GUI
			if not panelShown then
				panel.GroupTransparency = 1
				panelSlide.Value = 14
			end
			panelShown = true
			syncPanel()
			table.insert(panelTweens, tween(panel, 0.22, { GroupTransparency = 0 }))
			table.insert(panelTweens, tween(panelSlide, 0.25, { Value = 0 }, Enum.EasingStyle.Quad))
		else
			table.insert(panelTweens, tween(panel, 0.15, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
			local cl = tween(panelSlide, 0.15, { Value = 10 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			table.insert(panelTweens, cl)
			cl.Completed:Connect(function(state)
				if state == Enum.PlaybackState.Completed and not panelOpen then
					panelShown = false
					holder.Visible = false
				end
			end)
		end
	end

	gearBtn.MouseButton1Click:Connect(function()
		setPanel(not panelOpen)
	end)
	pClose.MouseButton1Click:Connect(function()
		setPanel(false)
	end)

	syncPanel()

	-- the bar slides in and the music starts once the setup is finished
	tween(bar, 0.6, { Position = UDim2.new(1, -10, 0, 8) }, Enum.EasingStyle.Back)
	setMusic(true)
	setTag(true)
	refreshTagBtn()
end


--==================================================
-- ABILITY ENGINE (fly / noclip / speed / spin / jump / esp / shield)
--==================================================

do
	local flyBV, flyBG
	local lastSafe
	local espObjs = {}
	local up, down = false, false

	local function charParts()
		local c = player.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		local r = c and c:FindFirstChild("HumanoidRootPart")
		return c, h, r
	end

	AbRef.stopFly = function()
		if flyBV then flyBV:Destroy() flyBV = nil end
		if flyBG then flyBG:Destroy() flyBG = nil end
		local _, h = charParts()
		if h then h.PlatformStand = false end
	end

	local function clearESP()
		for _, o in ipairs(espObjs) do pcall(function() o:Destroy() end) end
		espObjs = {}
	end

	local function addESP(p)
		if p == player or not p.Character then return end
		local c = p.Character
		local h = Instance.new("Highlight")
		h.Name = "AAYAN_ESP"
		h.Adornee = c
		h.FillColor = Theme.A1
		h.FillTransparency = 0.75
		h.OutlineColor = Color3.new(1, 1, 1)
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Parent = c
		table.insert(espObjs, h)

		local head = c:FindFirstChild("Head")
		if head then
			local bb = Instance.new("BillboardGui")
			bb.Name = "AAYAN_ESP_NAME"
			bb.Adornee = head
			bb.Size = UDim2.new(0, 120, 0, 18)
			bb.StudsOffset = Vector3.new(0, 2.4, 0)
			bb.AlwaysOnTop = true
			bb.Parent = head
			local l = Instance.new("TextLabel", bb)
			l.Size = UDim2.new(1, 0, 1, 0)
			l.BackgroundTransparency = 1
			l.Text = p.DisplayName
			l.TextColor3 = Color3.new(1, 1, 1)
			l.TextStrokeTransparency = 0.3
			l.Font = Enum.Font.GothamBold
			l.TextSize = 13
			table.insert(espObjs, bb)
		end
	end

	AbRef.refreshESP = function()
		clearESP()
		if Ab.esp then
			for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
		end
	end

	table.insert(Cleanup, { Disconnect = function() clearESP() AbRef.stopFly() end })

	Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function()
			task.wait(1)
			if Ab.esp then addESP(p) end
		end)
	end)
	for _, p in ipairs(Players:GetPlayers()) do
		p.CharacterAdded:Connect(function()
			task.wait(1)
			if Ab.esp then addESP(p) end
		end)
	end

	local saved
	AbRef.applyFB = function()
		if Ab.fb then
			if not saved then
				saved = { Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.FogEnd, Lighting.ClockTime }
			end
		elseif saved then
			Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.FogEnd, Lighting.ClockTime = unpack(saved)
			saved = nil
		end
	end

	table.insert(Cleanup, UserInputService.InputBegan:Connect(function(i, gp)
		if gp then return end
		if i.KeyCode == Enum.KeyCode.Space or i.KeyCode == Enum.KeyCode.E then up = true end
		if i.KeyCode == Enum.KeyCode.LeftShift or i.KeyCode == Enum.KeyCode.Q then down = true end
	end))
	table.insert(Cleanup, UserInputService.InputEnded:Connect(function(i)
		if i.KeyCode == Enum.KeyCode.Space or i.KeyCode == Enum.KeyCode.E then up = false end
		if i.KeyCode == Enum.KeyCode.LeftShift or i.KeyCode == Enum.KeyCode.Q then down = false end
	end))

	-- infinite jump
	table.insert(Cleanup, UserInputService.JumpRequest:Connect(function()
		if Config.InfJump then
			local _, h = charParts()
			if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
		end
	end))

	-- anti afk
	pcall(function()
		local vu = game:GetService("VirtualUser")
		table.insert(Cleanup, player.Idled:Connect(function()
			if Config.AntiAFK then
				vu:CaptureController()
				vu:ClickButton2(Vector2.new())
			end
		end))
	end)

	-- noclip (physics step so the game cannot push us back)
	table.insert(Cleanup, RunService.Stepped:Connect(function()
		if not Ab.noclip then return end
		local c = player.Character
		if not c then return end
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("BasePart") and d.CanCollide then d.CanCollide = false end
		end
	end))

	table.insert(Hooks, function(t, dt)
		local c, h, r = charParts()
		if not (c and h and r) then return end

		-- fly
		if Ab.fly then
			if not flyBV then
				flyBV = Instance.new("BodyVelocity")
				flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
				flyBV.Velocity = Vector3.zero
				flyBV.Parent = r
				flyBG = Instance.new("BodyGyro")
				flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
				flyBG.P = 9000
				flyBG.Parent = r
			end
			h.PlatformStand = true
			local cam = workspace.CurrentCamera
			local mv = h.MoveDirection
			local vel = Vector3.zero
			if mv.Magnitude > 0.05 then
				local flat = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
				flat = flat.Magnitude > 0 and flat.Unit or Vector3.new(0, 0, -1)
				local rightFlat = Vector3.new(-flat.Z, 0, flat.X)
				local f = mv:Dot(flat)
				local sd = mv:Dot(rightFlat)
				vel = (cam.CFrame.LookVector * f + cam.CFrame.RightVector * sd) * AbV.flySpeed
			end
			if up then vel = vel + Vector3.new(0, AbV.flySpeed, 0) end
			if down then vel = vel - Vector3.new(0, AbV.flySpeed, 0) end
			flyBV.Velocity = vel
			flyBG.CFrame = CFrame.new(r.Position, r.Position + Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z))
		end

		-- speed
		if Ab.speed then h.WalkSpeed = AbV.walk end

		-- spin
		if Config.Spin then
			r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(AbV.spinSpeed) * dt, 0)
		end

		-- fullbright
		if Ab.fb then
			Lighting.Brightness = 2
			Lighting.Ambient = Color3.fromRGB(200, 200, 200)
			Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
			Lighting.FogEnd = 1e6
			Lighting.ClockTime = 14
		end

		-- anti sit
		if Config.AntiSit and h.Sit then h.Sit = false end

		-- anti void
		if Config.AntiVoid then
			if r.Position.Y > -50 and h.FloorMaterial ~= Enum.Material.Air then
				lastSafe = r.CFrame
			elseif r.Position.Y < -200 and lastSafe then
				r.AssemblyLinearVelocity = Vector3.zero
				r.CFrame = lastSafe + Vector3.new(0, 4, 0)
			end
		end
	end)

	-- respawn: fly objects belonged to the old body
	player.CharacterAdded:Connect(function()
		flyBV, flyBG = nil, nil
	end)
end

--==================================================
-- ONE DRIVER LOOP FOR ALL ANIMATIONS
--==================================================

do
	local accTick = 0
	local shadeTick = 0
	local spinRot = 0

	table.insert(Hooks, function(t, dt)
		-- title shimmer
		TitleGrad.Offset = Vector2.new(math.sin(t * 1.6) * 0.45, 0)

		-- rotating main border
		if Theme.Spin and Main.Visible then
			spinRot = (spinRot + 90 * dt) % 360
			MainStrokeGrad.Rotation = spinRot
		end

		-- danger pulse on the toggle
		local pulse = (math.sin(t * 5) + 1) / 2
		ToggleStroke.Color = Theme.A1:Lerp(Theme.A2, pulse)
		ToggleStroke.Thickness = 3 + pulse
		BadgeStroke.Color = ToggleStroke.Color

		-- rainbow theme
		if Theme.Rainbow then
			local h = (t * 0.08) % 1
			Theme.A1 = Color3.fromHSV(h, 0.8, 1)
			Theme.A2 = Color3.fromHSV((h + 0.4) % 1, 0.85, 1)

			accTick = accTick + dt
			shadeTick = shadeTick + dt

			if accTick > 0.06 then
				accTick = 0
				applyAccent()
			end
			if shadeTick > 0.35 then
				shadeTick = 0
				applyShades()
			end
		end
	end)

	task.spawn(function()
		local last = os.clock()
		while sg.Parent do
			local now = os.clock()
			local dt = now - last
			last = now
			for _, fn in ipairs(Hooks) do
				pcall(fn, now, dt)
			end
			task.wait(0.033)
		end
	end)
end

-- ======================================================================
-- PREMIUM PACK: FAVORITES + QUICK BAR, THEME SLOTS, KEYBINDS
-- (wrapped in pcall: if anything here fails, the rest of the hub still opens)
-- ======================================================================
do
	local okAll, errAll = pcall(function()
		local HS = game:GetService("HttpService")
		local canFile = type(isfile) == "function" and type(readfile) == "function" and type(writefile) == "function"
		local function readJ(name)
			if not canFile then return nil end
			local ok, r = pcall(function()
				if isfile(name) then return HS:JSONDecode(readfile(name)) end
			end)
			if ok and type(r) == "table" then return r end
			return nil
		end
		local function writeJ(name, t)
			if not canFile then return false end
			return (pcall(function() writefile(name, HS:JSONEncode(t)) end))
		end

		local function runEntry(e)
			if typeof(e.cb) == "function" then pcall(e.cb, e.b) end
			pcall(notifyFromButton, e.b)
		end
		local function entryName(e)
			local t = tostring(e.b.Text or e.text0)
			return t
		end

		local function label(parent, text, h, order)
			local l = Instance.new("TextLabel")
			l.LayoutOrder = order or 0
			l.Size = UDim2.new(1, -10, 0, h or 30)
			l.BackgroundTransparency = 1
			l.Text = text
			l.TextColor3 = Theme.Muted
			l.Font = Fonts[Theme.FontIndex]
			l.TextSize = 11
			l.TextWrapped = true
			l.ZIndex = 15
			table.insert(Reg.texts, l)
			l.Parent = parent
			return l
		end
		local function field(parent, placeholder, order)
			local tb = Instance.new("TextBox")
			tb.LayoutOrder = order or 0
			tb.Size = UDim2.new(1, -10, 0, 30)
			tb.PlaceholderText = placeholder
			tb.PlaceholderColor3 = Color3.fromRGB(150, 155, 195)
			tb.Text = ""
			tb.BackgroundColor3 = Theme._field
			tb.TextColor3 = Theme.Text
			tb.Font = Enum.Font.GothamMedium
			tb.TextSize = 13
			tb.ClearTextOnFocus = false
			tb.ZIndex = 15
			regCorner(tb, 8)
			borderStroke(tb, 1.3, 0.1)
			table.insert(Reg.fields, tb)
			tb.Parent = parent
			return tb
		end
		local function flash(b, base, msg)
			b.Text = msg
			task.delay(1.5, function() if b.Parent then b.Text = base end end)
		end
		local function mirror(e, parent, size, order)
			local b = makeButton(parent, tostring(e.b.Text), size or UDim2.new(1, -10, 0, 36), 13, nil)
			b.LayoutOrder = order or 100
			local c = e.b:GetPropertyChangedSignal("Text"):Connect(function() b.Text = e.b.Text end)
			b.Destroying:Connect(function() c:Disconnect() end)
			b.MouseButton1Click:Connect(function() runEntry(e) end)
			return b
		end
		local function clearRows(container, name)
			for _, c in ipairs(container:GetChildren()) do
				if c.Name == name then c:Destroy() end
			end
		end

		-- ---------------- pages + tabs ----------------
		local PF, PK, PT = createPage(), createPage(), createPage()
		-- keep the existing tab order exactly (Reg.tabs is in creation order)
		SideList.SortOrder = Enum.SortOrder.LayoutOrder
		local infoTab = nil
		for i, v in ipairs(Reg.tabs) do
			v.LayoutOrder = i * 10
			if not infoTab and string.find(string.upper(v.Text), "INFO", 1, true) then infoTab = v end
		end
		infoTab = infoTab or Reg.tabs[1]
		local favTab = tab("FAVORITES", PF)
		favTab.LayoutOrder = infoTab.LayoutOrder + 1 -- right after INFO
		tab("THEME SLOTS", PT).LayoutOrder = 9000
		tab("KEYBINDS", PK).LayoutOrder = 9001 -- last

		-- ================= FAVORITES + QUICK BAR =================
		local FAVF = "AAYAN_HUB_V3_FAVS.json"
		local favData = readJ(FAVF) or {}
		for _, id in ipairs(favData.favs or {}) do Theme._fav[id] = true end
		local quickOn = favData.quick == true
		local function saveFav()
			local list = {}
			for _, e in ipairs(Theme._all) do
				if Theme._fav[e.id] then table.insert(list, e.id) end
			end
			writeJ(FAVF, { favs = list, quick = quickOn })
		end

		-- quick bar (floating, draggable, always on screen)
		local qb = Instance.new("Frame", sg)
		qb.Name = "AAYAN_QuickBar"
		qb.AnchorPoint = Vector2.new(1, 0.5)
		qb.Position = UDim2.new(1, -8, 0.5, 0)
		qb.Size = UDim2.new(0, 150, 0, 0)
		qb.AutomaticSize = Enum.AutomaticSize.Y
		qb.BackgroundColor3 = Theme._card
		qb.BackgroundTransparency = 0.15
		qb.BorderSizePixel = 0
		qb.ZIndex = 14
		qb.Visible = false
		regCorner(qb, 10)
		borderStroke(qb, 1.4, 0.2)
		table.insert(Reg.cards, qb)
		local ql = Instance.new("UIListLayout", qb)
		ql.Padding = UDim.new(0, 4)
		ql.HorizontalAlignment = Enum.HorizontalAlignment.Center
		ql.SortOrder = Enum.SortOrder.LayoutOrder
		local qp = Instance.new("UIPadding", qb)
		qp.PaddingTop = UDim.new(0, 4)
		qp.PaddingBottom = UDim.new(0, 4)
		local qh = Instance.new("TextButton", qb)
		qh.LayoutOrder = 0
		qh.Size = UDim2.new(1, -8, 0, 16)
		qh.BackgroundTransparency = 1
		qh.Text = "QUICK BAR  (drag)"
		qh.TextColor3 = Theme.Muted
		qh.Font = Enum.Font.GothamBold
		qh.TextSize = 9
		qh.AutoButtonColor = false
		qh.ZIndex = 16
		makeDraggable(qb, qh)

		local favList, favHeader -- favList: container (PF)
		local function rebuildFav()
			clearRows(PF, "FavRow")
			clearRows(qb, "QRow")
			local n, q = 0, 0
			for _, e in ipairs(Theme._all) do
				if Theme._fav[e.id] then
					n = n + 1
					local m = mirror(e, PF, nil, 100 + n)
					m.Name = "FavRow"
					if q < 4 then
						q = q + 1
						local qm = mirror(e, qb, UDim2.new(1, -8, 0, 28), q)
						qm.TextSize = 11
						qm.Name = "QRow"
					end
				end
			end
			favHeader.Text = (n == 0) and "No favorites yet. Tap the FAV tag on any button in any tab to add it here."
				or ("Favorites: " .. n .. "   (quick bar shows the first 4)")
			qb.Visible = quickOn and q > 0
		end
		Theme._refreshStars = function()
			for _, e in ipairs(Theme._all) do
				if e.star and e.star.Parent then
					e.star.Visible = Theme._favEdit
					local f = Theme._fav[e.id]
					e.star.TextColor3 = f and Color3.fromRGB(255, 215, 60) or Color3.new(1, 1, 1)
					e.star.BackgroundTransparency = f and 0.1 or 0.45
				end
			end
		end
		Theme._favToggle = function(e)
			if Theme._fav[e.id] then Theme._fav[e.id] = nil else Theme._fav[e.id] = true end
			saveFav()
			Theme._refreshStars()
			rebuildFav()
		end

		local editB = makeButton(PF, "FAV TAGS : ON", UDim2.new(1, -10, 0, 36), 13, nil)
		editB.LayoutOrder = 1
		editB.MouseButton1Click:Connect(function()
			Theme._favEdit = not Theme._favEdit
			editB.Text = "FAV TAGS : " .. (Theme._favEdit and "ON" or "OFF")
			Theme._refreshStars()
		end)
		local quickB = makeButton(PF, "QUICK BAR : " .. (quickOn and "ON" or "OFF"), UDim2.new(1, -10, 0, 36), 13, nil)
		quickB.LayoutOrder = 2
		quickB.MouseButton1Click:Connect(function()
			quickOn = not quickOn
			quickB.Text = "QUICK BAR : " .. (quickOn and "ON" or "OFF")
			saveFav()
			rebuildFav()
		end)
		favHeader = label(PF, "", 34, 3)

		-- ================= KEYBINDS =================
		local KBF = "AAYAN_HUB_V3_BINDS.json"
		local binds = readJ(KBF) or {} -- id -> KeyCode name
		local hubEntry = {
			id = "__hub", text0 = "SHOW / HIDE HUB",
			b = { Text = "SHOW / HIDE HUB" },
			cb = function() setMain(not mainOpen) end,
		}
		local capturing = nil
		local BLOCK = { W = 1, A = 1, S = 1, D = 1, Space = 1, Up = 1, Down = 1, Left = 1, Right = 1, Return = 1, Tab = 1 }

		local kbHint = label(PK, "Keyboard only (PC). Tap KEY, then press a key. BACKSPACE clears it.", 28, 1)
		local kBox = field(PK, "search a feature to bind", 2)
		local rebuildKeys
		local function setBind(id, name)
			if name then
				for k, v in pairs(binds) do if v == name then binds[k] = nil end end
				binds[id] = name
			else
				binds[id] = nil
			end
			writeJ(KBF, binds)
		end
		rebuildKeys = function()
			clearRows(PK, "KRow")
			local q = string.lower(kBox.Text)
			local list, n = {}, 0
			local function consider(e)
				if n >= 50 then return end
				local nm = entryName(e)
				local low = string.lower(nm)
				local isToggle = (string.find(nm, ": ON", 1, true) or string.find(nm, ": OFF", 1, true)) ~= nil
					or string.find(nm, ":ON", 1, true) or string.find(nm, ":OFF", 1, true)
				local ok
				if q == "" then ok = (binds[e.id] ~= nil) or isToggle or e.id == "__hub"
				else ok = string.find(low, q, 1, true) ~= nil end
				if ok then n = n + 1 table.insert(list, e) end
			end
			consider(hubEntry)
			for _, e in ipairs(Theme._all) do consider(e) end
			for i, e in ipairs(list) do
				local row = Instance.new("Frame")
				row.Name = "KRow"
				row.LayoutOrder = 100 + i
				row.Size = UDim2.new(1, -10, 0, 34)
				row.BackgroundTransparency = 1
				row.ZIndex = 15
				row.Parent = PK
				local nameL = Instance.new("TextLabel", row)
				nameL.Size = UDim2.new(0.62, -4, 1, 0)
				nameL.BackgroundTransparency = 1
				nameL.Text = entryName(e)
				nameL.TextColor3 = Theme.Text
				nameL.Font = Fonts[Theme.FontIndex]
				nameL.TextSize = 11
				nameL.TextWrapped = true
				nameL.TextXAlignment = Enum.TextXAlignment.Left
				nameL.ZIndex = 15
				table.insert(Reg.texts, nameL)
				local kb = makeButton(row, "KEY: " .. (binds[e.id] or "NONE"), UDim2.new(0.38, 0, 1, 0), 11, nil)
				kb.Position = UDim2.new(0.62, 0, 0, 0)
				kb.MouseButton1Click:Connect(function()
					capturing = { id = e.id, btn = kb }
					kb.Text = "PRESS KEY..."
				end)
			end
			kbHint.Text = (n == 0) and "Nothing found." or "Keyboard only (PC). Tap KEY, then press a key. BACKSPACE clears it."
		end
		local kTok = 0
		kBox:GetPropertyChangedSignal("Text"):Connect(function()
			kTok = kTok + 1
			local my = kTok
			task.delay(0.2, function() if my == kTok then rebuildKeys() end end)
		end)

		table.insert(Cleanup, UserInputService.InputBegan:Connect(function(input, gp)
			if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
			local name = input.KeyCode.Name
			if capturing then
				local cap = capturing
				capturing = nil
				if name == "Backspace" or name == "Escape" then
					setBind(cap.id, nil)
					kbHint.Text = "Key cleared."
				elseif BLOCK[name] then
					kbHint.Text = name .. " movement/chat key hai, doosri key chuno."
				else
					setBind(cap.id, name)
					kbHint.Text = "Bound: " .. name
				end
				rebuildKeys()
				return
			end
			if gp or UserInputService:GetFocusedTextBox() then return end
			for id, kname in pairs(binds) do
				if kname == name then
					if id == "__hub" then
						pcall(hubEntry.cb)
					else
						for _, e in ipairs(Theme._all) do
							if e.id == id then runEntry(e) break end
						end
					end
					break
				end
			end
		end))

		-- ================= THEME SLOTS =================
		local SLF = "AAYAN_HUB_V3_SLOTS.json"
		local slots = readJ(SLF) or {}
		local function enc(c) return { c.R, c.G, c.B } end
		local function dec(t)
			if type(t) == "table" and tonumber(t[1]) and tonumber(t[2]) and tonumber(t[3]) then
				return Color3.new(math.clamp(t[1], 0, 1), math.clamp(t[2], 0, 1), math.clamp(t[3], 0, 1))
			end
		end
		local function pack()
			return {
				A1 = enc(Theme.A1), A2 = enc(Theme.A2), Scale = Theme.Scale, Opacity = Theme.Opacity,
				AuraPower = Theme.AuraPower, Round = Theme.Round, Volume = Theme.Volume, FontIndex = Theme.FontIndex,
				Aura = Theme.Aura, Particles = Theme.Particles, Rainbow = Theme.Rainbow, Spin = Theme.Spin,
			}
		end
		local function unpack(d)
			local a1, a2 = dec(d.A1), dec(d.A2)
			if a1 and a2 then Theme.A1, Theme.A2 = a1, a2 end
			local ranges = { Scale = { 0.6, 1.3 }, Opacity = { 0, 1 }, AuraPower = { 0, 1 }, Round = { 0, 2 }, Volume = { 0, 1 } }
			for k, r in pairs(ranges) do
				if type(d[k]) == "number" then Theme[k] = math.clamp(d[k], r[1], r[2]) end
			end
			for _, k in ipairs({ "Aura", "Particles", "Rainbow", "Spin" }) do
				if type(d[k]) == "boolean" then Theme[k] = d[k] end
			end
			if type(d.FontIndex) == "number" and Fonts[d.FontIndex] then Theme.FontIndex = d.FontIndex end
		end

		label(PT, "SAVE keeps the current look in a slot. LOAD brings it back. Press SAVE in Customize to keep it for next execute too.", 44, 1)
		for i = 1, 3 do
			local row = Instance.new("Frame")
			row.LayoutOrder = 10 + i
			row.Size = UDim2.new(1, -10, 0, 40)
			row.BackgroundTransparency = 1
			row.ZIndex = 15
			row.Parent = PT
			local sw = Instance.new("Frame", row)
			sw.Size = UDim2.new(0, 34, 0, 30)
			sw.Position = UDim2.new(0, 0, 0.5, -15)
			sw.BackgroundColor3 = Color3.new(1, 1, 1)
			sw.BorderSizePixel = 0
			sw.ZIndex = 15
			Instance.new("UICorner", sw).CornerRadius = UDim.new(0, 7)
			local sg2 = Instance.new("UIGradient", sw)
			local function paintSwatch()
				local d = slots[tostring(i)]
				local a1, a2 = d and dec(d.A1), d and dec(d.A2)
				if a1 and a2 then
					sg2.Color = ColorSequence.new(a1, a2)
				else
					sg2.Color = ColorSequence.new(Color3.fromRGB(70, 70, 90), Color3.fromRGB(40, 40, 55))
				end
			end
			paintSwatch()
			local lbl = Instance.new("TextLabel", row)
			lbl.Position = UDim2.new(0, 40, 0, 0)
			lbl.Size = UDim2.new(0, 58, 1, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = "SLOT " .. i
			lbl.TextColor3 = Theme.Text
			lbl.Font = Fonts[Theme.FontIndex]
			lbl.TextSize = 12
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.ZIndex = 15
			table.insert(Reg.texts, lbl)
			local sv = makeButton(row, "SAVE", UDim2.new(0, 56, 0, 30), 11, nil)
			sv.Position = UDim2.new(1, -120, 0.5, -15)
			sv.MouseButton1Click:Connect(function()
				slots[tostring(i)] = pack()
				local ok = writeJ(SLF, slots)
				paintSwatch()
				flash(sv, "SAVE", ok and "SAVED" or "NO FILE")
			end)
			local ld = makeButton(row, "LOAD", UDim2.new(0, 56, 0, 30), 11, nil)
			ld.Position = UDim2.new(1, -60, 0.5, -15)
			ld.MouseButton1Click:Connect(function()
				local d = slots[tostring(i)]
				if type(d) ~= "table" then flash(ld, "LOAD", "EMPTY") return end
				unpack(d)
				applyAll()
				if Theme._refresh then pcall(Theme._refresh) end
				flash(ld, "LOAD", "LOADED")
			end)
		end

		-- build the initial lists
		rebuildFav()
		rebuildKeys()
		Theme._refreshStars()
	end)
	if not okAll then warn("[AAYAN PREMIUM PACK] " .. tostring(errAll)) end
end

-- ======================================================================
-- LEADERBOARD TAB: avatar + username + badge (hub team + players in this server)
-- Edit MEMBERS below to add more people: { "RobloxUsername", "BADGE" }
-- GLOBAL leaderboard (everyone who ran the hub + how many times): paste your Cloudflare Worker URL in LB_URL.
-- ======================================================================
do
	local okL, errL = pcall(function()
		local MEMBERS = {
			{ "AAYAN_ZZZZ", "OWNER" },
			{ "mr_king7809", "CO OWNER" },
			{ "Rehan_mirzaa", "LOCAL CREDIT" },
		}
		-- ===== EXECUTION BADGES (edit the numbers here) =====
		local TIERS = {
			{ "BRONZE", 1, Color3.fromRGB(205, 127, 50) },
			{ "SILVER", 10, Color3.fromRGB(200, 206, 218) },
			{ "GOLD", 25, Color3.fromRGB(255, 205, 60) },
			{ "PLATINUM", 37, Color3.fromRGB(120, 235, 215) },
			{ "DIAMOND", 50, Color3.fromRGB(130, 215, 255) },
			{ "RAINBOW", 70, Color3.fromRGB(255, 120, 200) },
			{ "ALPHA", 100, Color3.fromRGB(215, 25, 45) },
		}
		local BADGE = {
			["OWNER"] = { Color3.fromRGB(255, 200, 60), 1 },
			["CO OWNER"] = { Color3.fromRGB(190, 90, 255), 2 },
			["LOCAL CREDIT"] = { Color3.fromRGB(80, 220, 255), 3 },
			["PLAYER"] = { Color3.fromRGB(150, 155, 195), 9 },
			["NEW"] = { Color3.fromRGB(150, 155, 195), 9 },
		}
		for _, t in ipairs(TIERS) do BADGE[t[1]] = { t[3], 8 } end
		local function tierOf(n)
			local r = TIERS[1][1]
			for _, t in ipairs(TIERS) do
				if n >= t[2] then r = t[1] end
			end
			return r
		end
		local OWNER_NAMES = { ["aayan_zzzz"] = true } -- these accounts can open + wear every badge
		local ownerMode = false
		local equipped = nil
		local chips = {} -- chips that have the shine / rainbow animation

		-- ===== GLOBAL LEADERBOARD SETTINGS =====
		local LB_URL = "https://aayan-lb.ahmadaayan400.workers.dev" -- global leaderboard server
		local LB_KEY = "AAYAN13BAP" -- same as KEY in the worker
		LB_URL = string.gsub(LB_URL, "/+$", "")
		local HS = game:GetService("HttpService")
		local canFile = type(isfile) == "function" and type(readfile) == "function" and type(writefile) == "function"
		local LBF = "AAYAN_HUB_V3_LB.json"
		local function readLB()
			if not canFile then return {} end
			local ok, r = pcall(function()
				if isfile(LBF) then return HS:JSONDecode(readfile(LBF)) end
			end)
			return (ok and type(r) == "table") and r or {}
		end
		local myRuns, lastRun, myCount = 0, 0, 0 -- my own execution counter (kept on this device)
		local saved0 = {}
		local function writeLB(t)
			for k, v in pairs(t) do saved0[k] = v end
			saved0.equip = equipped
			saved0.runs = myRuns
			saved0.lastRun = lastRun
			if canFile then pcall(function() writefile(LBF, HS:JSONEncode(saved0)) end) end
		end
		saved0 = readLB()
		myRuns = tonumber(saved0.runs) or 0
		lastRun = tonumber(saved0.lastRun) or 0
		if os.time() - lastRun >= 60 then -- same 60s rule as the server
			myRuns = myRuns + 1
			lastRun = os.time()
		end
		myCount = myRuns
		ownerMode = OWNER_NAMES[string.lower(player.Name)] == true
		if ownerMode then equipped = saved0.equip end
		local optin = true -- always sharing, no toggle
		local noticed = saved0.noticed == true -- has the one-time info notice been closed?
		writeLB({ optin = optin, noticed = noticed })
		local function httpReq(method, path, body)
			local rq = request or http_request or (syn and syn.request)
			if not rq or LB_URL == "" then return nil end
			local ok, res = pcall(rq, {
				Url = LB_URL .. path, Method = method,
				Headers = { ["Content-Type"] = "application/json" },
				Body = body and HS:JSONEncode(body) or nil,
			})
			if ok and res and res.StatusCode == 200 then
				local ok2, d = pcall(function() return HS:JSONDecode(res.Body) end)
				if ok2 and type(d) == "table" then return d end
			end
			return nil
		end
		local globalData = nil
		local function agoText(ms)
			local sec = math.max(os.time() - math.floor((tonumber(ms) or 0) / 1000), 0)
			if sec < 90 then return "just now" end
			if sec < 3600 then return math.floor(sec / 60) .. "m ago" end
			if sec < 86400 then return math.floor(sec / 3600) .. "h ago" end
			return math.floor(sec / 86400) .. "d ago"
		end
		local roleByName = {}
		for _, m in ipairs(MEMBERS) do roleByName[string.lower(m[1])] = m[2] end
		local idCache, imgCache = {}, {}

		local PL = createPage()
		local lbTab = tab("LEADERBOARD", PL)
		local infoOrder = 10
		for _, v in ipairs(Reg.tabs) do
			if string.find(string.upper(v.Text), "INFO", 1, true) then infoOrder = v.LayoutOrder break end
		end
		lbTab.LayoutOrder = infoOrder + 2 -- right after FAVORITES

		local function loadAvatar(img, uid)
			task.spawn(function()
				if imgCache[uid] == nil then
					local ok, r = pcall(function()
						return Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
					end)
					imgCache[uid] = ok and r or false
				end
				if img.Parent and imgCache[uid] then img.Image = imgCache[uid] end
			end)
		end
		local function resolveId(name, cb)
			task.spawn(function()
				if idCache[name] == nil then
					local ok, id = pcall(function() return Players:GetUserIdFromNameAsync(name) end)
					idCache[name] = ok and id or false
				end
				cb(idCache[name])
			end)
		end

		local function header(text, order, big)
			local l = Instance.new("TextLabel")
			l.Name = "LRow"
			l.LayoutOrder = order
			l.Size = UDim2.new(1, -10, 0, big and 38 or 22)
			l.BackgroundTransparency = 1
			l.Text = text
			l.TextColor3 = big and Theme.Text or Theme.Muted
			l.Font = big and Enum.Font.GothamBold or Fonts[Theme.FontIndex]
			l.TextSize = big and 12 or 11
			l.TextWrapped = true
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.ZIndex = 15
			table.insert(Reg.texts, l)
			l.Parent = PL
		end

		local function myTier()
			if ownerMode and equipped then return equipped end
			return (myCount >= 1) and tierOf(myCount) or "NEW"
		end

		local function makeChip(parent, role, size, ts, z)
			local info = BADGE[role] or BADGE["PLAYER"]
			local chip = Instance.new("TextLabel", parent)
			chip.Size = size
			chip.BackgroundColor3 = info[1]
			chip.BorderSizePixel = 0
			chip.Text = role
			chip.TextColor3 = (role == "ALPHA") and Color3.new(1, 1, 1) or Color3.fromRGB(15, 12, 25)
			chip.Font = Enum.Font.GothamBlack
			chip.TextSize = ts
			chip.ZIndex = z
			chip.ClipsDescendants = true
			Instance.new("UICorner", chip).CornerRadius = UDim.new(1, 0)
			local stroke = nil
			if role == "ALPHA" or role == "DIAMOND" or role == "PLATINUM" then
				stroke = Instance.new("UIStroke", chip)
				pcall(function() stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border end)
				stroke.Thickness = (role == "ALPHA") and 2 or 1.2
				stroke.Color = (role == "ALPHA") and Color3.fromRGB(255, 90, 90) or Color3.new(1, 1, 1)
			end
			local sh = Instance.new("Frame", chip)
			sh.Name = "Shine"
			sh.AnchorPoint = Vector2.new(0.5, 0.5)
			sh.Position = UDim2.new(-0.3, 0, 0.5, 0)
			sh.Size = UDim2.new(0, (role == "ALPHA") and 26 or 18, 2, 0)
			sh.Rotation = 20
			sh.BackgroundColor3 = Color3.new(1, 1, 1)
			sh.BorderSizePixel = 0
			sh.ZIndex = z + 1
			local shg = Instance.new("UIGradient", sh)
			shg.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, (role == "ALPHA") and 0 or 0.15), NumberSequenceKeypoint.new(1, 1),
			})
			table.insert(chips, { chip = chip, sh = sh, tier = role, ph = math.random(), stroke = stroke, base = info[1] })
			return chip
		end

		local function makeRow(order, rank, name, sub, role, uid, uidFn)
			local row = Instance.new("Frame")
			row.Name = "LRow"
			row.LayoutOrder = order
			row.Size = UDim2.new(1, -10, 0, 54)
			row.BackgroundColor3 = Theme._card
			row.BorderSizePixel = 0
			row.ZIndex = 14
			regCorner(row, 10)
			borderStroke(row, 1.1, 0.35)
			table.insert(Reg.cards, row)
			row.Parent = PL

			local rk = Instance.new("TextLabel", row)
			rk.Size = UDim2.new(0, 26, 1, 0)
			rk.Position = UDim2.new(0, 2, 0, 0)
			rk.BackgroundTransparency = 1
			rk.Text = rank and ("#" .. rank) or ""
			rk.TextColor3 = Theme.Muted
			rk.Font = Enum.Font.GothamBlack
			rk.TextSize = 12
			rk.ZIndex = 16

			local img = Instance.new("ImageLabel", row)
			img.Size = UDim2.new(0, 40, 0, 40)
			img.Position = UDim2.new(0, 30, 0.5, -20)
			img.BackgroundColor3 = Color3.fromRGB(20, 20, 34)
			img.BorderSizePixel = 0
			img.ZIndex = 16
			Instance.new("UICorner", img).CornerRadius = UDim.new(1, 0)
			if uid then loadAvatar(img, uid) elseif uidFn then
				resolveId(name, function(id)
					if id and img.Parent then loadAvatar(img, id) end
				end)
			end

			local nm = Instance.new("TextLabel", row)
			nm.Position = UDim2.new(0, 78, 0, 7)
			nm.Size = UDim2.new(1, -184, 0, 20)
			nm.BackgroundTransparency = 1
			nm.Text = name
			nm.TextColor3 = Theme.Text
			nm.Font = Enum.Font.GothamBold
			nm.TextSize = 14
			nm.TextXAlignment = Enum.TextXAlignment.Left
			nm.TextTruncate = Enum.TextTruncate.AtEnd
			nm.ZIndex = 16

			local sb = Instance.new("TextLabel", row)
			sb.Position = UDim2.new(0, 78, 0, 28)
			sb.Size = UDim2.new(1, -184, 0, 16)
			sb.BackgroundTransparency = 1
			sb.Text = sub
			sb.TextColor3 = (string.find(sub, "IN SERVER", 1, true) and Color3.fromRGB(90, 235, 140)) or Theme.Muted
			sb.Font = Enum.Font.GothamMedium
			sb.TextSize = 11
			sb.TextXAlignment = Enum.TextXAlignment.Left
			sb.TextTruncate = Enum.TextTruncate.AtEnd
			sb.ZIndex = 16

			if not role then return end
			local chip = makeChip(row, role, UDim2.new(0, 96, 0, 24), 10, 16)
			chip.AnchorPoint = Vector2.new(1, 0.5)
			chip.Position = UDim2.new(1, -8, 0.5, 0)
		end

		table.insert(Hooks, function(now)
			for i = #chips, 1, -1 do
				local c = chips[i]
				if not c.chip.Parent then
					table.remove(chips, i)
				else
					local speed = (c.tier == "ALPHA") and 1.5 or 0.6
					local x = ((now * speed + c.ph) % 2.2) / 2.2
					c.sh.Position = UDim2.new(-0.2 + x * 1.4, 0, 0.5, 0)
					if c.tier == "RAINBOW" then
						c.chip.BackgroundColor3 = Color3.fromHSV((now * 0.35 + c.ph) % 1, 0.6, 1)
					elseif c.tier == "DIAMOND" then
						local k = (math.sin(now * 2.2 + c.ph * 6) + 1) / 2
						c.chip.BackgroundColor3 = Color3.fromRGB(110, 200, 255):Lerp(Color3.fromRGB(235, 252, 255), k)
					elseif c.tier == "PLATINUM" then
						local k = (math.sin(now * 1.6 + c.ph * 6) + 1) / 2
						c.chip.BackgroundColor3 = Color3.fromRGB(100, 225, 205):Lerp(Color3.fromRGB(190, 255, 245), k)
					elseif c.tier == "ALPHA" then
						local k = (math.sin(now * 5 + c.ph * 6) + 1) / 2
						c.chip.BackgroundColor3 = Color3.fromRGB(120, 8, 24):Lerp(Color3.fromRGB(255, 35, 55), k)
						if c.stroke then
							c.stroke.Thickness = 1.5 + k * 2
							c.stroke.Color = Color3.fromRGB(255, 70, 70):Lerp(Color3.fromRGB(255, 200, 120), k)
						end
					end
				end
			end
		end)

		local function lastText(ms)
			local sec = math.floor((tonumber(ms) or 0) / 1000)
			local ok, d = pcall(os.date, "%d %b, %H:%M", sec)
			return agoText(ms) .. (ok and (" (" .. d .. ")") or "")
		end

		local function rebuild()
			for _, c in ipairs(PL:GetChildren()) do
				if c.Name == "LRow" then c:Destroy() end
			end
			local o = 1
			if LB_URL ~= "" then
				if globalData then
					header("TOTAL EXECUTIONS: " .. tostring(globalData.runs or 0) .. "   |   PLAYERS: " .. tostring(globalData.users or 0)
						.. "\nONLINE NOW: " .. tostring(globalData.online or 0), -2, true)
				else
					header("TOTAL EXECUTIONS: ...\nONLINE NOW: ...", -2, true)
				end
			end
			if LB_URL == "" then
				header("Leaderboard is OFF. Put your Worker URL in LB_URL inside the script.", o)
			elseif not globalData then
				header("Loading... (or server not reachable)", o)
			elseif #(globalData.top or {}) == 0 then
				header("No runs recorded yet.", o)
			else
				for i, u in ipairs(globalData.top or {}) do
					local cnt = tonumber(u.count) or 0
					if tonumber(u.id) == player.UserId and optin == true and myCount > cnt then cnt = myCount end -- my row = same number as my header badge
					makeRow(o, i, tostring(u.name),
						"Runs: " .. tostring(cnt) .. "   |   Last run: " .. lastText(u.last_seen),
						(tonumber(u.id) == player.UserId and optin == true) and myTier() or tierOf(cnt), tonumber(u.id), false)
					o = o + 1
				end
			end
		end

		local refreshB = makeButton(PL, "REFRESH", UDim2.new(1, -10, 0, 30), 12, nil)
		refreshB.LayoutOrder = 0
		refreshB.MouseButton1Click:Connect(rebuild)

		local function fetchGlobal()
			if LB_URL == "" then return end
			task.spawn(function()
				local d = httpReq("GET", "/top?limit=50")
				if d then globalData = d end
				rebuild()
			end)
		end
		local refreshBadge = function() end -- filled in below (header badge + secret page)
		local function sendHit()
			task.spawn(function()
				local d = httpReq("POST", "/hit", { userId = player.UserId, name = player.Name, display = player.DisplayName, key = LB_KEY })
				if d and tonumber(d.count) and tonumber(d.count) > myCount then
					myCount = tonumber(d.count)
					myRuns = math.max(myRuns, myCount)
					writeLB({})
					refreshBadge()
				end
				fetchGlobal()
			end)
		end

		-- ===== MY BADGE (top-left of the hub, next to the title) + SECRET BADGES PAGE =====
		local PB = createPage() -- secret page: no sidebar tab, opened by clicking the badge
		local badgeBtn = Instance.new("TextButton", Main)
		badgeBtn.Name = "MyBadgeBtn"
		badgeBtn.Position = UDim2.new(0, 12, 0, 9)
		badgeBtn.Size = UDim2.new(0, 80, 0, 22)
		badgeBtn.BackgroundTransparency = 1
		badgeBtn.Text = ""
		badgeBtn.AutoButtonColor = false
		badgeBtn.ZIndex = 20
		local myChip = nil

		local function buildBadgePage()
			for _, c in ipairs(PB:GetChildren()) do
				if c.Name == "BRow" then c:Destroy() end
			end
			local function line(text, order, h, bold, col)
				local l = Instance.new("TextLabel")
				l.Name = "BRow"
				l.LayoutOrder = order
				l.Size = UDim2.new(1, -10, 0, h)
				l.BackgroundTransparency = 1
				l.Text = text
				l.TextColor3 = col or Theme.Muted
				l.Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium
				l.TextSize = bold and 13 or 11
				l.TextWrapped = true
				l.TextXAlignment = Enum.TextXAlignment.Left
				l.ZIndex = 15
				l.Parent = PB
			end
			line("SECRET BADGES", 0, 22, true, Theme.Text)
			local nextT = nil
			for _, t in ipairs(TIERS) do
				if myCount < t[2] and not nextT then nextT = t end
			end
			local msg = "Your executions: " .. myCount
			if nextT then
				msg = msg .. "   |   Next: " .. nextT[1] .. " at " .. nextT[2] .. " (" .. (nextT[2] - myCount) .. " more)"
			else
				msg = msg .. "   |   MAX BADGE UNLOCKED"
			end
			line(msg, 1, 34, false, Theme.Muted)
			local cur = myTier()
			if ownerMode then line("OWNER: all badges are open. Tap a badge to wear it.", 2, 20, false, Theme.Text) end
			for i, t in ipairs(TIERS) do
				local open = ownerMode or myCount >= t[2]
				local row = Instance.new("Frame")
				row.Name = "BRow"
				row.LayoutOrder = 10 + i
				row.Size = UDim2.new(1, -10, 0, 50)
				row.BackgroundColor3 = Theme._card
				row.BorderSizePixel = 0
				row.ZIndex = 14
				regCorner(row, 10)
				borderStroke(row, 1.1, 0.35)
				table.insert(Reg.cards, row)
				row.Parent = PB
				local ch = makeChip(row, t[1], UDim2.new(0, 96, 0, 24), 10, 16)
				ch.Position = UDim2.new(0, 8, 0, 8)
				if not open then
					ch.BackgroundTransparency = 0.6
					ch.TextTransparency = 0.4
				end
				local need = Instance.new("TextLabel", row)
				need.Position = UDim2.new(0, 112, 0, 6)
				need.Size = UDim2.new(1, -120, 0, 18)
				need.BackgroundTransparency = 1
				need.Text = t[2] .. "+ executions" .. ((cur == t[1]) and "   (YOUR BADGE)" or "")
				need.TextColor3 = Theme.Text
				need.Font = Enum.Font.GothamBold
				need.TextSize = 12
				need.TextXAlignment = Enum.TextXAlignment.Left
				need.ZIndex = 16
				local st = Instance.new("TextLabel", row)
				st.Position = UDim2.new(0, 112, 0, 24)
				st.Size = UDim2.new(1, -120, 0, 16)
				st.BackgroundTransparency = 1
				st.Text = open and "UNLOCKED" or ("LOCKED - " .. (t[2] - myCount) .. " more executions")
				st.TextColor3 = open and Color3.fromRGB(90, 235, 140) or Theme.Muted
				st.Font = Enum.Font.GothamMedium
				st.TextSize = 11
				st.TextXAlignment = Enum.TextXAlignment.Left
				st.ZIndex = 16
				local bg = Instance.new("Frame", row)
				bg.Position = UDim2.new(0, 8, 1, -8)
				bg.Size = UDim2.new(1, -16, 0, 3)
				bg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
				bg.BorderSizePixel = 0
				bg.ZIndex = 16
				local fill = Instance.new("Frame", bg)
				fill.Size = UDim2.new(math.min(myCount / t[2], 1), 0, 1, 0)
				fill.BackgroundColor3 = t[3]
				fill.BorderSizePixel = 0
				fill.ZIndex = 17
				if ownerMode then
					local pick = Instance.new("TextButton", row)
					pick.Size = UDim2.new(1, 0, 1, 0)
					pick.BackgroundTransparency = 1
					pick.Text = ""
					pick.ZIndex = 30
					pick.MouseButton1Click:Connect(function()
						equipped = t[1]
						writeLB({})
						refreshBadge()
						rebuild()
					end)
				end
			end
			line("Open any tab on the left to go back.", 99, 20, false, Theme.Muted)
		end

		refreshBadge = function()
			if myChip then myChip:Destroy() myChip = nil end
			local role = myTier()
			myChip = makeChip(badgeBtn, role, UDim2.new(1, 0, 1, 0), 10, 21)
			if PB.Visible then buildBadgePage() end
		end

		badgeBtn.MouseButton1Click:Connect(function()
			for _, v in ipairs(Pages:GetChildren()) do
				if v:IsA("ScrollingFrame") then v.Visible = false end
			end
			if activeTab then
				setTabLook(activeTab, "normal")
				activeTab = nil
			end
			buildBadgePage()
			PB.Position = UDim2.new(0, 18, 0, 0)
			PB.Visible = true
			tween(PB, 0.25, { Position = UDim2.new(0, 0, 0, 0) })
		end)
		refreshBadge()

		-- every 2 min: tell the server I am still here (only if sharing is ON) + refresh the numbers
		task.spawn(function()
			while sg.Parent do
				task.wait(120)
				if not sg.Parent then break end
				if optin == true then
					httpReq("POST", "/ping", { userId = player.UserId, key = LB_KEY })
				end
				fetchGlobal()
			end
		end)

		if LB_URL ~= "" then
			-- first run: one-time info notice (join is automatic, always on)
			if not noticed then
				local m = Instance.new("Frame", sg)
				m.AnchorPoint = Vector2.new(0.5, 0.5)
				m.Position = UDim2.new(0.5, 0, 0.5, 0)
				m.Size = UDim2.new(0, 300, 0, 170)
				m.BackgroundColor3 = Theme._card
				m.BorderSizePixel = 0
				m.ZIndex = 400
				regCorner(m, 14)
				borderStroke(m, 2, 0.1)
				table.insert(Reg.cards, m)
				local mt = Instance.new("TextLabel", m)
				mt.Position = UDim2.new(0, 14, 0, 10)
				mt.Size = UDim2.new(1, -28, 0, 22)
				mt.BackgroundTransparency = 1
				mt.Text = "YOU ARE ON THE LEADERBOARD"
				mt.TextColor3 = Theme.Text
				mt.Font = Enum.Font.GothamBlack
				mt.TextSize = 14
				mt.ZIndex = 401
				local mb = Instance.new("TextLabel", m)
				mb.Position = UDim2.new(0, 14, 0, 36)
				mb.Size = UDim2.new(1, -28, 0, 80)
				mb.BackgroundTransparency = 1
				mb.Text = "Your Roblox username, how many times you ran this hub, when you last ran it and that you are online are shown on the hub leaderboard."
				mb.TextColor3 = Theme.Muted
				mb.Font = Enum.Font.Gotham
				mb.TextSize = 11
				mb.TextWrapped = true
				mb.TextXAlignment = Enum.TextXAlignment.Left
				mb.TextYAlignment = Enum.TextYAlignment.Top
				mb.ZIndex = 401
				local ok1 = makeButton(m, "OK", UDim2.new(1, -28, 0, 32), 12, nil)
				ok1.Position = UDim2.new(0, 14, 1, -44)
				ok1.ZIndex = 402
				ok1.MouseButton1Click:Connect(function()
					noticed = true
					writeLB({ noticed = true })
					m:Destroy()
				end)
			end
		end

		local tok = 0
		local function soon()
			tok = tok + 1
			local my = tok
			task.delay(0.5, function() if my == tok then rebuild() end end)
		end
		rebuild()
		if optin == true then sendHit() else fetchGlobal() end
	end)
	if not okL then warn("[AAYAN LEADERBOARD] " .. tostring(errL)) end
end

-- ======================================================================
-- 🌍 CHAT TAB: global chat, visible to every player running the hub.
-- Messages are never deleted (permanent, stored on the chat server).
-- Uses its own Cloudflare Worker + D1 database (CHATDB) via the same
-- worker URL as the leaderboard, under the /chat/* routes.
-- ======================================================================
do
	local okC, errC = pcall(function()
		local HS2 = game:GetService("HttpService")
		local CHAT_URL = "https://aayan-lb.ahmadaayan400.workers.dev"
		local CHAT_KEY = "AAYAN13BAP"
		CHAT_URL = string.gsub(CHAT_URL, "/+$", "")

		local function chatReq(method, path, body)
			local rq = request or http_request or (syn and syn.request)
			if not rq or CHAT_URL == "" then return nil end
			local ok, res = pcall(rq, {
				Url = CHAT_URL .. path, Method = method,
				Headers = { ["Content-Type"] = "application/json" },
				Body = body and HS2:JSONEncode(body) or nil,
			})
			if ok and res and res.StatusCode == 200 then
				local ok2, d = pcall(function() return HS2:JSONDecode(res.Body) end)
				if ok2 and type(d) == "table" then return d end
			end
			return nil
		end

		local canFile = type(isfile) == "function" and type(readfile) == "function" and type(writefile) == "function"
		local CHAT_FILE = "AAYAN_HUB_V3_CHAT.json"
		local function readChat()
			if not canFile then return {} end
			local ok, r = pcall(function()
				if isfile(CHAT_FILE) then return HS2:JSONDecode(readfile(CHAT_FILE)) end
			end)
			return (ok and type(r) == "table") and r or {}
		end
		local savedC = readChat()
		local lastSeenId = tonumber(savedC.lastId) or 0
		local function writeChat()
			if canFile then pcall(function() writefile(CHAT_FILE, HS2:JSONEncode({ lastId = lastSeenId })) end) end
		end

		local seenIds = {}
		local msgReactions = {}
		local rowsById = {}
		local avImgCache = {}

		local function getAvatar(uid, cb)
			task.spawn(function()
				if avImgCache[uid] == nil then
					local ok, r = pcall(function()
						return Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
					end)
					avImgCache[uid] = ok and r or false
				end
				if avImgCache[uid] then cb(avImgCache[uid]) end
			end)
		end

		local function agoTextC(ms)
			local sec = math.max(os.time() - math.floor((tonumber(ms) or 0) / 1000), 0)
			if sec < 60 then return "just now" end
			if sec < 3600 then return math.floor(sec / 60) .. "m" end
			if sec < 86400 then return math.floor(sec / 3600) .. "h" end
			return math.floor(sec / 86400) .. "d"
		end

		local QUICK_EMOJIS = { "❤️", "🔥", "😂", "👍" }
		local PICKER_EMOJIS = { "🔥", "😂", "💀", "😭", "💯", "🫡", "👑", "🗿", "🤡", "❤️", "👍", "😎" }
		local emojiAnim = {} -- {scaleObj=UIScale, phase=number} pulsed by the global Hooks loop

		local function animatedEmojiBtn(parent, emoji, size, onClick)
			local b = Instance.new("TextButton", parent)
			b.Size = size
			b.BackgroundColor3 = Theme._n
			b.BorderSizePixel = 0
			b.Text = emoji
			b.TextScaled = true
			b.AutoButtonColor = false
			b.ZIndex = 25
			regCorner(b, 8)
			table.insert(Reg.cards, b)
			local sc = Instance.new("UIScale", b)
			table.insert(emojiAnim, { s = sc, ph = math.random() * 6.28 })
			b.MouseButton1Click:Connect(function()
				if onClick then onClick(emoji) end
			end)
			return b
		end

		table.insert(Hooks, function(now)
			for i = #emojiAnim, 1, -1 do
				local e = emojiAnim[i]
				if not e.s.Parent then
					table.remove(emojiAnim, i)
				else
					e.s.Scale = 1 + math.sin(now * 3 + e.ph) * 0.08
				end
			end
		end)

		-- ===== PAGE + TAB (placed right after LEADERBOARD in the sidebar) =====
		local PCHAT = createPage()
		local chatPad = Instance.new("UIPadding", PCHAT)
		chatPad.PaddingBottom = UDim.new(0, 56)

		local chatTabBtn = tab("🌍 CHAT", PCHAT)
		local lbOrder = 100
		for _, v in ipairs(Reg.tabs) do
			if v.Text == "LEADERBOARD" then
				lbOrder = v.LayoutOrder
				break
			end
		end
		chatTabBtn.LayoutOrder = lbOrder + 1

		local function headerC(text, order)
			local l = Instance.new("TextLabel")
			l.Name = "CRow"
			l.LayoutOrder = order
			l.Size = UDim2.new(1, -10, 0, 22)
			l.BackgroundTransparency = 1
			l.Text = text
			l.TextColor3 = Theme.Muted
			l.Font = Fonts[Theme.FontIndex]
			l.TextSize = 11
			l.TextWrapped = true
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.ZIndex = 15
			table.insert(Reg.texts, l)
			l.Parent = PCHAT
		end
		headerC("🌍 GLOBAL CHAT — messages are public and never deleted.", -1000)

		local function scrollToBottom()
			task.defer(function()
				task.wait()
				PCHAT.CanvasPosition = Vector2.new(0, math.max(0, PCHAT.CanvasSize.Y.Offset))
			end)
		end

		local function renderReactions(pillRow, id)
			for _, c in ipairs(pillRow:GetChildren()) do
				if c.Name ~= "AddReact" then c:Destroy() end
			end
			local counts = msgReactions[id] or {}
			local order = 0
			for emoji, cnt in pairs(counts) do
				if cnt and cnt > 0 then
					order = order + 1
					local pill = Instance.new("TextLabel", pillRow)
					pill.LayoutOrder = order
					pill.Size = UDim2.new(0, 0, 0, 22)
					pill.AutomaticSize = Enum.AutomaticSize.X
					pill.BackgroundColor3 = Theme._field
					pill.BorderSizePixel = 0
					pill.Text = "  " .. emoji .. " " .. tostring(cnt) .. "  "
					pill.TextColor3 = Theme.Text
					pill.Font = Enum.Font.GothamBold
					pill.TextSize = 12
					pill.ZIndex = 16
					regCorner(pill, 10)
					table.insert(Reg.cards, pill)
					table.insert(Reg.texts, pill)
				end
			end
		end

		local function sendReact(id, emoji, pillRow)
			task.spawn(function()
				local d = chatReq("POST", "/chat/react", { userId = player.UserId, messageId = id, emoji = emoji, key = CHAT_KEY })
				if d and d.reactions then
					msgReactions[id] = d.reactions
					renderReactions(pillRow, id)
				end
			end)
		end

		local function addMsgRow(m)
			if rowsById[m.id] then return end
			local row = Instance.new("Frame")
			row.Name = "CRow"
			row.LayoutOrder = m.id
			row.Size = UDim2.new(1, -10, 0, 0)
			row.AutomaticSize = Enum.AutomaticSize.Y
			row.BackgroundColor3 = Theme._card
			row.BorderSizePixel = 0
			row.ZIndex = 14
			regCorner(row, 10)
			borderStroke(row, 1.1, 0.45)
			table.insert(Reg.cards, row)
			row.Parent = PCHAT
			rowsById[m.id] = row

			local rowPad = Instance.new("UIPadding", row)
			rowPad.PaddingTop = UDim.new(0, 8)
			rowPad.PaddingBottom = UDim.new(0, 8)
			rowPad.PaddingLeft = UDim.new(0, 8)
			rowPad.PaddingRight = UDim.new(0, 8)

			local list = Instance.new("UIListLayout", row)
			list.Padding = UDim.new(0, 4)
			list.SortOrder = Enum.SortOrder.LayoutOrder

			local top = Instance.new("Frame", row)
			top.LayoutOrder = 1
			top.Size = UDim2.new(1, 0, 0, 34)
			top.BackgroundTransparency = 1

			local img = Instance.new("ImageLabel", top)
			img.Size = UDim2.new(0, 30, 0, 30)
			img.Position = UDim2.new(0, 0, 0.5, -15)
			img.BackgroundColor3 = Color3.fromRGB(20, 20, 34)
			img.BorderSizePixel = 0
			img.ZIndex = 16
			Instance.new("UICorner", img).CornerRadius = UDim.new(1, 0)
			getAvatar(tonumber(m.userId) or 0, function(uri)
				if img.Parent then img.Image = uri end
			end)

			local nm = Instance.new("TextLabel", top)
			nm.Position = UDim2.new(0, 40, 0, 0)
			nm.Size = UDim2.new(1, -110, 1, 0)
			nm.BackgroundTransparency = 1
			nm.Text = tostring(m.display or m.name)
			nm.TextColor3 = Theme.Text
			nm.Font = Enum.Font.GothamBold
			nm.TextSize = 14
			nm.TextXAlignment = Enum.TextXAlignment.Left
			nm.TextTruncate = Enum.TextTruncate.AtEnd
			nm.ZIndex = 16
			table.insert(Reg.texts, nm)

			local tm = Instance.new("TextLabel", top)
			tm.AnchorPoint = Vector2.new(1, 0)
			tm.Position = UDim2.new(1, 0, 0, 0)
			tm.Size = UDim2.new(0, 60, 1, 0)
			tm.BackgroundTransparency = 1
			tm.Text = agoTextC(m.ts)
			tm.TextColor3 = Theme.Muted
			tm.Font = Enum.Font.GothamMedium
			tm.TextSize = 10
			tm.TextXAlignment = Enum.TextXAlignment.Right
			tm.ZIndex = 16

			local txt = Instance.new("TextLabel", row)
			txt.Name = "Body"
			txt.LayoutOrder = 2
			txt.Size = UDim2.new(1, 0, 0, 0)
			txt.AutomaticSize = Enum.AutomaticSize.Y
			txt.BackgroundTransparency = 1
			txt.Text = tostring(m.text)
			txt.TextColor3 = Theme.Text
			txt.Font = Fonts[Theme.FontIndex]
			txt.TextSize = 13
			txt.TextWrapped = true
			txt.TextXAlignment = Enum.TextXAlignment.Left
			txt.ZIndex = 16
			table.insert(Reg.texts, txt)

			local pillRow = Instance.new("Frame", row)
			pillRow.Name = "Pills"
			pillRow.LayoutOrder = 3
			pillRow.Size = UDim2.new(1, 0, 0, 26)
			pillRow.BackgroundTransparency = 1
			local pl = Instance.new("UIListLayout", pillRow)
			pl.FillDirection = Enum.FillDirection.Horizontal
			pl.Padding = UDim.new(0, 6)
			pl.VerticalAlignment = Enum.VerticalAlignment.Center

			local addReact = Instance.new("TextButton")
			addReact.Name = "AddReact"
			addReact.LayoutOrder = 999
			addReact.Size = UDim2.new(0, 26, 0, 22)
			addReact.BackgroundColor3 = Theme._n
			addReact.BorderSizePixel = 0
			addReact.Text = "➕"
			addReact.TextScaled = true
			addReact.AutoButtonColor = false
			addReact.ZIndex = 16
			regCorner(addReact, 10)
			table.insert(Reg.cards, addReact)
			addReact.Parent = pillRow

			local quick = Instance.new("Frame", row)
			quick.Name = "Quick"
			quick.LayoutOrder = 4
			quick.Size = UDim2.new(0, 0, 0, 28)
			quick.AutomaticSize = Enum.AutomaticSize.X
			quick.BackgroundTransparency = 1
			quick.Visible = false
			local ql = Instance.new("UIListLayout", quick)
			ql.FillDirection = Enum.FillDirection.Horizontal
			ql.Padding = UDim.new(0, 4)
			for _, e in ipairs(QUICK_EMOJIS) do
				animatedEmojiBtn(quick, e, UDim2.new(0, 28, 0, 28), function(emoji)
					quick.Visible = false
					sendReact(m.id, emoji, pillRow)
				end)
			end
			addReact.MouseButton1Click:Connect(function()
				quick.Visible = not quick.Visible
			end)

			renderReactions(pillRow, m.id)
		end

		-- ===== notification toast queue (shows for messages from others) =====
		local toastQueue = {}
		local function jumpToChat()
			for _, v in ipairs(Pages:GetChildren()) do
				if v:IsA("ScrollingFrame") then v.Visible = false end
			end
			if activeTab and activeTab ~= chatTabBtn then setTabLook(activeTab, "normal") end
			activeTab = chatTabBtn
			setTabLook(chatTabBtn, "active")
			PCHAT.Position = UDim2.new(0, 18, 0, 0)
			PCHAT.Visible = true
			tween(PCHAT, 0.25, { Position = UDim2.new(0, 0, 0, 0) })
			scrollToBottom()
		end

		local function showToast(uid, name, text)
			local toast = Instance.new("TextButton")
			toast.AnchorPoint = Vector2.new(0.5, 0)
			toast.Position = UDim2.new(0.5, 0, 0, -70)
			toast.Size = UDim2.new(0, 300, 0, 52)
			toast.BackgroundColor3 = Color3.fromRGB(14, 16, 38)
			toast.BorderSizePixel = 0
			toast.Text = ""
			toast.AutoButtonColor = false
			toast.ZIndex = 200
			toast.Parent = sg
			Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 14)
			borderStroke(toast, 1.6, 0.1)

			local img = Instance.new("ImageLabel", toast)
			img.Position = UDim2.new(0, 8, 0.5, -16)
			img.Size = UDim2.new(0, 32, 0, 32)
			img.BackgroundColor3 = Color3.fromRGB(20, 20, 34)
			img.BorderSizePixel = 0
			img.ZIndex = 201
			Instance.new("UICorner", img).CornerRadius = UDim.new(1, 0)
			getAvatar(tonumber(uid) or 0, function(uri)
				if img.Parent then img.Image = uri end
			end)

			local nm = Instance.new("TextLabel", toast)
			nm.Position = UDim2.new(0, 48, 0, 6)
			nm.Size = UDim2.new(1, -56, 0, 18)
			nm.BackgroundTransparency = 1
			nm.Text = tostring(name) .. "  sent a message"
			nm.TextColor3 = Color3.new(1, 1, 1)
			nm.Font = Enum.Font.GothamBold
			nm.TextSize = 13
			nm.TextXAlignment = Enum.TextXAlignment.Left
			nm.TextTruncate = Enum.TextTruncate.AtEnd
			nm.ZIndex = 201

			local bd = Instance.new("TextLabel", toast)
			bd.Position = UDim2.new(0, 48, 0, 24)
			bd.Size = UDim2.new(1, -56, 0, 20)
			bd.BackgroundTransparency = 1
			bd.Text = tostring(text)
			bd.TextColor3 = Color3.fromRGB(190, 195, 220)
			bd.Font = Enum.Font.GothamMedium
			bd.TextSize = 12
			bd.TextXAlignment = Enum.TextXAlignment.Left
			bd.TextTruncate = Enum.TextTruncate.AtEnd
			bd.ZIndex = 201

			toast.MouseButton1Click:Connect(function()
				jumpToChat()
				tween(toast, 0.25, { Position = UDim2.new(0.5, 0, 0, -70) })
			end)

			tween(toast, 0.35, { Position = UDim2.new(0.5, 0, 0, 64) }, Enum.EasingStyle.Back)
			task.wait(2.6)
			if toast.Parent then
				local out = tween(toast, 0.3, { Position = UDim2.new(0.5, 0, 0, -70) })
				out.Completed:Wait()
				toast:Destroy()
			end
		end

		task.spawn(function()
			while true do
				if #toastQueue > 0 then
					local t = table.remove(toastQueue, 1)
					pcall(showToast, t.uid, t.name, t.text)
				else
					task.wait(0.25)
				end
			end
		end)

		local function pushToast(uid, name, text)
			if #toastQueue > 4 then table.remove(toastQueue, 1) end
			table.insert(toastQueue, { uid = uid, name = name, text = text })
		end

		local function ingest(messages)
			local any = false
			for _, m in ipairs(messages) do
				if not seenIds[m.id] then
					seenIds[m.id] = true
					msgReactions[m.id] = m.reactions or {}
					addMsgRow(m)
					if m.id > lastSeenId then lastSeenId = m.id end
					any = true
					if tonumber(m.userId) ~= player.UserId then
						pushToast(m.userId, m.display or m.name, m.text)
					end
				end
			end
			if any then
				writeChat()
				if activeTab == chatTabBtn then scrollToBottom() end
			end
			return any
		end

		-- ===== bottom input bar (always on top, visible only while CHAT tab is open) =====
		local chatBar = Instance.new("Frame", Main)
		chatBar.Name = "ChatBar"
		chatBar.AnchorPoint = Vector2.new(0, 1)
		chatBar.Position = UDim2.new(0, 148, 1, -14)
		chatBar.Size = UDim2.new(1, -160, 0, 44)
		chatBar.BackgroundColor3 = Theme._card
		chatBar.BorderSizePixel = 0
		chatBar.ZIndex = 20
		chatBar.Visible = false
		regCorner(chatBar, 10)
		borderStroke(chatBar, 1.2, 0.3)
		table.insert(Reg.cards, chatBar)

		table.insert(Hooks, function(now)
			if chatBar.Parent then
				chatBar.Visible = (activeTab == chatTabBtn)
			end
		end)

		local emojiToggle = Instance.new("TextButton", chatBar)
		emojiToggle.Position = UDim2.new(0, 6, 0.5, -17)
		emojiToggle.Size = UDim2.new(0, 34, 0, 34)
		emojiToggle.BackgroundColor3 = Theme._n
		emojiToggle.BorderSizePixel = 0
		emojiToggle.Text = "😊"
		emojiToggle.TextScaled = true
		emojiToggle.AutoButtonColor = false
		emojiToggle.ZIndex = 21
		regCorner(emojiToggle, 8)
		table.insert(Reg.cards, emojiToggle)

		local box = Instance.new("TextBox", chatBar)
		box.Position = UDim2.new(0, 46, 0.5, -17)
		box.Size = UDim2.new(1, -116, 0, 34)
		box.BackgroundColor3 = Theme._field
		box.BorderSizePixel = 0
		box.PlaceholderText = "Type a message..."
		box.PlaceholderColor3 = Theme.Muted
		box.Text = ""
		box.TextColor3 = Theme.Text
		box.Font = Fonts[Theme.FontIndex]
		box.TextSize = 13
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.ClearTextOnFocus = false
		box.ClipsDescendants = true
		box.ZIndex = 21
		regCorner(box, 8)
		table.insert(Reg.fields, box)
		table.insert(Reg.texts, box)
		local boxPad = Instance.new("UIPadding", box)
		boxPad.PaddingLeft = UDim.new(0, 8)
		boxPad.PaddingRight = UDim.new(0, 8)

		local sendBtn = Instance.new("TextButton", chatBar)
		sendBtn.AnchorPoint = Vector2.new(1, 0.5)
		sendBtn.Position = UDim2.new(1, -6, 0.5, 0)
		sendBtn.Size = UDim2.new(0, 60, 0, 34)
		sendBtn.BackgroundColor3 = Theme._a
		sendBtn.BorderSizePixel = 0
		sendBtn.Text = "SEND"
		sendBtn.TextColor3 = Color3.new(1, 1, 1)
		sendBtn.Font = Enum.Font.GothamBlack
		sendBtn.TextSize = 13
		sendBtn.AutoButtonColor = false
		sendBtn.ZIndex = 21
		regCorner(sendBtn, 8)
		table.insert(Reg.cards, sendBtn)

		local picker = Instance.new("Frame", Main)
		picker.Name = "ChatEmojiPicker"
		picker.AnchorPoint = Vector2.new(0, 1)
		picker.Position = UDim2.new(0, 148, 1, -64)
		picker.Size = UDim2.new(0, 220, 0, 86)
		picker.BackgroundColor3 = Theme._card
		picker.BorderSizePixel = 0
		picker.ZIndex = 24
		picker.Visible = false
		regCorner(picker, 10)
		borderStroke(picker, 1.2, 0.2)
		table.insert(Reg.cards, picker)
		local grid = Instance.new("UIGridLayout", picker)
		grid.CellSize = UDim2.new(0, 32, 0, 32)
		grid.CellPadding = UDim2.new(0, 4, 0, 4)
		local pickerPad = Instance.new("UIPadding", picker)
		pickerPad.PaddingTop = UDim.new(0, 6)
		pickerPad.PaddingLeft = UDim.new(0, 6)

		for _, e in ipairs(PICKER_EMOJIS) do
			animatedEmojiBtn(picker, e, UDim2.new(0, 32, 0, 32), function(emoji)
				box.Text = box.Text .. emoji
			end)
		end

		emojiToggle.MouseButton1Click:Connect(function()
			picker.Visible = not picker.Visible
		end)

		table.insert(Hooks, function(now)
			if picker.Parent and activeTab ~= chatTabBtn then
				picker.Visible = false
			end
		end)

		local sending = false
		local function doSend()
			if sending then return end
			local text = box.Text:gsub("^%s+", ""):gsub("%s+$", "")
			if text == "" then return end
			if #text > 220 then text = text:sub(1, 220) end
			sending = true
			task.spawn(function()
				local d = chatReq("POST", "/chat/send", {
					userId = player.UserId, name = player.Name, display = player.DisplayName,
					text = text, key = CHAT_KEY,
				})
				if d and d.ok then
					box.Text = ""
					ingest({ { id = d.id, userId = player.UserId, name = player.Name, display = player.DisplayName, text = text, ts = d.ts, reactions = {} } })
				end
				sending = false
			end)
		end

		sendBtn.MouseButton1Click:Connect(doSend)
		box.FocusLost:Connect(function(enterPressed)
			if enterPressed then doSend() end
		end)

		-- ===== catch-up (everything missed while offline) then poll forever =====
		task.spawn(function()
			while true do
				local d = chatReq("GET", "/chat/messages?after=" .. tostring(lastSeenId) .. "&limit=100")
				if d and d.messages then
					ingest(d.messages)
					if #d.messages < 100 then break end
				else
					break
				end
			end
			while PCHAT.Parent do
				task.wait(2.5)
				local d = chatReq("GET", "/chat/messages?after=" .. tostring(lastSeenId) .. "&limit=50")
				if d and d.messages and #d.messages > 0 then
					ingest(d.messages)
				end
			end
		end)
	end)
	if not okC then warn("[AAYAN CHAT] " .. tostring(errC)) end
end

-- apply the theme to everything once, then open the main window
applyAll()
setMain(true)
