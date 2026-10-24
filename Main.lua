do
local Players,RunService,CoreGui,UserInputService=game:GetService("Players"),game:GetService("RunService"),game:GetService("CoreGui"),game:GetService("UserInputService")
local player=Players.LocalPlayer
local CONFIG={Name="Lennon hub",UpdateRate=.15,DiscoveryRate=1.5,ChromaSpeed=.35,Background=Color3.fromRGB(15,17,19),Panel=Color3.fromRGB(25,28,30),Button=Color3.fromRGB(35,39,41),Text=Color3.fromRGB(245,245,245),Accent=Color3.fromRGB(145,255,65),Active=Color3.fromRGB(30,75,35),Danger=Color3.fromRGB(100,35,35)}
local ESP_COLORS={Lennon=Color3.fromRGB(145,255,65),Red=Color3.fromRGB(255,70,70),Blue=Color3.fromRGB(70,160,255),White=Color3.fromRGB(255,255,255),Yellow=Color3.fromRGB(255,230,60)}
local ESP_CONFIG={Color="Lennon",MaxDistance=1000,ShowNames=true,ShowDistance=true}
local locations={Spawn=Vector3.new(326.58,511.7,393.3),["Upgrade Machine"]=Vector3.new(112.16,313.5,71.18),["Get Ammo"]=Vector3.new(184.02,313.5,434.36),Armor=Vector3.new(-174.8,293.5,316.31)}
local destroyed,espEnabled,allEnabled,ammoEnabled=false,false,false,false
local selectedLocation,floatingTPEnabled="Spawn",true
local espObjects,connections,uiStrokes={},{},{}
local updateAccumulator,discoveryAccumulator,collectAccumulator,chromaHue=0,0,0,0
local cachedWeapons,cachedTargets,cachedAmmo,cachedBadges={},{},{},{}
local cachedSpots,cachedQuest,cachedMansion,cachedArea
local targetIndex,ammoIndex=1,1

local function connect(signal,callback)
local c=signal:Connect(callback);table.insert(connections,c);return c
end
local function create(class,props,parent)
local o=Instance.new(class)
for k,v in pairs(props or {}) do o[k]=v end
o.Parent=parent
return o
end
local function corner(o,r) return create("UICorner",{CornerRadius=UDim.new(0,r or 5)},o) end
local function stroke(o,t)
local s=create("UIStroke",{Color=CONFIG.Accent,Thickness=t or 1},o)
table.insert(uiStrokes,s)
return s
end
local function label(p,txt,size,pos)
return create("TextLabel",{Size=size,Position=pos,BackgroundTransparency=1,Text=txt,TextColor3=CONFIG.Text,TextSize=10,Font=Enum.Font.Arcade,TextWrapped=true,BorderSizePixel=0},p)
end
local function makeButton(p,txt,size,pos)
local b=create("TextButton",{Size=size,Position=pos,BackgroundColor3=CONFIG.Button,Text=txt,TextColor3=CONFIG.Text,Font=Enum.Font.Arcade,TextSize=9,TextWrapped=true,BorderSizePixel=0,AutoButtonColor=true},p)
corner(b)
return b
end

