-- services
local players = game:GetService("Players");
local workspace = game:GetService("Workspace");
local runService = game:GetService("RunService");
local inputService = game:GetService("UserInputService");
local networkClient = game:GetService("NetworkClient");
local virtualUser = game:GetService("VirtualUser");
local lighting = game:GetService("Lighting");
local teleportService = game:GetService("TeleportService");

-- variables
local camera = workspace.CurrentCamera;
local localplayer = players.LocalPlayer;
local mouse = localplayer:GetMouse();
local curveStatus = {player = nil, i = 0};
local ambient = lighting.Ambient;
local keybinds = {};
local xray = {};
local fonts = {};

-- libraries
local uiLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))();
local espLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Sirius/main/library/esp/esp.lua"))();

local playa = game.Players.LocalPlayer

uiLibrary:MakeNotification({
	Name = "DSM Pro",
	Content = "Version 1.0.4-alpha Made By Payson Holmes.",
    Image = "rbxassetid://10727788295",
	Time = 8
})
wait(3)
uiLibrary:MakeNotification({
	Name = "DSM Pro",
	Content = "You are currently logged in as"..playa.Name..".",
    Image = "rbxassetid://10727788295",
	Time = 5
})

local Name = game.Players.LocalPlayer.Name
-- functions
local function connect(signal, callback)
    local connection = signal:Connect(callback);
    table.insert(uiLibrary.Connections, connection);
    return connection;
end

local function getFlag(name)
    return uiLibrary.Flags[name].Value;
end

local function isR15(character)
    return character:FindFirstChild("UpperTorso") ~= nil;
end

local function getHitpart(character)
    local hitpart = getFlag("combot_aimbot_hitpart");
    if hitpart == "Torso" and isR15(character) then
        hitpart = "UpperTorso";
    end
    return character:FindFirstChild(hitpart);
end

local function isCharacterPart(part)
    for _, player in next, players:GetPlayers() do
        if player.Character and part:IsDescendantOf(player.Character) then
            return true;
        end
    end
    return false;
end

local function wtvp(worldPosition)
    local screenPosition, inBounds = camera:WorldToViewportPoint(worldPosition);
    return Vector2.new(screenPosition.X, screenPosition.Y), inBounds, screenPosition.Z;
end

local function getClosest(fov, teamcheck)
    local returns = {};
    local lastMagnitude = fov or math.huge;
    for _, player in next, players:GetPlayers() do
        if (teamcheck and player.Team == localplayer.Team) or player == localplayer then
            continue;
        end

        local character = player.Character;
        local part = character and getHitpart(character);
        if character and part then
            local partPosition = part.Position;
            if getFlag("combat_aimbot_prediction") then
                partPosition += part.Velocity * getFlag("combat_aimbot_predictioninterval");
            end

            local screenPosition, inBounds = wtvp(partPosition);
            local mousePosition = inputService:GetMouseLocation();
            local magnitude = (screenPosition - mousePosition).Magnitude;
            if magnitude < lastMagnitude and inBounds then
                lastMagnitude = magnitude;
                returns = table.pack(player, screenPosition, part);
            end
        end
    end
    return table.unpack(returns);
end

local function isVisible(part)
    return #camera:GetPartsObscuringTarget({ part.Position }, { camera, part.Parent, localplayer.Character }) == 0;
end

local function bezierCurve(bezierType, t, p0, p1)
    if bezierType == "Linear" then
        return (1-t)*p0 + t*p1;
    else
        return (1 - t)^2 * p0 + 2 * (1 - t) * t * (p0 + (p1 - p0) * Vector2.new(0.5, 0)) + t^2 * p1;
    end
end

local speed = 50

local c
local h
local bv
local bav
local cam
local flying
local p = game.Players.LocalPlayer
local buttons = {W = false, S = false, A = false, D = false, Moving = false}

local startFly = function () -- Call this function to begin flying 
	if not p.Character or not p.Character.Head or flying then return end
	c = p.Character
	h = c.Humanoid
	h.PlatformStand = true
	cam = workspace:WaitForChild('Camera')
	bv = Instance.new("BodyVelocity")
	bav = Instance.new("BodyAngularVelocity")
	bv.Velocity, bv.MaxForce, bv.P = Vector3.new(0, 0, 0), Vector3.new(10000, 10000, 10000), 1000
	bav.AngularVelocity, bav.MaxTorque, bav.P = Vector3.new(0, 0, 0), Vector3.new(10000, 10000, 10000), 1000
	bv.Parent = c.Head
	bav.Parent = c.Head
	flying = true
	h.Died:connect(function() flying = false end)
