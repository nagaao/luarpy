
--[[ SERVICES ]]--

local TWEEN_SERVICE = game:GetService("TweenService")
local REPLICATED_STORAGE = game:GetService("ReplicatedStorage")
local USER_INPUT_SERVICE = game:GetService("UserInputService")
local SOUND_SERVICE = game:GetService("SoundService")
local DEBRIS = game:GetService("Debris")

local LuaRpy = {}
LuaRpy.__index = LuaRpy

--[[ HELPER FUNCTIONS ]]--

-- Returns a Property for tweens for a specific Instance with "part" for the exact property
local function RETURN_TWEEN_PROPERTY(part: string, obj: Instance): string
	
	if part == "Transparency" then
		if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			return "ImageTransparency"
		end
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			return "TextTransparency"
		end
		if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
			return "BackgroundTransparency"
		end
	end
	if part == "Color" then
		if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			return "ImageColor3"
		end
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			return "TextColor3"
		end
		if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
			return "BackgroundColor3"
		end
	end
	
end

-- Creates a new LuaRpy environment
function LuaRpy.new(args)
	assert(args ~= nil and typeof(args) == "table", "Arguments cannot be nil and must be type \"table\"")
	
	return setmetatable({
		-- STORY --
		
		DEFINED_OBJECTS = {},
		LABELS = {},
		SCENE_COUNT = 0,
		ACTIVE_TWEENS = {
			dissolve = {},
			fadeColor = {},
			fade = {},
			spriteTweens = {},
			audio = {}
		},
		autoDeemphasize = true,
		
		-- MISC --
		
		main_menu = args.menu,
		primary_interface = args.primary,
		project_name = _G.project_name,
		project_version = _G.project_version,
		copyright_holder = args.copyright_holder or nil,
	}, LuaRpy)
end

--[[ AUDIO CLASSES ]]--

-- Plays music that is stored in SoundService.Music, must be called by name. Fade boolean to add an intro fade.
function LuaRpy:playMusic(name: string, fade: boolean?)
	if self.currentMusic then
		self:stopMusic()
	end
	if SOUND_SERVICE.Music:FindFirstChild(name) then
		self.currentMusic = SOUND_SERVICE.Music:FindFirstChild(name)
		self.currentMusic:Play()
		if fade then
			local original: number = self.currentMusic.Volume
			self.currentMusic.Volume = 0
			TWEEN_SERVICE:Create(self.currentMusic, TweenInfo.new(1, Enum.EasingStyle.Linear), {Volume = original}):Play()
		end
	end
end

-- Stops the currentMusic from playing. If currentMusic switches mid tween, the old one will stop playing.
function LuaRpy:stopMusic()
	if self.currentMusic then
		local duration = 1
		local original: number = self.currentMusic.Volume
		local oldMusic: Sound = self.currentMusic
		TWEEN_SERVICE:Create(self.currentMusic, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Volume = 0}):Play()
		task.delay(duration, function()
			if oldMusic == self.currentMusic then
				self.currentMusic:Stop()
				self.currentMusic.Volume = original
				self.currentMusic = nil
			else
				oldMusic:Stop()
				oldMusic.Volume = original
			end
		end)
	end
end

-- This feature is not complete.
function LuaRpy:narrate(): Sound
	return false
end

--[[ TEXT CLASSES ]]--

-- Starts a "typewriting" type of effect on a TextLabel. Appends text if specified, and holds for a specified duration.
function LuaRpy:typeWrite(text: string, speed: number, textLabel: TextLabel, hold_dur: number?, append: string?, append_dur: number?): ()
	task.spawn(function()
		if self.typeWriting then
			self.typeWriting = nil
		end
		self.typeWriting = true
		
		textLabel.MaxVisibleGraphemes = 0
		textLabel.Text = text
		
		if append then
			textLabel.Text = append .. text
		end
		
		if self.primary_interface.Dialog:FindFirstChild("Continue") then
			self.primary_interface.Dialog.Continue.Visible = false
		end
		
		if speed > -1 then
			if append then
				for i = 1, string.len(append) do
					if not self.typeWriting then
						break
					end
					textLabel.MaxVisibleGraphemes = i
					task.wait(speed * _G.dialogSpeed)
				end
				if self.typeWriting then
					task.wait(append_dur or 1)
				end
				for i = string.len(append), string.len(append .. text) do
					if not self.typeWriting then
						break
					end
					textLabel.MaxVisibleGraphemes = i
					task.wait(speed * _G.dialogSpeed)
				end
			else
				for i = 1, string.len(text) do
					if not self.typeWriting then
						break
					end
					textLabel.MaxVisibleGraphemes = i
					task.wait(speed * _G.dialogSpeed)
				end
			end
		end
		textLabel.MaxVisibleGraphemes = -1

		if hold_dur then
			task.wait(hold_dur * _G.dialogSpeed)
		end
		
		if self.primary_interface.Dialog:FindFirstChild("Continue") then
			self.primary_interface.Dialog.Continue.Visible = true
		end

		self.typeWriting = nil
	end)