local old=CoreGui:FindFirstChild("LennonHub")
if old then old:Destroy() end
local gui=create("ScreenGui",{Name="LennonHub",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=999},CoreGui)
local main=create("Frame",{Name="Main",Size=UDim2.fromOffset(210,335),Position=UDim2.new(.5,-105,.5,-167),BackgroundColor3=CONFIG.Background,BorderSizePixel=0,Active=true,Draggable=true},gui)
corner(main,7)
local mainStroke=stroke(main,2)
local header=create("Frame",{Size=UDim2.new(1,0,0,27),BackgroundColor3=CONFIG.Panel,BorderSizePixel=0},main)
corner(header)
local title=label(header,CONFIG.Name,UDim2.new(1,-48,1,0),UDim2.fromOffset(7,0))
title.TextSize=11
title.TextXAlignment=Enum.TextXAlignment.Left
local closeButton=makeButton(header,"X",UDim2.fromOffset(21,20),UDim2.new(1,-24,0,3))
closeButton.BackgroundColor3=CONFIG.Danger
local locationButton=makeButton(main,"LOCATION: SPAWN  v",UDim2.new(1,-14,0,23),UDim2.fromOffset(7,32))
local locationList=create("Frame",{Size=UDim2.new(1,-14,0,0),Position=UDim2.fromOffset(7,57),BackgroundColor3=CONFIG.Panel,BorderSizePixel=0,Visible=false,ClipsDescendants=true,ZIndex=15},main)
corner(locationList)
stroke(locationList)
local teleportButton=makeButton(main,"TELEPORT",UDim2.new(1,-14,0,23),UDim2.fromOffset(7,59))
local tpButton=makeButton(main,"TP CLOSEST KILLER",UDim2.new(1,-14,0,23),UDim2.fromOffset(7,86))
local espButton=makeButton(main,"KILLER ESP: OFF",UDim2.new(1,-14,0,24),UDim2.fromOffset(7,113))
local gunsButton=makeButton(main,"GUNS / AMMO: OFF",UDim2.new(1,-14,0,23),UDim2.fromOffset(7,141))
local ammoButton=makeButton(main,"AMMO ONLY: OFF",UDim2.new(1,-14,0,23),UDim2.fromOffset(7,168))
local settingsButton=makeButton(main,"ESP SETTINGS",UDim2.new(1,-14,0,23),UDim2.fromOffset(7,195))
local floatingToggle=makeButton(main,"FLOATING TP: ON",UDim2.new(1,-14,0,23),UDim2.fromOffset(7,222))
floatingToggle.BackgroundColor3=CONFIG.Active
local statusLabel=label(main,"Starting...",UDim2.new(1,-14,0,15),UDim2.fromOffset(7,250))
statusLabel.TextXAlignment=Enum.TextXAlignment.Left
statusLabel.TextSize=8

local settings=create("Frame",{Size=UDim2.fromOffset(170,157),Position=UDim2.new(1,5,0,27),BackgroundColor3=CONFIG.Background,BorderSizePixel=0,Visible=false,ZIndex=20},main)
corner(settings)
stroke(settings,2)
local settingsTitle=label(settings,"ESP SETTINGS",UDim2.new(1,-8,0,19),UDim2.fromOffset(4,2))
settingsTitle.ZIndex=21
local colorButton=makeButton(settings,"COLOR: LENNON",UDim2.new(1,-10,0,23),UDim2.fromOffset(5,24))
colorButton.ZIndex=21
local rangeButton=makeButton(settings,"RANGE: 1000",UDim2.new(1,-10,0,23),UDim2.fromOffset(5,51))
rangeButton.ZIndex=21
local namesButton=makeButton(settings,"NAMES: ON",UDim2.new(1,-10,0,23),UDim2.fromOffset(5,78))
namesButton.ZIndex=21
local distanceButton=makeButton(settings,"DISTANCE: ON",UDim2.new(1,-10,0,23),UDim2.fromOffset(5,105))
distanceButton.ZIndex=21
local floatingTP=makeButton(gui,"TP",UDim2.fromOffset(40,34),UDim2.new(.04,0,.65,0))
floatingTP.Name="FloatingTP"
floatingTP.TextSize=10
floatingTP.ZIndex=100
local floatingTPStroke=stroke(floatingTP,2)
local floatingMenu=makeButton(gui,"OPEN",UDim2.fromOffset(40,27),UDim2.new(.04,0,.75,0))
floatingMenu.Name="FloatingMenu"
floatingMenu.ZIndex=100
local floatingMenuStroke=stroke(floatingMenu,2)
local confirm=create("Frame",{Size=UDim2.fromOffset(175,76),Position=UDim2.new(.5,-87,.5,-38),BackgroundColor3=CONFIG.Background,BorderSizePixel=0,Visible=false,ZIndex=40},gui)
corner(confirm)
stroke(confirm,2)
local confirmLabel=label(confirm,"CLOSE LENNON HUB?",UDim2.new(1,-8,0,24),UDim2.fromOffset(4,3))
confirmLabel.ZIndex=41
local yesButton=makeButton(confirm,"YES",UDim2.fromOffset(68,22),UDim2.fromOffset(12,44))
yesButton.BackgroundColor3=CONFIG.Danger
yesButton.ZIndex=41
local noButton=makeButton(confirm,"NO",UDim2.fromOffset(68,22),UDim2.fromOffset(95,44))
noButton.ZIndex=41