end

local endFly = function () -- Call this function to stop flying
	if not p.Character or not flying then return end
	h.PlatformStand = false
	bv:Destroy()
	bav:Destroy()
	flying = false
end

game:GetService("UserInputService").InputBegan:connect(function (input, GPE) 
	if GPE then return end
	for i, e in pairs(buttons) do
		if i ~= "Moving" and input.KeyCode == Enum.KeyCode[i] then
			buttons[i] = true
			buttons.Moving = true
		end
	end
end)

game:GetService("UserInputService").InputEnded:connect(function (input, GPE) 
	if GPE then return end
	local a = false
	for i, e in pairs(buttons) do
		if i ~= "Moving" then
			if input.KeyCode == Enum.KeyCode[i] then
				buttons[i] = false
			end
			if buttons[i] then a = true end
		end
	end
	buttons.Moving = a
end)

local setVec = function (vec)
	return vec * (speed / vec.Magnitude)
end

game:GetService("RunService").Heartbeat:connect(function (step) -- The actual fly function, called every frame
	if flying and c and c.PrimaryPart then
		local p = c.PrimaryPart.Position
		local cf = cam.CFrame
		local ax, ay, az = cf:toEulerAnglesXYZ()
		c:SetPrimaryPartCFrame(CFrame.new(p.x, p.y, p.z) * CFrame.Angles(ax, ay, az))
		if buttons.Moving then
			local t = Vector3.new()
			if buttons.W then t = t + (setVec(cf.lookVector)) end
			if buttons.S then t = t - (setVec(cf.lookVector)) end
			if buttons.A then t = t - (setVec(cf.rightVector)) end
			if buttons.D then t = t + (setVec(cf.rightVector)) end
			c:TranslateBy(t * step)
		end
	end
end);