end

--[[ CHARACTER CLASSES ]]--

function LuaRpy:define(toDefine: {}): any
	assert(toDefine ~= nil and typeof(toDefine) == "table", "Argument #1 cannot be nil and must be type \"table\"")
	
	table.insert(self.DEFINED_OBJECTS, toDefine)
end

--[[ TRANSITION CLASSES ]]--


-- A transition that takes out_dur seconds to fade to a screen filled with color, holds at that screen for hold_dur seconds, and then takes in_dur to fade to then new screen.
function LuaRpy:fadeColor(out_dur: number, hold_dur: number, color: Color3, in_dur: number?, newColor: Color3?): ()
	for _, tween: Tween in self.ACTIVE_TWEENS.fadeColor do
		tween:Cancel()
	end

	local c1 = TWEEN_SERVICE:Create(self.primary_interface.CurrentScreen, TweenInfo.new(out_dur, Enum.EasingStyle.Linear), {BackgroundColor3 = color})

	table.insert(self.ACTIVE_TWEENS.fadeColor, c1)

	local c2
	if newColor then
		c2 = TWEEN_SERVICE:Create(self.primary_interface.CurrentScreen, TweenInfo.new(in_dur, Enum.EasingStyle.Linear), {BackgroundColor3 = newColor})
	end

	c1:Play()
	c1.Completed:Wait()
	task.wait(hold_dur)

	if c2 then
		c2:Play()
		c2.Completed:Wait()
		task.wait(hold_dur)
	end
end

-- A transition that takes out_dur seconds to fade to a GuiObject, holds at that screen for hold_dur seconds, and then takes in_dur to fade to then new screen (can be nil for a basic fade).
function LuaRpy:fade(out_dur: number, hold_dur: number, oldScreen: GuiObject, property: string, to: any): ()
	for _, tween: Tween in self.ACTIVE_TWEENS.fade do
		tween:Cancel()
	end
	
	local prop = RETURN_TWEEN_PROPERTY(property, oldScreen)

	local c1 = TWEEN_SERVICE:Create(oldScreen, TweenInfo.new(out_dur, Enum.EasingStyle.Linear), {[prop] = to})

	table.insert(self.ACTIVE_TWEENS.fade, c1)

	c1:Play()
	c1.Completed:Wait()
	task.wait(hold_dur)
end

-- This method yields. A transition that takes a set duration amount of time to dissolve from the old to the new screen.
function LuaRpy:dissolve(duration: number, hold_dur: number, oldScreen: GuiObject, newScreen: GuiObject?): ()
	for _, tween: Tween in self.ACTIVE_TWEENS.dissolve do
		tween:Cancel()
	end
	
	local Transparency = RETURN_TWEEN_PROPERTY("Transparency", oldScreen)
	
	local oldTween = TWEEN_SERVICE:Create(oldScreen, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0), {[Transparency] = 0})
	local oldTweenFade = TWEEN_SERVICE:Create(oldScreen, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0), {[Transparency] = 1})
	
	table.insert(self.ACTIVE_TWEENS.dissolve, oldTween)
	table.insert(self.ACTIVE_TWEENS.dissolve, oldTweenFade)
	
	local newTween
	if newScreen then
		newTween = TWEEN_SERVICE:Create(newScreen, TweenInfo.new(duration, Enum.EasingStyle.Linear), {[Transparency] = 0})
		table.insert(self.ACTIVE_TWEENS.dissolve, newTween)
	end

	oldTween:Play()
	oldTween.Completed:Wait()
	task.wait(hold_dur)
	
	oldTweenFade:Play()
	oldTweenFade.Completed:Wait()
	
	if newTween then
		newTween:Play()
		newTween.Completed:Wait()
		task.wait(hold_dur)
	end
end

--[[ MISCELLANEOUS CLASSES ]]--


-- Initiates the main menu with a custom callback.
function LuaRpy:initMenu(callback): ()
	self.main_menu.TitleScreen.Visible = true
	self.main_menu.TitleScreen.SideInformation.Project.Text = self.project_name
	self.main_menu.TitleScreen.SideInformation.Version.Text = self.project_version
	self.main_menu.TitleScreen.SideInformation.Copyright.Visible = self.copyright_holder ~= nil
	if self.copyright_holder then
		self.main_menu.TitleScreen.SideInformation.Copyright.Text = `© {self.copyright_holder} {os.date("!*t").year}`
	end
	
	if callback then
		task.spawn(callback)
	end