local function setGuiVisible(v)
main.Visible=v
confirm.Visible=false
floatingMenu.Visible=true
floatingMenu.Text=v and "HIDE" or "OPEN"
end
local function getESPColor() return ESP_COLORS[ESP_CONFIG.Color] or CONFIG.Accent end
local function getTargetPart(t) return t:FindFirstChild("HumanoidRootPart") or t:FindFirstChild("Head") or t:FindFirstChildWhichIsA("BasePart") end
local function destroyESPData(d)
if not d then return end
if d.highlight then d.highlight:Destroy() end
if d.billboard then d.billboard:Destroy() end
end

local function addESP(target)
if destroyed or not espEnabled or not target:IsA("Model") or not target.Parent or espObjects[target] then return end
local part=getTargetPart(target)
if not part then return end
local color=getESPColor()
local highlight=create("Highlight",{Adornee=target,FillColor=color,OutlineColor=color,FillTransparency=.75,OutlineTransparency=0,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop},gui)
local billboard=create("BillboardGui",{Adornee=part,Size=UDim2.fromOffset(145,35),StudsOffset=Vector3.new(0,2.5,0),AlwaysOnTop=true,MaxDistance=ESP_CONFIG.MaxDistance},gui)
local nameText=label(billboard,target.Name,UDim2.new(1,0,0,18),UDim2.fromOffset(0,0))
nameText.TextColor3=color
local distText=label(billboard,"-- studs",UDim2.new(1,0,0,15),UDim2.fromOffset(0,18))
espObjects[target]={highlight=highlight,billboard=billboard,nameLabel=nameText,distanceLabel=distText}
end
local function clearESP()
for t,d in pairs(espObjects) do destroyESPData(d);espObjects[t]=nil end
end
local function setESP(v)
espEnabled=v
if not v then
clearESP()
else
local f=workspace:FindFirstChild("Killers")
if f then for _,t in ipairs(f:GetChildren()) do addESP(t) end end
end
espButton.Text=v and "KILLER ESP: ON" or "KILLER ESP: OFF"
espButton.BackgroundColor3=v and CONFIG.Active or CONFIG.Button
statusLabel.Text=v and "Killer ESP enabled" or "Killer ESP disabled"
end

local function findPotionSpots()
if cachedSpots and cachedSpots.Parent then return cachedSpots end
cachedSpots=nil
cachedArea=workspace:FindFirstChild("AREA51")
cachedMansion=cachedArea and cachedArea:FindFirstChild("UndergroundMansion",true)
cachedQuest=cachedMansion and cachedMansion:FindFirstChild("Quest2",true)
cachedSpots=cachedQuest and cachedQuest:FindFirstChild("PotionsPossibleSpots",true)
return cachedSpots
end

local function getTouchPart(obj)
if not obj then return nil end
if obj:IsA("BasePart") then return obj end
if obj:IsA("Model") or obj:IsA("Tool") then
return obj:FindFirstChild("Hitbox",true) or obj:FindFirstChild("Handle",true) or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart",true)
end
return nil
end

local function discoverTargets()
table.clear(cachedWeapons)
table.clear(cachedTargets)
table.clear(cachedAmmo)
table.clear(cachedBadges)
local seenTargets,seenAmmo={},{}
local function addTarget(obj)
local part=getTouchPart(obj)
if part and not seenTargets[part] then
seenTargets[part]=true
table.insert(cachedTargets,part)
end
end
local function addAmmo(obj)
local part=getTouchPart(obj)
if part and not seenAmmo[part] then
seenAmmo[part]=true
table.insert(cachedAmmo,part)
end
end