-- ui
local window = uiLibrary:MakeWindow({Name = "DSM Pro", HidePremium = false, SaveConfig = true, ConfigFolder = "DSM-Pro", IntroEnabled = true, IntroText ="DSM Pro", IntroIcon = "rbxassetid://10727788295", Icon = "rbxassetid://10727788295"})
do
    local combat = window:MakeTab({ Name = "Main" });
    do
        local aimbot = combat:AddSection({ Name = "Auto Farm" });
        do
            combat:AddButton({
                Name = "Add Credits",
                Callback = function()
                    print("Added 100M Credits to LocalPlayer's funds.")
                    game:GetService("ReplicatedStorage").Remotes.generateBoost:FireServer("Coins", 480, 99999999)  
                  end    
            })
            
            combat:AddButton({
                Name = "Add EXP",
                Callback = function()
                    print("Added 10 LVL's of EXP to LocalPlayer's funds.")
                    game:GetService("ReplicatedStorage").Remotes.generateBoost:FireServer("Levels", 480, 11)
                  end    
            })
            
            combat:AddButton({
                Name = "Sell",
                Callback = function()
                    print("SOLD")
                    local remote = game["ReplicatedStorage"]["Remotes"]["sellBricks"]
                    remote:FireServer()
                  end    
            })
            
            combat:AddButton({
                Name = "Auto Sell",
                Callback = function()
                    print("Activated Auto Sell")
                    local remote = game["ReplicatedStorage"]["Remotes"]["sellBricks"]
                    while true do
                        remote:FireServer()
                        wait(12.5)
                     end
                  end    
            })
        end

    end

    local visuals = window:MakeTab({ Name = "Visuals" });
    do
        local esp = visuals:AddSection({ Name = "ESP" });
        do
            esp:AddToggle({ Name = "Enabled", Default = false, Save = true, Flag = "visuals_esp_enabled", Callback = function(value)
                espLibrary.options.enabled = value;
            end });

            esp:AddToggle({ Name = "Boxes", Default = false, Save = true, Flag = "visuals_esp_boxes", Callback = function(value)
                espLibrary.options.boxes = value;
            end });

            esp:AddToggle({ Name = "Filled Boxes", Default = false, Save = true, Flag = "visuals_esp_filledboxes", Callback = function(value)
                espLibrary.options.boxFill = value;
            end });

            esp:AddToggle({ Name = "Healthbar", Default = false, Save = true, Flag = "visuals_esp_healthbar", Callback = function(value)
                espLibrary.options.healthBars = value;
            end });

            esp:AddToggle({ Name = "Health Text", Default = false, Save = true, Flag = "visuals_esp_healthtext", Callback = function(value)
                espLibrary.options.healthText = value;
            end });

            esp:AddToggle({ Name = "Names", Default = false, Save = true, Flag = "visuals_esp_names", Callback = function(value)
                espLibrary.options.names = value;
            end });

            esp:AddToggle({ Name = "Distance", Default = false, Save = true, Flag = "visuals_esp_distance", Callback = function(value)
                espLibrary.options.distance = value;
            end });

            esp:AddToggle({ Name = "Chams", Default = false, Save = true, Flag = "visuals_esp_chams", Callback = function(value)
                espLibrary.options.chams = value;
            end });

            esp:AddToggle({ Name = "Tracers", Default = false, Save = true, Flag = "visuals_esp_tracers", Callback = function(value)
                espLibrary.options.tracers = value;
            end });

            esp:AddToggle({ Name = "Out-of-view arrows", Default = false, Save = true, Flag = "visuals_esp_oofarrows", Callback = function(value)
                espLibrary.options.outOfViewArrows = value;
                espLibrary.options.outOfViewArrowsOutline = value;
            end });
        end

        local espSettings = visuals:AddSection({ Name = "ESP Settings" });
        do
            espSettings:AddColorpicker({ Name = "Box Color", Default = Color3.new(1,1,1), Save = true, Flag = "visuals_espsettings_boxcolor", Callback = function(value)
                espLibrary.options.boxesColor = value;
            end });

            espSettings:AddColorpicker({ Name = "Filled Box Color", Default = Color3.new(1,1,1), Save = true, Flag = "visuals_espsettings_filledboxcolor", Callback = function(value)
                espLibrary.options.boxFillColor = value;
            end });

            espSettings:AddColorpicker({ Name = "Healthbar Color", Default = Color3.new(0,1,0), Save = true, Flag = "visuals_espsettings_healthbarcolor", Callback = function(value)
                espLibrary.options.healthBarsColor = value;
            end });

            espSettings:AddColorpicker({ Name = "Healthtext Color", Default = Color3.new(0,1,0), Save = true, Flag = "visuals_espsettings_healthtextcolor", Callback = function(value)
                espLibrary.options.healthTextColor = value;
            end });

            espSettings:AddColorpicker({ Name = "Names Color", Default = Color3.new(1,1,1), Save = true, Flag = "visuals_espsettings_namescolor", Callback = function(value)
                espLibrary.options.nameColor = value;
            end });

            espSettings:AddColorpicker({ Name = "Distance Color", Default = Color3.new(1,1,1), Save = true, Flag = "visuals_espsettings_distancecolor", Callback = function(value)
                espLibrary.options.distanceColor = value;
            end });

            espSettings:AddColorpicker({ Name = "Chams Color", Default = Color3.new(1,0,0), Save = true, Flag = "visuals_espsettings_chamscolor", Callback = function(value)
                espLibrary.options.chamsFillColor = value;
            end });

            espSettings:AddColorpicker({ Name = "Tracer Color", Default = Color3.new(1,1,1), Save = true, Flag = "visuals_espsettings_tracercolor", Callback = function(value)
                espLibrary.options.tracerColor = value;
            end });
            
            espSettings:AddColorpicker({ Name = "OOF Arrows Color", Default = Color3.new(1,1,1), Save = true, Flag = "visuals_espsettings_oofarrowscolor", Callback = function(value)
                espLibrary.options.outOfViewArrowsColor = value;
                espLibrary.options.outOfViewArrowsOutlineColor = value;
            end });

            espSettings:AddToggle({ Name = "Use Teamcolor", Default = false, Save = true, Flag = "visuals_espsettings_useteamcolor", Callback = function(value)
                espLibrary.options.teamColor = value;
            end });

            espSettings:AddToggle({ Name = "Team Check", Default = true, Save = true, Flag = "visuals_espsettings_teamcheck", Callback = function(value)
                espLibrary.options.teamCheck = value;
            end });

            espSettings:AddToggle({ Name = "Visible Check", Default = false, Save = true, Flag = "visuals_espsettings_visiblecheck", Callback = function(value)
                espLibrary.options.visibleOnly = value;
            end });

            espSettings:AddToggle({ Name = "Limit Distance", Default = false, Save = true, Flag = "visuals_espsettings_limitdistance", Callback = function(value)
                espLibrary.options.limitDistance = value;
            end });

            espSettings:AddSlider({ Name = "Max Distance", Default = 1000, Min = 50, Max = 2000, ValueName = "studs", Save = true, Flag = "visuals_espsettings_maxdistance", Callback = function(value)
                espLibrary.options.maxDistance = value;
            end });

            espSettings:AddSlider({ Name = "Font Size", Default = 13, Min = 5, Max = 25, ValueName = "px", Save = true, Flag = "visuals_espsettings_fontsize", Callback = function(value)
                espLibrary.options.fontSize = value;
            end });

            espSettings:AddDropdown({ Name = "Tracer Origin", Default = "Bottom", Options = {"Bottom", "Top", "Mouse"}, Save = true, Flag = "visuals_espsettings_tracerorigin", Callback = function(value)
                espLibrary.options.tracerOrigin = value;
            end });
        end
    end

    local movement = window:MakeTab({ Name = "Movement" });
    do
        local character = movement:AddSection({ Name = "Character" });
        do
            character:AddSlider({
                Name = "Walkspeed",
                Min = 0,
                Max = 250,
                Default = 16,
                Color = Color3.fromRGB(0, 200, 0),
                Increment = 1,
                ValueName = "studs/s",
                Save = true,
                Callback = function(speed)
                    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = speed
                end    
            })

            local character = movement:AddSection({ Name = "Character" });
            do
                character:AddSlider({
                    Name = "JumpPower",
                    Min = 0,
                    Max = 250,
                    Default = 55,
                    Color = Color3.fromRGB(0, 200, 0),
                    Increment = 1,
                    ValueName = "studs",
                    Save = true,
                    Callback = function(height)
                        game.Players.LocalPlayer.Character.Humanoid.JumpPower = height
                    end    
                })

                character:AddToggle({
                    Name = "Fly",
                    Default = false,
                    Save = true,
                    Callback = function(Value)
                        if Value == true then
                            startFly()
                        else
                            endFly()
                        end
                    end    
                })

            character:AddToggle({ Name = "Infinite Jump", Default = false, Save = true, Flag = "movement_character_infinitejump" });
        end

        local teleporting = movement:AddSection({ Name = "Teleporting" });
        do
            local playerName = "";
            teleporting:AddTextbox({ Name = "Player", TextDisappear = true, Save = false, Callback = function(value)
                playerName = string.lower(value);
            end });

            teleporting:AddButton({ Name = "Teleport", Callback = function()
                local character = localplayer.Character;
                if character then
                    local player;
                    for _, plr in next, players:GetPlayers() do
                        if string.find(string.lower(plr.Name), playerName) or string.find(string.lower(plr.DisplayName), playerName) then
                            player = plr;
                        end
                    end

                    if player and player.Character then
                        character:PivotTo(player.Character:GetPivot());
                    end
                end
            end });

            teleporting:AddToggle({ Name = "Click TP", Default = false, Save = true, Flag = "movement_teleporting_clicktp"});
            
            teleporting:AddButton({
                Name = "TP to Shop",
                Callback = function()
                    game.Workspace[Name].HumanoidRootPart.CFrame = CFrame.new(-52.7326279, 3.45200205, -556.515015)
                  end    
            })
            
            teleporting:AddButton({
                Name = "TP to Highway Racing",
                Callback = function()
                    game.Workspace[Name].HumanoidRootPart.CFrame = CFrame.new(19.63, 3.35, -434.96)
                  end    
            })
            
            teleporting:AddButton({
                Name = "TP to Construction Site",
                Callback = function()
                    game.Workspace[Name].HumanoidRootPart.CFrame = CFrame.new(-89, 3, -452)
                  end    
            })
            
            teleporting:AddButton({
                Name = "TP to Happy Home",
                Callback = function()
                    game.Workspace[Name].HumanoidRootPart.CFrame = CFrame.new(-88, 3.5, -150)
                  end    
            })
            
            teleporting:AddButton({
                Name = "TP to Ship Dock",
                Callback = function()
                    game.Workspace[Name].HumanoidRootPart.CFrame = CFrame.new(-89.05, 3.35, 144)
                  end    
            })
            
            teleporting:AddButton({
                Name = "TP to Space Travel",
                Callback = function()
                    game.Workspace[Name].HumanoidRootPart.CFrame = CFrame.new(-89.05, 3.35, 144)
                  end    
            })
            
            teleporting:AddButton({
                Name = "TP to Military Camp",
                Callback = function()
                    game.Workspace[Name].HumanoidRootPart.CFrame = CFrame.new(17.74, 3.35, 453.33)
                  end    
            })
            
            teleporting:AddButton({
                Name = "TP to Pyramid & Pillars",
                Callback = function()
                    game.Workspace[Name].HumanoidRootPart.CFrame = CFrame.new(-86.08, 3.35, 446.63)
                  end    
            })
            
            teleporting:AddButton({
                Name = "TP to Castle",
                Callback = function()
                    game.Workspace[Name].HumanoidRootPart.CFrame = CFrame.new(18.35, 3.35, 774.2)
                  end    
            })
            
            teleporting:AddButton({
                Name = "TP to Empire State",
                Callback = function()
                    game.Workspace[Name].HumanoidRootPart.CFrame = CFrame.new(-89.75, 3.35, 747.22)
                  end    
            })
            
            teleporting:AddButton({
                Name = "TP to Volcano",
                Callback = function()
                    game.Workspace[Name].HumanoidRootPart.CFrame = CFrame.new(-1.8668566942214966, 5.440496921539307, 1041.328125)
                  end    
            })
            
            teleporting:AddButton({
                Name = "TP to Towers",
                Callback = function()
                    game.Workspace[Name].HumanoidRootPart.CFrame = CFrame.new(-65.02375030517578, 5.440497875213623, 1042.22216796875)
                  end    
            })

        end
        local teleportingr = movement:AddSection({ Name = "Teleporting [RANKED]" });
        do
        teleportingr:AddButton({
            Name = "TP to [RANK 2] Emoji Land",
            Callback = function()
                game.Workspace[Name].HumanoidRootPart.CFrame = CFrame.new(-4.56, 5.44, -757.52)
              end    
        })

        teleportingr:AddButton({
            Name = "TP to [RANK 3] Noob Land",
            Callback = function()
                game.Workspace[Name].HumanoidRootPart.CFrame = CFrame.new(-69.46, 5.44, -757.78)
              end    
        })

        teleportingr:AddButton({
            Name = "TP to [RANK 4] Switch Land",
            Callback = function()
                game.Workspace[Name].HumanoidRootPart.CFrame = CFrame.new(-4.56, 5.44, -1055.60)
              end    
        })

        teleportingr:AddButton({
            Name = "TP to [RANK 5] Rubix Land",
            Callback = function()
                game.Workspace[Name].HumanoidRootPart.CFrame = CFrame.new(-69.46, 5.44, -1055.60)
              end    
        })
        end
    end

    local other = window:MakeTab({ Name = "Misc" });
    do
        local exploits = other:AddSection({ Name = "Exploits" });
        do
            exploits:AddToggle({ Name = "No-Clip", Default = false, Save = true, Flag = "other_exploits_noclip" });

            exploits:AddToggle({ Name = "Fake Lag", Default = false, Save = true, Flag = "other_exploits_fakelag", Callback = function(value)
                networkClient:SetOutgoingKBPSLimit(value and 1 or 0);
            end });

            exploits:AddToggle({ Name = "Anti AFK", Default = true, Save = true, Flag = "other_exploits_antiafk" });
        end

        local lighting = other:AddSection({ Name = "Lighting" });
        do
            lighting:AddToggle({ Name = "Custom Time", Default = false, Save = true, Flag = "other_lighting_customtime" });
            lighting:AddSlider({ Name = "Time of Day", Default = 12, Min = 0, Max = 24, Increment = 0.5, Save = true, Flag = "other_lighting_timevalue" });
        end

        local _game = other:AddSection({ Name = "Game" });
        do
            _game:AddToggle({ Name = "X-Ray", Default = false, Save = true, Flag = "other_game_xray", Callback = function(value)
                if value then
                    for _, part in next, workspace:GetDescendants() do
                        if part:IsA("BasePart") and part.Transparency ~= 1 and not part:IsDescendantOf(camera) and not isCharacterPart(part) then
                            if not xray[part] or xray[part] ~= part.Transparency then
                                xray[part] = part.Transparency;
                            end
                            part.Transparency = 0.75;
                        end
                    end
                else
                    for _, part in next, workspace:GetDescendants() do
                        if xray[part] then
                            part.Transparency = xray[part];
                        end
                    end
                end
            end });

            _game:AddButton({ Name = "Rejoin Game", Callback = function()
                teleportService:Teleport(game.PlaceId);
            end });
        end
    end

    local extratb = window:MakeTab({ Name = "Extra" });
    do
        local windowex = extratb:AddSection({ Name = "Script" });
        do
            windowex:AddLabel("Click the X to Hide the UI.");
            windowex:AddLabel("Press RightShift after ro re-open the UI.")
            extratb:AddLabel("DSM Pro - v1.0.4");
        end
        local creds = extratb:AddSection({ Name = "Credits" });
        do
        creds:AddLabel("Made By Payson Holmes");
        creds:AddButton({
            Name = "GitHub",
            Callback = function()
                      setclipboard("https://github.com/P-DennyGamingYT")
                      uiLibrary:MakeNotification({
                        Name = "DSM Pro",
                        Image = "rbxassetid://10727788295",
                        Content = "Copied GitHub Link to Clipboard.",
                        Time = 5
                    })
              end    
        })
        creds:AddButton({
            Name = "Discord",
            Callback = function()
                      setclipboard("https://discord.gg/users/820680923887566868")
                      uiLibrary:MakeNotification({
                        Name = "DSM Pro",
                        Image = "rbxassetid://10727788295",
                        Content = "Copied Discord Profile Link to Clipboard.",
                        Time = 5
                    })
              end    
        })
        creds:AddButton({
            Name = "Discord Server",
            Callback = function()
                      setclipboard("https://dsc.gg/PDennSploit")
                      uiLibrary:MakeNotification({
                        Name = "DSM Pro",
                        Image = "rbxassetid://10727788295",
                        Content = "Copied Discord Server Link to Clipboard.",
                        Time = 5
                    })
              end    
        })
        end
    end