end

-- This method yields. Starts a splash screen cycle. out_dur is the duration per splashScreen part. hold_dur is the duration to yield after the cycle has ended.
function LuaRpy:splashScreen(out_dur: number, stall: number, hold_dur: number?): ()
	self.main_menu.splashScreen.Visible = true
	if hold_dur then
		task.wait(hold_dur)
	end
	for i = 1, #self.main_menu.splashScreen:GetChildren() do
		local part = self.main_menu.splashScreen:GetChildren()[i]		
		self:dissolve(out_dur, stall, part)
	end
	if hold_dur then
		task.wait(hold_dur)
	end
end

-- Requires a sprite that already exists in the LABELS table. If it exists, the sprite will tween with a "bounce".
function LuaRpy:bounceSprite(container: string, Y: number): ()
	for _, tween: Tween in self.ACTIVE_TWEENS.spriteTweens do
		tween:Cancel()
	end
	
	if self.LABELS[container] then
		container = self.LABELS[container]
		local old = container.Sprite.Position
		local tween1 = TWEEN_SERVICE:Create(container.Sprite, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Position = old - UDim2.new(0, 0, 0, Y)})
		local tween2 = TWEEN_SERVICE:Create(container.Sprite, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Position = old})
		
		table.insert(self.ACTIVE_TWEENS.spriteTweens, tween1)
		table.insert(self.ACTIVE_TWEENS.spriteTweens, tween2)
		
		task.spawn(function()
			tween1:Play()
			tween1.Completed:Wait()
			tween2:Play()
			tween2.Completed:Wait()
		end)
	end
end

-- "Emphasizes" an existing sprite by increasing its size. Plan to make this automatic. At the moment, it is a function that must be specifically called in the story.
function LuaRpy:emphasizeSprite(container: string): ()
	for _, tween: Tween in self.ACTIVE_TWEENS.spriteTweens do
		tween:Cancel()
	end
	
	if self.LABELS[container] then
		container = self.LABELS[container]
		local tween = TWEEN_SERVICE:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Size = container.Size + UDim2.new(0, 40, 0, 40)})
		table.insert(self.ACTIVE_TWEENS.spriteTweens, tween)
		tween:Play()
	end
end

-- "Deemphasizes" every existing sprite by decreasing size.
function LuaRpy:deemphasizeAll(): ()
	for _, tween: Tween in self.ACTIVE_TWEENS.spriteTweens do
		tween:Cancel()
	end
	
	for _, label in self.LABELS do
		local tween = TWEEN_SERVICE:Create(label, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Size = label:GetAttribute("OriginalSize")})
		table.insert(self.ACTIVE_TWEENS.spriteTweens, tween)
		tween:Play()
	end
end

-- Saves player progress with current scene. NOT DONE.
function LuaRpy:saveProgress(): ()
	REPLICATED_STORAGE.Save:FireServer(self.SCENE_COUNT)
end

-- Loads player progress from saved scenes in the player datastore. NOT DONE.
function LuaRpy:loadProgress(): ()
	return REPLICATED_STORAGE.Load:InvokeServer()
end

-- Yields until the "Start" button has been clicked.
function LuaRpy:waitForStart(): ()
	repeat
		task.wait()
	until self.started
end

-- Returns a defined object by its ID.
function LuaRpy:getObjectByID(ID: number)
	for _, v in self.DEFINED_OBJECTS do
		if v.ID == ID then
			return v
		end
	end
end

-- Starts the story.
function LuaRpy:startGame(SCENE_COUNT: number): ()
	self.started = true
	self.SCENE_COUNT = SCENE_COUNT or 1
	
	self.main_menu.Enabled = false
	self.primary_interface.Enabled = true
end