local weapons=workspace:FindFirstChild("Weapons")
if weapons then
for _,obj in ipairs(weapons:GetDescendants()) do
if obj.Name=="Hitbox" and obj:IsA("BasePart") then table.insert(cachedWeapons,obj) end
end
end

for _,obj in ipairs(workspace:GetDescendants()) do
local name=string.lower(obj.Name)
if name=="paper" then
addTarget(obj)
elseif name=="candy" and obj.Parent and obj.Parent.Name=="CandyHolders" then
addTarget(obj)
elseif name=="ammo" or name=="ammobox" or name=="ammunition" or name=="ammopickup" then
addAmmo(obj)
end
end

-- Todos os Reward dentro de AREA51
local area=workspace:FindFirstChild("AREA51")
if area then
for _,obj in ipairs(area:GetDescendants()) do
if obj.Name=="Reward" then addTarget(obj) end
end
-- Todas as Badges (TheUltimateSecret e demais)
local badges=area:FindFirstChild("Badges")
if badges then
local seenBadges={}
for _,obj in ipairs(badges:GetChildren()) do
local part=getTouchPart(obj)
if part and not seenBadges[part] then
seenBadges[part]=true
table.insert(cachedBadges,part)
end
end
end
end

local spots=findPotionSpots()
if spots then
for _,obj in ipairs(spots:GetDescendants()) do
if obj:IsA("BasePart") and obj.Name=="Hitbox" then addTarget(obj) end
end
end
targetIndex=math.min(targetIndex,math.max(1,#cachedTargets))
ammoIndex=math.min(ammoIndex,math.max(1,#cachedAmmo))
end

local function touchPart(root,part)
if not root or not root.Parent or not part or not part.Parent then return end
pcall(function()
firetouchinterest(root,part,0)
firetouchinterest(root,part,1)
end)
end
local function collectList(root,list,indexName,limit)
local total=#list
if total==0 then return 1 end
local index=indexName
for _=1,math.min(limit,total) do
if index>total then index=1 end
local part=list[index]
if part and part.Parent then touchPart(root,part) end
index+=1
end
return index>total and 1 or index
end
local function collectEverything()
if not allEnabled or typeof(firetouchinterest)~="function" then return end
local c=player.Character
local root=c and c:FindFirstChild("HumanoidRootPart")
if not root then return end
for _,part in ipairs(cachedWeapons) do
if part and part.Parent then touchPart(root,part) end
end
for _,part in ipairs(cachedBadges) do
if part and part.Parent then touchPart(root,part) end
end
targetIndex=collectList(root,cachedTargets,targetIndex,8)
ammoIndex=collectList(root,cachedAmmo,ammoIndex,8)
end
local function collectAmmoOnly()
if not ammoEnabled or typeof(firetouchinterest)~="function" then return end
local c=player.Character
local root=c and c:FindFirstChild("HumanoidRootPart")
if not root then return end
ammoIndex=collectList(root,cachedAmmo,ammoIndex,8)
end

local function teleportTo(pos)
local c=player.Character
local r=c and c:FindFirstChild("HumanoidRootPart")
if not r then statusLabel.Text="Character unavailable";return end
r.CFrame=CFrame.new(pos)
statusLabel.Text="Teleported: "..selectedLocation
end
local function teleportBehindClosestKiller()
local c=player.Character
local r=c and c:FindFirstChild("HumanoidRootPart")
local f=workspace:FindFirstChild("Killers")
if not r or not f then statusLabel.Text="Character or killers unavailable";return end
local closestPart,closestDistance=nil,math.huge
for _,k in ipairs(f:GetChildren()) do
if k:IsA("Model") and k.Name~="Giant" then
local p=getTargetPart(k)
local h=k:FindFirstChildOfClass("Humanoid")
if p and (not h or h.Health>0) then
local d=(r.Position-p.Position).Magnitude
if d<closestDistance then closestDistance,closestPart=d,p end
end
end
end
if not closestPart then statusLabel.Text="No valid killer found";return end
local behind=closestPart.Position-closestPart.CFrame.LookVector*10
r.CFrame=CFrame.lookAt(behind,closestPart.Position)
statusLabel.Text="TP Closest: "..math.floor(closestDistance).." studs"
end

local function refreshLocations()
local buttons={}
for _,o in ipairs(locationList:GetChildren()) do
if o:IsA("TextButton") then table.insert(buttons,o) end
end
table.sort(buttons,function(a,b) return a.Text<b.Text end)
for i,b in ipairs(buttons) do
b.Position=UDim2.fromOffset(4,4+(i-1)*25)
b.Visible=true
b.ZIndex=16
end
locationList.Size=UDim2.new(1,-14,0,#buttons*25+8)
end
for name in pairs(locations) do
local locationName=name
local b=makeButton(locationList,locationName,UDim2.new(1,-8,0,23),UDim2.fromOffset(4,4))
b.Visible=false
b.ZIndex=16
connect(b.Activated,function()
selectedLocation=locationName
locationButton.Text="LOCATION: "..string.upper(locationName).."  v"
locationList.Visible=false
locationList.Size=UDim2.new(1,-14,0,0)
statusLabel.Text="Selected: "..locationName
end)
end
connect(locationButton.Activated,function()
local opening=not locationList.Visible
if opening then refreshLocations() end
locationList.Visible=opening
if not opening then locationList.Size=UDim2.new(1,-14,0,0) end
end)
connect(teleportButton.Activated,function() if locations[selectedLocation] then teleportTo(locations[selectedLocation]) end end)
connect(tpButton.Activated,teleportBehindClosestKiller)
connect(floatingTP.Activated,teleportBehindClosestKiller)
connect(espButton.Activated,function() setESP(not espEnabled) end)

connect(gunsButton.Activated,function()
allEnabled=not allEnabled
if allEnabled then ammoEnabled=false end
gunsButton.Text=allEnabled and "GUNS / AMMO: ON" or "GUNS / AMMO: OFF"
gunsButton.BackgroundColor3=allEnabled and CONFIG.Active or CONFIG.Button
ammoButton.Text="AMMO ONLY: "..(ammoEnabled and "ON" or "OFF")
ammoButton.BackgroundColor3=ammoEnabled and CONFIG.Active or CONFIG.Button
statusLabel.Text=allEnabled and "Collection enabled" or "Collection disabled"
end)
connect(ammoButton.Activated,function()
ammoEnabled=not ammoEnabled
if ammoEnabled then allEnabled=false end
ammoButton.Text=ammoEnabled and "AMMO ONLY: ON" or "AMMO ONLY: OFF"
ammoButton.BackgroundColor3=ammoEnabled and CONFIG.Active or CONFIG.Button
gunsButton.Text="GUNS / AMMO: "..(allEnabled and "ON" or "OFF")
gunsButton.BackgroundColor3=allEnabled and CONFIG.Active or CONFIG.Button
statusLabel.Text=ammoEnabled and "Ammo-only collection enabled" or "Ammo-only collection disabled"
end)
connect(settingsButton.Activated,function()
settings.Visible=not settings.Visible
settingsButton.Text=settings.Visible and "CLOSE SETTINGS" or "ESP SETTINGS"
end)
connect(floatingToggle.Activated,function()
floatingTPEnabled=not floatingTPEnabled
floatingTP.Visible=floatingTPEnabled
floatingToggle.Text=floatingTPEnabled and "FLOATING TP: ON" or "FLOATING TP: OFF"
floatingToggle.BackgroundColor3=floatingTPEnabled and CONFIG.Active or CONFIG.Button
end)

-- === NOVOS BOTÕES: ARMORY GIVER / ZOMBIE MORPH ===
local armoryButton=makeButton(main,"ARMORY GIVER",UDim2.new(1,-14,0,23),UDim2.fromOffset(7,277))
local zombieButton=makeButton(main,"ZOMBIE MORPH",UDim2.new(1,-14,0,23),UDim2.fromOffset(7,304))

connect(armoryButton.Activated,function()
local area=workspace:FindFirstChild("AREA51")
local room=area and area:FindFirstChild("Amory2Room")
local armory=room and room:FindFirstChild("Armory")
local giver=armory and armory:FindFirstChild("Giver",true)

if giver then
local part=getTouchPart(giver)
if part and player.Character then
local root=player.Character:FindFirstChild("HumanoidRootPart")
if root and typeof(firetouchinterest)=="function" then
touchPart(root,part)
statusLabel.Text="Armory Giver activated"
return
end
end
end

statusLabel.Text="Armory Giver not found"
end)

connect(zombieButton.Activated,function()
local area=workspace:FindFirstChild("AREA51")
local outside=area and area:FindFirstChild("Outside")
local hangar=outside and outside:FindFirstChild("Hangar")
local right=hangar and hangar:FindFirstChild("Right")
local morph=right and right:FindFirstChild("Zombie Morph")
local button=morph and morph:FindFirstChild("TheButton")

if button then
local part=getTouchPart(button)
if part and player.Character then
local root=player.Character:FindFirstChild("HumanoidRootPart")
if root and typeof(firetouchinterest)=="function" then
touchPart(root,part)
statusLabel.Text="Zombie Morph activated"
return
end
end
end

statusLabel.Text="Zombie Morph button not found"
end)
-- === FIM DOS NOVOS BOTÕES ===

local colorNames={"Lennon","Red","Blue","White","Yellow"}
local colorIndex=1
connect(colorButton.Activated,function()
colorIndex=colorIndex%#colorNames+1
ESP_CONFIG.Color=colorNames[colorIndex]
colorButton.Text="COLOR: "..string.upper(ESP_CONFIG.Color)
end)
local ranges={100,250,500,1000,2500,10000}
local rangeIndex=4
connect(rangeButton.Activated,function()
rangeIndex=rangeIndex%#ranges+1
ESP_CONFIG.MaxDistance=ranges[rangeIndex]
rangeButton.Text="RANGE: "..ESP_CONFIG.MaxDistance
end)
connect(namesButton.Activated,function()
ESP_CONFIG.ShowNames=not ESP_CONFIG.ShowNames
namesButton.Text=ESP_CONFIG.ShowNames and "NAMES: ON" or "NAMES: OFF"
end)
connect(distanceButton.Activated,function()
ESP_CONFIG.ShowDistance=not ESP_CONFIG.ShowDistance
distanceButton.Text=ESP_CONFIG.ShowDistance and "DISTANCE: ON" or "DISTANCE: OFF"
end)

local function attachKillerFolder(folder)
if not folder or folder.Name~="Killers" then return end
connect(folder.ChildAdded,function(t)
task.delay(.15,function()
if not destroyed and espEnabled and t.Parent==folder then addESP(t) end
end)
end)
connect(folder.ChildRemoved,function(t)
local d=espObjects[t]
if d then destroyESPData(d);espObjects[t]=nil end
end)
if espEnabled then for _,t in ipairs(folder:GetChildren()) do addESP(t) end end
end
local folder=workspace:FindFirstChild("Killers")
if folder then attachKillerFolder(folder) end
connect(workspace.ChildAdded,function(o) if o.Name=="Killers" then attachKillerFolder(o) end end)

local discoveryQueued=false
connect(workspace.DescendantAdded,function(o)
if o.Name=="Paper" or o.Name=="Candy" or o.Name=="Hitbox" or o.Name=="Reward" or string.lower(o.Name)=="ammo" or string.lower(o.Name)=="ammobox" or string.lower(o.Name)=="ammunition" or string.lower(o.Name)=="ammopickup" then
if not discoveryQueued then
discoveryQueued=true
task.delay(.25,function()
discoveryQueued=false
if not destroyed then
local ok,err=pcall(discoverTargets)
if not ok then warn("Lennon Hub discovery:",err) end
end
end)
end
end
end)
connect(workspace.DescendantRemoving,function(o)
if o==cachedSpots or o==cachedQuest or o==cachedMansion or o==cachedArea then
cachedSpots,cachedQuest,cachedMansion,cachedArea=nil,nil,nil,nil
end
end)

connect(RunService.Heartbeat,function(dt)
if destroyed then return end
updateAccumulator+=dt
discoveryAccumulator+=dt
collectAccumulator+=dt
if updateAccumulator>=CONFIG.UpdateRate then
updateAccumulator%=CONFIG.UpdateRate
local c=player.Character
local root=c and c:FindFirstChild("HumanoidRootPart")
local color=getESPColor()
if espEnabled and root then
local closestDistance,closestName=math.huge,nil
for t,d in pairs(espObjects) do
if not t.Parent then
destroyESPData(d)
espObjects[t]=nil
else
local p=getTargetPart(t)
if p then
local distance=(root.Position-p.Position).Magnitude
local inRange=distance<=ESP_CONFIG.MaxDistance
d.highlight.Enabled=inRange
d.billboard.Enabled=inRange
d.billboard.Adornee=p
d.billboard.MaxDistance=ESP_CONFIG.MaxDistance
d.nameLabel.Visible=ESP_CONFIG.ShowNames
d.distanceLabel.Visible=ESP_CONFIG.ShowDistance
d.nameLabel.TextColor3=color
d.nameLabel.Text=t.Name
d.distanceLabel.Text=math.floor(distance).." studs"
d.highlight.FillColor=color
d.highlight.OutlineColor=color
if inRange and distance<closestDistance then closestDistance,closestName=distance,t.Name end
end
end
end
statusLabel.Text=closestName and string.format("%s | %d studs",closestName,math.floor(closestDistance)) or "No killer detected"
end
end
if discoveryAccumulator>=CONFIG.DiscoveryRate then
discoveryAccumulator%=CONFIG.DiscoveryRate
local ok,err=pcall(discoverTargets)
if not ok then warn("Lennon Hub discovery:",err) end
end
if collectAccumulator>=CONFIG.UpdateRate then
collectAccumulator%=CONFIG.UpdateRate
if allEnabled then collectEverything() elseif ammoEnabled then collectAmmoOnly() end
end
chromaHue=(chromaHue+dt*CONFIG.ChromaSpeed)%1
local chroma=Color3.fromHSV(chromaHue,.9,1)
mainStroke.Color=chroma
floatingTPStroke.Color=chroma
floatingMenuStroke.Color=chroma
title.TextColor3=chroma
for _,o in ipairs(uiStrokes) do if o.Parent then o.Color=chroma end end
end)

local function makeDraggable(button)
local dragging,moved=false,false
local startPosition,originalPosition,activeTouch
connect(button.InputBegan,function(input)
if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
dragging=true
moved=false
startPosition=input.Position
originalPosition=button.Position
activeTouch=input.UserInputType==Enum.UserInputType.Touch and input or nil
end)
connect(UserInputService.InputChanged,function(input)
if not dragging then return end
local matches=input.UserInputType==Enum.UserInputType.MouseMovement or (activeTouch and input==activeTouch)
if not matches then return end
local delta=input.Position-startPosition
if delta.Magnitude>7 then moved=true end
if moved then button.Position=UDim2.new(originalPosition.X.Scale,originalPosition.X.Offset+delta.X,originalPosition.Y.Scale,originalPosition.Y.Offset+delta.Y) end
end)
connect(UserInputService.InputEnded,function(input)
if not dragging then return end
local ended=input.UserInputType==Enum.UserInputType.MouseButton1 or (activeTouch and input==activeTouch)
if ended then
dragging=false
activeTouch=nil
if not moved and button==floatingMenu then setGuiVisible(not main.Visible) end
end
end)
end
makeDraggable(floatingTP)
makeDraggable(floatingMenu)

connect(closeButton.Activated,function()
main.Visible=false
floatingMenu.Text="OPEN"
confirm.Visible=true
end)
connect(noButton.Activated,function() setGuiVisible(true) end)
local function cleanup()
if destroyed then return end
destroyed=true
clearESP()
for _,c in ipairs(connections) do if c.Connected then c:Disconnect() end end
table.clear(connections)
gui:Destroy()
end
connect(yesButton.Activated,cleanup)

local ok,err=pcall(discoverTargets)
if ok then
statusLabel.Text="Ready"
else
statusLabel.Text="Discovery error"
warn("Lennon Hub initial discovery:",err)
end
end