end

-- connections
connect(localplayer.Idled, function()
    if getFlag("other_exploits_antiafk") then
        virtualUser:ClickButton1(Vector2.zero, camera);
    end
end);

connect(runService.Stepped, function()
    if getFlag("other_exploits_noclip") then
        local character = localplayer.Character;
        if character then
            for _, part in next, character:GetDescendants() do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false;
                end
            end
        end
    end
end);

connect(runService.Heartbeat, function()
    if getFlag("other_lighting_ambient") then
        lighting.Ambient = getFlag("other_lighting_ambientcolor");
    else
        lighting.Ambient = ambient;
    end
    if getFlag("other_lighting_customtime") then
        lighting.ClockTime = getFlag("other_lighting_timevalue");
    end
end);

connect(runService.Heartbeat, function()
    local character = localplayer.Character;
    local humanoid = character and character:FindFirstChildOfClass("Humanoid");
    if humanoid then
        if getFlag("movement_character_walkspeed") then
            game.Players.LocalPlayer.Humanoid.Walkspeed = getFlag("movement_character_walkspeed_value");
        end
        if getFlag("movement_character_jumpheight") then
            humanoid.UseJumpPower = false;
            game.Players.LocalPlayer.Humanoid.JumpPower = getFlag("movement_character_jumpheight_value");
        end
        if getFlag("movement_character_fly") then
            local rootPart = humanoid.RootPart;
            local velocity = Vector3.zero;
            if inputService:IsKeyDown(Enum.KeyCode.W) then
                velocity += camera.CFrame.LookVector;
            end
            if inputService:IsKeyDown(Enum.KeyCode.S) then
                velocity += -camera.CFrame.LookVector;
            end
            if inputService:IsKeyDown(Enum.KeyCode.D) then
                velocity += camera.CFrame.RightVector;
            end
            if inputService:IsKeyDown(Enum.KeyCode.A) then
                velocity += -camera.CFrame.RightVector;
            end
            if inputService:IsKeyDown(Enum.KeyCode.Space) then
                velocity += rootPart.CFrame.UpVector;
            end
            if inputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                velocity += -rootPart.CFrame.UpVector;
            end
            rootPart.Velocity = velocity * getFlag("movement_character_fly_value");
        end
    end
end);

connect(inputService.InputBegan, function(input, processed)
    if input.UserInputType.Name == "MouseButton1" and not processed and getFlag("movement_teleporting_clicktp") then
        local character = localplayer.Character;
        local camPos = camera.CFrame.Position;

        local ray = Ray.new(camPos, mouse.Hit.Position - camPos);
        local _, hit, normal = workspace:FindPartOnRayWithIgnoreList(ray, { camera });
        if hit and normal then
            character:PivotTo(CFrame.new(hit + normal));
        end
    end
    if input.KeyCode.Name == "Space" and not processed and getFlag("movement_character_infinitejump") then
        local character = localplayer.Character;
        local humanoid = character and character:FindFirstChildOfClass("Humanoid");
        if humanoid then
            humanoid:ChangeState("Jumping");
        end 
    end
end);
end
espLibrary:Load();
uiLibrary:Init();