-- Initiates a scene.
function LuaRpy:doScene(scene: {}): ()
	self.primary_interface.Dialog.Speech.Text = ""
	self.primary_interface.Dialog.Character.charName.Text = ""
	self.primary_interface.Dialog.Character.charName.TextColor3 = Color3.fromRGB(0, 0, 0)
	self.primary_interface.Dialog.Speech.TextColor3 = Color3.fromRGB(0, 0, 0)
	self.primary_interface.Dialog.Visible = false
	
	if scene.Custom then
		scene.Custom(self)
	end
	
	if scene.music then
		self:playMusic(scene.music, scene.fadeMusic)
	end
	
	if scene.stopMusic then
		self:stopMusic()
	end
	
	if scene.sprites then
		for _, v in scene.sprites do
			local new = Instance.new("Frame")
			new.Parent = self.primary_interface["Active Sprites"]
			new.BackgroundTransparency = 1
			new.ZIndex = 2
			new.Name = v.n
			local sprite = Instance.new("ImageLabel")
			sprite.Parent = new
			sprite.Image = `rbxassetid://{v.image}`
			sprite.Name = "Sprite"
			sprite.BackgroundTransparency = 1
			sprite.ZIndex = 2
			sprite.Size = UDim2.fromScale(1, 1)
			new:SetAttribute("OriginalSize", v.size or UDim2.fromOffset(500, 500))
			if v.sizein then
				new.Size = UDim2.new()
				TWEEN_SERVICE:Create(new, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {Size = v.size or UDim2.fromOffset(500, 500)}):Play()
			else
				new.Size = v.size or UDim2.fromOffset(500, 500)
			end
			if v.fadein then
				sprite.ImageTransparency = 1
				TWEEN_SERVICE:Create(sprite, TweenInfo.new(1, Enum.EasingStyle.Linear), {ImageTransparency = 0}):Play()
			end
			if not self.LABELS[v.n] then
				self.LABELS[v.n] = new
			end
		end
	end
	
	if scene.spriteFunction then
		scene.spriteFunction(self)
	end
	
	if not scene.spriteFunction and not scene.forceDeemphasize and self.autoDeemphasize then
		self:deemphasizeAll()
	end
	
	if scene.clearSprites then
		local duration = 1 -- plan to make this not hard coded
		
		for _, sprite in self.LABELS do
			self.LABELS[sprite.Name] = nil
			TWEEN_SERVICE:Create(sprite.Sprite, TweenInfo.new(duration, Enum.EasingStyle.Linear), {ImageTransparency = 1}):Play()
			DEBRIS:AddItem(sprite, duration)
		end
	end
	
	if scene.screen then
		if scene.screen.image then
			self.primary_interface.CurrentScreen.Image = `rbxassetid://{scene.screen.image}`
		end
		if scene.screen.color and not scene.screen.transition then
			self.primary_interface.CurrentScreen.BackgroundColor3 = scene.screen.color
		end
		if scene.screen.imageTransition then
			if scene.screen.imageTransitionTransparency then
				self.primary_interface.CurrentScreen.ImageTransparency = math.clamp(1 - scene.screen.imageTransitionTransparency, 0, 1)
			else
				self.primary_interface.CurrentScreen.ImageTransparency = 1
			end
			self:fade(scene.screen.imageTransitionDur or 1.0, scene.screen.imageTransitionHoldDur or 0.0, self.primary_interface.CurrentScreen, "Transparency", scene.screen.imageTransitionTransparency or 0)
		end
		if scene.screen.color then
			if not scene.screen.image then
				self.primary_interface.CurrentScreen.Image = ""
			end
			if scene.screen.transition then
				self:fadeColor(scene.screen.transitionDur or 1.0, scene.screen.transitionHoldDur or 0.0, scene.screen.color, scene.screen.in_dur, scene.screen.in_color)
			end
		end
	end
	
	if scene.dialog then
		self.primary_interface.Dialog.Visible = true
		if scene.dialog.character then
			local char = self:getObjectByID(scene.dialog.character)
			self.primary_interface.Dialog.Character.Visible = true
			self.primary_interface.Dialog.Character.charName.Text = typeof(scene.dialog.character) == "number" and char.name or scene.dialog.character
			self.primary_interface.Dialog.Character.charName.TextColor3 = char ~= nil and char.color or Color3.fromRGB(255, 255, 255)
		else
			self.primary_interface.Dialog.Character.Visible = false
		end
		self.primary_interface.Dialog.Speech.TextColor3 = scene.dialog.color or Color3.fromRGB(255, 255, 255)
		self:typeWrite(scene.dialog.text, scene.dialog.speed or 0.050, self.primary_interface.Dialog.Speech, 0.0, scene.dialog.append, scene.dialog.append_dur)
	end
	
end

-- Yields for user input.
function LuaRpy:waitForInput(): ()
	
	local COMPLETED = false
	local Signal = nil
	
	Signal = USER_INPUT_SERVICE.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			COMPLETED = true
		end
		if input.KeyCode == Enum.KeyCode.ButtonX or input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.Space then
			COMPLETED = true
		end
	end)
	
	-- Simple busy waiting method
	repeat
		task.wait()
	until COMPLETED
	
	Signal:Disconnect()
		
end

return LuaRpy
