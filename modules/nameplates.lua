	ShaguPlates:RegisterModule("nameplates", "vanilla:tbc", function ()
	-- disable original castbars
	pcall(SetCVar, "ShowVKeyCastbar", 0)

	local scanTool = CreateFrame( "GameTooltip", "ScanTooltip", nil, "GameTooltipTemplate" )
	scanTool:SetOwner( WorldFrame, "ANCHOR_NONE" )
	local scanTextLine2 = _G["ScanTooltipTextLeft2"] -- This is the line with <[Player]'s Pet>
	--local scanTextLine3 = _G["ScanTooltipTextLeft3"] -- This is the line with <[Player]'s Pet>

	local elitestrings = {
	["elite"] = "+",
	["rareelite"] = "R+",
	["rare"] = "R",
	["boss"] = "B"
	}
	
	function getClassPos(class)
		if(class=="WARRIOR") then return 0,    0.25,    0,	0.25;	end
		if(class=="MAGE")    then return 0.25, 0.5,     0,	0.25;	end
		if(class=="ROGUE")   then return 0.5,  0.75,    0,	0.25;	end
		if(class=="DRUID")   then return 0.75, 1,       0,	0.25;	end
		if(class=="HUNTER")  then return 0,    0.25,    0.25,	0.5;	end
		if(class=="SHAMAN")  then return 0.25, 0.5,     0.25,	0.5;	end
		if(class=="PRIEST")  then return 0.5,  0.75,    0.25,	0.5;	end
		if(class=="WARLOCK") then return 0.75, 1,       0.25,	0.5;	end
		if(class=="PALADIN") then return 0,    0.25,    0.5,	0.75;	end
		return 0.25, 0.5, 0.5, 0.75	-- Returns empty next one, so blank
	end

	-- catch all nameplates
	local childs, regions, plate
	local initialized = 0
	local parentcount = 0
	local platecount = 0
	local registry = {}
	local debuffdurations = true

	-- ALL CONFIG VARIABLES
	local nameplatesTotemIcons = true

	local nameplatesFullhealth = true
	local nameplatesTarget = true

	local nameplatesEnemynpc = true
	local nameplatesEnemyplayer = true
	local nameplatesNeutralnpc = true
	local nameplatesFriendlynpc = true
	local nameplatesFriendlyplayer = true
	local nameplatesCritters = true
	local nameplatesTotems = true

	local nameplatesDebuffsize = 18
	local nameplatesDebuffOffset = 20

	local nameplatesSelfdebuff = 0

	local nameplatesUseUnitfonts = true

	local globalFontUnitSize = 12

	local globalFontSize = 12

	local nameplatesNameFontstyle = "OUTLINE"


	local nameplatesGlowcolor = "0.4,1,1,0.7"
	local nameplatesHighlightcolor = "0.5,0.9,1,1"
	local nameplatesHealthtexture = "Interface\\AddOns\\ShaguPlates\\img\\statusbar\\XPerl_StatusBar4"

	local nameplatesDebuffsPosition = "TOP"

	local nameplateWidthGrayLevel = 70

	local nameplateWidthCritter = 50
	local nameplatesHeighthealthCritter = 8

	local nameplateWidth = 115
	local nameplatesHeighthealth = 14
	local nameplatesHeightcast = 8
	
	local nameplatesHeightPower = 7

	local nameplatesHealthOffset = 3
	local nameplatesVerticalhealth = false

	local nameplatesHptextpos = "RIGHT"


	local nameplatesRaidiconpos = "RIGHT"
	local nameplatesRaidiconoffx = 40
	local nameplatesRaidiconoffy = 0
	local nameplatesRaidiconsize = 35


	local nameplatesTargetglow = true

	local nameplatesOutcombatstate = false

	local nameplatesTargethighlight = true


	local nameplatesShowhp = true

	local nameplatesHptextformat = "cur"

	local nameplatesCpdisplay = true

	local nameplatesShowdebuffs = true

	local nameplatesGuessdebuffs = true

	local nameplatesNamefightcolor = true

	local nameplatesNotargalpha = .75

	local nameplatesShowhostile = true
	local nameplatesShowfriendly = false


	local nameplatesOverlap = true
	local nameplatesVerticalOffset = "0"
	local nameplatesRightclick = true
	local nameplatesClickthrough = "0"
	local nameplatesClickthreshold = "0"
	
	local nameplateOffsetY = -20

	--------------------------

	-- cache default border color
	--local er, eg, eb, ea = GetStringColor("0.2,0.2,0.2,0.1")
	
	local er, eg, eb, ea = 0.2,0.2,0.2,0.1

	local function DoNothing()
	return
	end

	local function IsNamePlate(frame)
	if frame:GetObjectType() ~= NAMEPLATE_FRAMETYPE then return nil end
	regions = plate:GetRegions()

	if not regions then return nil end
	if not regions.GetObjectType then return nil end
	if not regions.GetTexture then return nil end

	if regions:GetObjectType() ~= "Texture" then return nil end
	return regions:GetTexture() == "Interface\\Tooltips\\Nameplate-Border" or nil
	end

	local function DisableObject(object)
	if not object then return end
	if not object.GetObjectType then return end

	local otype = object:GetObjectType()

	if otype == "Texture" then
	  object:SetTexture("")
	  object:SetTexCoord(0, 0, 0, 0)
	elseif otype == "FontString" then
	  object:SetWidth(0.001)
	elseif otype == "StatusBar" then
	  object:SetStatusBarTexture("")
	end
	end

	local function TotemPlate(name)
	if nameplatesTotemIcons then
	  for totem, icon in pairs(L["totems"]) do
		if string.find(name, totem) then return icon end
	  end
	end
	end

	local function GetUnitType(red, green, blue)
	if red > .9 and green < .2 and blue < .2 then
	  return "ENEMY_NPC"
	elseif red > .9 and green > .9 and blue < .2 then
	  return "NEUTRAL_NPC"
	elseif red < .2 and green < .2 and blue > 0.9 then
	  return "FRIENDLY_PLAYER"
	elseif red < .2 and green > .9 and blue < .2 then
	  return "FRIENDLY_NPC"
	end
	end

	local list, cache

	local function PlateCacheDebuffs(self, unitstr, verify)
	if not self.debuffcache then self.debuffcache = {} end

	for id = 1, 16 do
	  local effect, _, texture, stacks, _, duration, timeleft

	  if unitstr and nameplatesSelfdebuff == "1" then
		effect, _, texture, stacks, _, duration, timeleft = libdebuff:UnitOwnDebuff(unitstr, id)
	  else
		effect, _, texture, stacks, _, duration, timeleft = libdebuff:UnitDebuff(unitstr, id)
	  end

	  if effect and timeleft and timeleft > 0 then
		local start = GetTime() - ( (duration or 0) - ( timeleft or 0) )
		local stop = GetTime() + ( timeleft or 0 )
		self.debuffcache[id] = self.debuffcache[id] or {}
		self.debuffcache[id].effect = effect
		self.debuffcache[id].texture = texture
		self.debuffcache[id].stacks = stacks
		self.debuffcache[id].duration = duration or 0
		self.debuffcache[id].start = start
		self.debuffcache[id].stop = stop
		self.debuffcache[id].empty = nil
	  end
	end

	self.verify = verify
	end

	local function PlateUnitDebuff(self, id)
	-- break on unknown data
	if not self.debuffcache then return end
	if not self.debuffcache[id] then return end
	if not self.debuffcache[id].stop then return end

	-- break on timeout debuffs
	if self.debuffcache[id].empty then return end
	if self.debuffcache[id].stop < GetTime() then return end

	-- return cached debuff
	local cSelfDefuffCache = self.debuffcache[id]
	return cSelfDefuffCache.effect, cSelfDefuffCache.rank, cSelfDefuffCache.texture, cSelfDefuffCache.stacks, cSelfDefuffCache.dtype, cSelfDefuffCache.duration, (cSelfDefuffCache.stop - GetTime())
	end

	local function CreateDebuffIcon(plate, index)
	plate.debuffs[index] = CreateFrame("Frame", plate.platename.."Debuff"..index, plate)
	plate.debuffs[index]:Hide()
	plate.debuffs[index]:SetFrameLevel(1)

	plate.debuffs[index].icon = plate.debuffs[index]:CreateTexture(nil, "BACKGROUND")
	plate.debuffs[index].icon:SetTexture(.3,1,.8,1)
	plate.debuffs[index].icon:SetAllPoints(plate.debuffs[index])

	plate.debuffs[index].stacks = plate.debuffs[index]:CreateFontString(nil, "OVERLAY")
	plate.debuffs[index].stacks:SetAllPoints(plate.debuffs[index])
	plate.debuffs[index].stacks:SetJustifyH("RIGHT")
	plate.debuffs[index].stacks:SetJustifyV("BOTTOM")
	plate.debuffs[index].stacks:SetTextColor(1,1,0)

	if ShaguPlates.client <= 11200 then
	  -- create a fake animation frame on vanilla to improve performance
	  plate.debuffs[index].cd = CreateFrame("Frame", plate.platename.."Debuff"..index.."Cooldown", plate.debuffs[index])
	  plate.debuffs[index].cd:SetScript("OnUpdate", CooldownFrame_OnUpdateModel)
	  plate.debuffs[index].cd.AdvanceTime = DoNothing
	  plate.debuffs[index].cd.SetSequence = DoNothing
	  plate.debuffs[index].cd.SetSequenceTime = DoNothing
	else
	  -- use regular cooldown animation frames on burning crusade and later
	  plate.debuffs[index].cd = CreateFrame(COOLDOWN_FRAME_TYPE, plate.platename.."Debuff"..index.."Cooldown", plate.debuffs[index], "CooldownFrameTemplate")
	end

	plate.debuffs[index].cd.pfCooldownStyleAnimation = 0
	plate.debuffs[index].cd.pfCooldownType = "ALL"
	end

	function GetActivePlateCount()
	local activePlateCount = 0
	local parentcountx = WorldFrame:GetNumChildren()
	local childrenx = { WorldFrame:GetChildren() }
	for i = 1, parentcountx do
		local platexx = _G["pfNamePlate" .. i]
		if platexx and platexx:IsVisible() then
			activePlateCount = activePlateCount + 1
		end
	end
	--print(activePlateCount)
	return activePlateCount
	end

	local isBalloon = function(f)
	  if f:GetName() then return end
	  if not f:GetRegions() then return end
	  return f:GetRegions():GetTexture() == [[Interface\Tooltips\ChatBubble-Background]]
	end

	local styleBalloon = function(f)
	  local r = {f:GetRegions()}
	  for _, v in pairs(r) do
		  if  v:GetObjectType() == 'Texture' then
			  --v:SetDrawLayer'OVERLAY'
			  if  v:GetTexture() == [[Interface\Tooltips\ChatBubble-Background]] or v:GetTexture() == [[Interface\Tooltips\ChatBubble-Backdrop]] then
				  --v:SetTexture''
				-- DoNothing()
			  elseif (v:GetTexture() == [[Interface\Tooltips\ChatBubble-Tail]]) then
				--print("asdasdasd")
				--v:SetTexture("")
			  end
		  elseif  v:GetObjectType() == 'FontString' then
			  f.textstring = v
		  end
	  end
	  -- if not string.find(f.textstring:GetText(), "\n\n\n\n") then
		-- f.textstring:SetText(f.textstring:GetText().."\n\n\n\n")
	  -- end
	  if not f.skinned then
	  
	  
		-- local BACKDROP = {  bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
					-- edgeFile = nil,
					-- edgeSize = 0,
					-- insets = {left = 2, right = 2, top = 2, bottom = 2},}
					
		-- local BACKDROP = {  bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
					-- edgeFile = nil,
					-- edgeSize = 8,
					-- insets = {left = 2, right = 2, top = 2, bottom = 2},}

		--modSkin(f, 1)
		--modSkinColor(f, .7, .7, .7)
		-- f:SetBackdrop(BACKDROP)
		-- f:SetBackdropColor(0, 0, 0, .8)
		--f.textstring:SetSpacing(5)
		
		-- f:SetBackdrop({
			-- bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			-- edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			-- edgeSize = 16,
			-- insets = { left = 4, right = 4, top = 4, bottom = 4 },
		-- })
		--f:SetBackdropColor(0, 0, 1, .5)
		
		f.textstring:SetFont(STANDARD_TEXT_FONT, 10)
		--f.textstring:SetText("wasdas: "..f.textstring:GetText())
		--local point, relativeTo, relativePoint, xOfs, yOfs = f:GetPoint(n)
		--f:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs+40)

		--local parx = f.GetParent()
		
		-- f.parent:SetDrawLayer("OVERLAY")
		-- f.parent:SetFrameLevel(4)
		-- f.parent:SetFrameStrata("TOOLTIP")

		-- local numpoints = f:GetNumPoints()
		-- for i=1, numpoints do
			-- --local point, relativeTo, relativePoint, xOfs, yOfs = f:GetPoint(i)
			-- --f:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs+40)
			
			-- local point, relativeTo, relativePoint, xOfs, yOfs = f:GetPoint(i)
			-- if i == 1 then
				-- f:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
			-- else
				-- f:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs+40)
			-- end
		-- end
		
		
		--f:SetHeight(v:GetHeight() + 50)
		
		--f.textstring:SetText(f.textstring:GetText().."\n\n\n\n")
		
		-- f.textstring:SetSpacing(500)
		
		-- local numpointstxt = f.textstring:GetNumPoints()
		-- for i=1, numpointstxt do
			-- local point, relativeTo, relativePoint, xOfs, yOfs = f.textstring:GetPoint(i)
			-- f.textstring:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs+40)
		-- end
		
		--f.parent:Show()

		--local point, relativeTo, relativePoint, xOfs, yOfs = f:GetPoint(1)
		--f:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs+40)
		f.skinned = true
	  end
	end

	local function UpdateDebuffConfig(nameplate, i)
		if not nameplate.debuffs[i] then return end

		-- update debuff positions
		local width = tonumber(nameplateWidth)
		local debuffsize = tonumber(nameplatesDebuffsize)
		local debuffoffset = tonumber(nameplatesDebuffOffset)
		local limit = floor(width / debuffsize)
		local font = nameplatesUseUnitfonts and ShaguPlates.font_unit or ShaguPlates.font_default
		local font_size = nameplatesUseUnitfonts and globalFontUnitSize or globalFontSize
		local font_style = nameplatesNameFontstyle

		local aligna, alignb, offs, space
		if nameplatesDebuffsPosition == "BOTTOM" then
		  aligna, alignb, offs, space = "TOPLEFT", "BOTTOMLEFT", -debuffoffset, -1
		else
		  aligna, alignb, offs, space = "BOTTOMLEFT", "CENTER", debuffoffset, 1
		end

		nameplate.debuffs[i].stacks:SetFont(font, font_size, font_style)
		nameplate.debuffs[i]:ClearAllPoints()
		if i == 1 then
		  -- if nameplate.guild:GetText() and string.len(nameplate.guild:GetText()) > 0 and nameplate.guild:IsShown() then
			-- nameplate.debuffs[i]:SetPoint(aligna, nameplate.name, alignb, 0, offs)
		  -- else
			-- nameplate.debuffs[i]:SetPoint(aligna, nameplate.health, alignb, 0, offs)
		  -- end
		  nameplate.debuffs[i]:SetPoint(aligna, nameplate.name, alignb, -(nameplate.health:GetWidth()/2), offs)
		elseif i <= limit then
		  nameplate.debuffs[i]:SetPoint("LEFT", nameplate.debuffs[i-1], "RIGHT", 1, 0)
		elseif i > limit and limit > 0 then
		  nameplate.debuffs[i]:SetPoint(aligna, nameplate.debuffs[i-limit], alignb, 0, space)
		end

		nameplate.debuffs[i]:SetWidth(tonumber(nameplatesDebuffsize))
		nameplate.debuffs[i]:SetHeight(tonumber(nameplatesDebuffsize))
	end

	-- create nameplate core
	local nameplates = CreateFrame("Frame", "pfNameplates", UIParent)
	nameplates:RegisterEvent("PLAYER_ENTERING_WORLD")
	nameplates:RegisterEvent("PLAYER_TARGET_CHANGED")
	nameplates:RegisterEvent("UNIT_COMBO_POINTS")
	nameplates:RegisterEvent("PLAYER_COMBO_POINTS")
	nameplates:RegisterEvent("UNIT_AURA")
	--nameplates:RegisterEvent("CHAT_MSG_ADDON")
	
	local function explode(str, delimiter)
		local result = {}
		local from = 1
		local delim_from, delim_to = string.find(str, delimiter, from, 1, true)
		while delim_from do
			table.insert(result, string.sub(str, from, delim_from - 1))
			from = delim_to + 1
			delim_from, delim_to = string.find(str, delimiter, from, true)
		end
		table.insert(result, string.sub(str, from))
		return result
	end

	nameplates:SetScript("OnEvent", function()
		if event == "PLAYER_ENTERING_WORLD" then
		  this:SetGameVariables()
		else
		  this.eventcache = true
		end
		
		-- if event == "CHAT_MSG_ADDON" and string.find(arg2, "TWTv4=", 1, true) then
			-- --me.processthreatupdate(arg2)
			-- --return 
			-- print("yessssss")
			
			-- local message = arg2
			
			-- local playersString = string.sub(message, find(message, "TWTv4=") + string.len("TWTv4="), string.len(message))

			-- local players = explode(playersString, ';')

			-- for _, tData in players do

				-- local msgEx = explode(tData, ':')

				-- -- udts handling
				-- if msgEx[1] and msgEx[2] and msgEx[3] and msgEx[4] and msgEx[5] then

					-- local player = msgEx[1]
					-- local tank = msgEx[2] == '1'
					-- local threat = tonumber(msgEx[3])
					-- local perc = tonumber(msgEx[4])
					-- local melee = msgEx[5] == '1'

					-- --mod.table.updateplayerthreat(player, threat)
					-- --KLHTM_RequestRedraw("raid")
					
					-- print("player: "..player.." tank: "..tank.." perc: "..perc)
				-- end
			-- end
			
		-- else
			-- --print("yessssss0")
			-- SendAddonMessage("TWT_UDTSv4", "limit=" .. 5, "PARTY")
			-- --print("yessssss1")
		-- end
		
	end)

	nameplates:SetScript("OnUpdate", function()
		-- propagate events to all nameplates
		if this.eventcache then
		  this.eventcache = nil
		  for plate in pairs(registry) do
			plate.eventcache = true
		  end
		end

		-- detect new nameplates
		parentcount = WorldFrame:GetNumChildren()
		if initialized < parentcount then
		  childs = { WorldFrame:GetChildren() }
		  for i = initialized + 1, parentcount do
			plate = childs[i]
			if IsNamePlate(plate) and not registry[plate] then
			  nameplates.OnCreate(plate)
			  registry[plate] = plate
			end
		  end

		  initialized = parentcount
		end

		--print("h1")
		--local newNumKids = WorldFrame:GetNumChildren()
		local f = {WorldFrame:GetChildren()}
		for _, v in pairs(f) do
			--print("aaa")
			--print("aaa")
			if isBalloon(v) then
				styleBalloon(v)
				--print("aaa2")
				--v:SetDrawLayer("OVERLAY")
				--v:SetFrameLevel(4)
				--v:SetFrameStrata("TOOLTIP")
				--v:SetHeight(v:GetHeight() + 50)
				--print("h"..v:GetHeight())
				
				--v:GetParent():SetPoint("BOTTOM", nil, "TOP", -2, 28)
				
				--print("h"..v.parent:GetText())
			end
		end

	end)

	-- combat tracker
	nameplates.combat = CreateFrame("Frame")
	nameplates.combat:RegisterEvent("PLAYER_ENTER_COMBAT")
	nameplates.combat:RegisterEvent("PLAYER_LEAVE_COMBAT")
	nameplates.combat:SetScript("OnEvent", function()
	if event == "PLAYER_ENTER_COMBAT" then
	  this.inCombat = 1
	  if PlayerFrame then PlayerFrame.inCombat = 1 end
	elseif event == "PLAYER_LEAVE_COMBAT" then
	  this.inCombat = nil
	  if PlayerFrame then PlayerFrame.inCombat = nil end
	end
	end)

nameplates.OnCreate = function(frame)
	local parent = frame or this
	platecount = platecount + 1
	platename = "pfNamePlate" .. platecount
	
	local font_size = nameplatesUseUnitfonts and globalFontUnitSize or globalFontSize
	
	local plate_width = nameplateWidth + 50
	local plate_height = nameplatesHeighthealth + font_size + 5
	
	local rawborderx, default_border = GetBorderSize("nameplates")
	
	local glowr, glowg, glowb, glowa = 0.4, 1,1, 0.7, 0.5
	
	local combo_size = 5

	-- create ShaguPlates nameplate overlay
	local nameplate = CreateFrame("Button", platename, parent)
	nameplate.platename = platename
	--nameplate:EnableMouse(0)
	nameplate.parent = parent
	nameplate.cache = {}
	nameplate.UnitDebuff = PlateUnitDebuff
	nameplate.CacheDebuffs = PlateCacheDebuffs
	nameplate.original = {}
	
	nameplate.distanceToPlayer = 999
	nameplate.desiredYOffset = 0
	nameplate.currentYOffset = 0

	-- create shortcuts for all known elements and disable them
	nameplate.original.healthbar, nameplate.original.castbar = parent:GetChildren()
	DisableObject(nameplate.original.healthbar)
	DisableObject(nameplate.original.castbar)

	for i, object in pairs({parent:GetRegions()}) do
	  if NAMEPLATE_OBJECTORDER[i] and NAMEPLATE_OBJECTORDER[i] == "raidicon" then
		nameplate[NAMEPLATE_OBJECTORDER[i]] = object
	  elseif NAMEPLATE_OBJECTORDER[i] then
		nameplate.original[NAMEPLATE_OBJECTORDER[i]] = object
		DisableObject(object)
	  else
		DisableObject(object)
	  end
	end

	HookScript(nameplate.original.healthbar, "OnValueChanged", nameplates.OnValueChanged)

	-- adjust sizes and scaling of the nameplate
	nameplate:SetScale(UIParent:GetScale())
	
	nameplate:SetWidth(plate_width)
	nameplate:SetPoint("TOP", parent, "TOP", 0, 0)
	-- nameplate:SetPoint("TOP", parent, "TOP", 0, nameplateOffsetY)
	
	-----------------------------------

	nameplate.health = CreateFrame("StatusBar", nil, nameplate)
	nameplate.health:SetFrameLevel(1) -- keep above glow
	nameplate.health:SetOrientation("HORIZONTAL")
	nameplate.health:SetStatusBarTexture(nameplatesHealthtexture)
	nameplate.health.hlr, nameplate.health.hlg, nameplate.health.hlb, nameplate.health.hla = glowr, glowg, glowb, 1
	
	nameplate.health.text = nameplate.health:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	--nameplate.health.text:SetAllPoints()
	nameplate.health.text:SetFont("Interface\\AddOns\\ShaguPlates\\fonts\\francois.ttf", font_size - 2, "OUTLINE")
	nameplate.health.text:SetJustifyH(nameplatesHptextpos)
	nameplate.health.text:SetPoint("RIGHT", nameplate.health, "RIGHT", -2, -4)
	nameplate.health.text:SetTextColor(1,1,1,1)
	CreateBackdrop(nameplate.health, default_border)
	
	nameplate.power = CreateFrame("StatusBar", nil, nameplate)
	nameplate.power:SetFrameLevel(1) -- keep above glow
	nameplate.power:SetOrientation("HORIZONTAL")
	nameplate.power:SetPoint("TOP", nameplate.health, "BOTTOM", 0, 0)
	nameplate.power:SetStatusBarTexture("Interface\\AddOns\\ShaguPlates\\img\\statusbar\\XPerl_StatusBar7")
	nameplate.power.hlr, nameplate.power.hlg, nameplate.power.hlb, nameplate.power.hla = glowr, glowg, glowb, 1
	
	nameplate.power.text = nameplate.power:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	nameplate.power.text:SetFont(ShaguPlates.font_unit, 8, "OUTLINE")
	nameplate.power.text:SetJustifyH(nameplatesHptextpos)
	--nameplate.health.text:SetAllPoints()
	nameplate.power.text:SetPoint("RIGHT", nameplate.power, "RIGHT", -2, -4)
	nameplate.power.text:SetTextColor(1,1,1,1)
	CreateBackdrop(nameplate.power, default_border)

	nameplate.guild = nameplate:CreateFontString(nil, "OVERLAY")
	--nameplate.guild:SetPoint("BOTTOM", nameplate.health, "BOTTOM", 0, 0)
	--nameplate.guild:SetPoint("TOP", nameplate, "TOP", 0, 0)
	nameplate.guild:SetPoint("BOTTOM", plate, "TOP", 0, 0)
	nameplate.guild:SetFont("Interface\\AddOns\\ShaguPlates\\fonts\\francois.ttf", font_size, "OUTLINE")

	nameplate.name = nameplate:CreateFontString(nil, "OVERLAY")
	--nameplate.name:SetPoint("TOP", nameplate, "TOP", 0, 0)
	--nameplate.name:SetPoint("TOP", nameplate.guild, "TOP", 0, 0)
	nameplate.name:SetPoint("BOTTOM", nameplate.guild, "TOP", 0, 0)
	nameplate.name:SetFont("Interface\\AddOns\\ShaguPlates\\fonts\\francois.ttf", font_size, nameplatesNameFontstyle)

	nameplate.classIcon = CreateFrame("Frame", nil, nameplate)
	nameplate.classIcon:SetPoint("RIGHT", nameplate.name, "LEFT", -2, 4)
	nameplate.classIcon:SetHeight(20)
	nameplate.classIcon:SetWidth(20)
	nameplate.classIcon.icon = nameplate.classIcon:CreateTexture(nil, "ARTWORK")
	--nameplate.typeIcon.icon:SetTexCoord(.078, .92, .079, .937)
	--nameplate.classIcon.icon:SetAllPoints()
	--nameplate.typeIcon.icon:SetTexture("Interface\\Icons\\" .. "spell_holy_sealofsalvation.blp")
	--nameplate.classIcon.icon:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\classicons\\UNKNOWN.tga")
	nameplate.classIcon.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
	nameplate.classIcon.icon:SetAllPoints()
	nameplate.classIcon:Hide()

	nameplate.typeIcon = CreateFrame("Frame", nil, nameplate)
	nameplate.typeIcon:SetFrameLevel(1)
	nameplate.typeIcon:SetPoint("RIGHT", nameplate.health, "LEFT", -2, 0)
	nameplate.typeIcon:SetHeight(nameplatesHeighthealth)
	nameplate.typeIcon:SetWidth(nameplatesHeighthealth)
	nameplate.typeIcon.icon = nameplate.typeIcon:CreateTexture(nil, "OVERLAY")
	--nameplate.typeIcon.icon:SetTexCoord(.078, .92, .079, .937)
	nameplate.typeIcon.icon:SetAllPoints()
	--nameplate.typeIcon.icon:SetTexture("Interface\\Icons\\" .. "spell_holy_sealofsalvation.blp")
	nameplate.typeIcon.icon:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\creaturetypes\\UNKNOWN.tga")
	CreateBackdrop(nameplate.typeIcon, 1)
	nameplate.typeIcon:Show()

	nameplate.glow = nameplate:CreateTexture(nil, "BACKGROUND")
	nameplate.glow:SetPoint("LEFT", nameplate.typeIcon, "LEFT", -30, 0)
	nameplate.glow:SetTexture(ShaguPlates.media["img:arrow_left"])
	--nameplate.glow:SetFrameLevel(1)
	nameplate.glow:SetDrawLayer("BACKGROUND")
	nameplate.glow:SetWidth(30)
	nameplate.glow:SetHeight(30)
	nameplate.glow:SetVertexColor(glowr, glowg, glowb, glowa)
	nameplate.glow:Hide()

	nameplate.glow2 = nameplate:CreateTexture(nil, "BACKGROUND")
	nameplate.glow2:SetPoint("RIGHT", nameplate.health, "RIGHT", 30, 0)
	nameplate.glow2:SetTexture(ShaguPlates.media["img:arrow_right"])
	--nameplate.glow:SetFrameLevel(1)
	nameplate.glow2:SetDrawLayer("BACKGROUND")
	--nameplate.glow2.texture:SetRotation(2)
	nameplate.glow2:SetWidth(30)
	nameplate.glow2:SetHeight(30)
	nameplate.glow2:SetVertexColor(glowr, glowg, glowb, glowa)
	nameplate.glow2:Hide()
	
	nameplate.selectionGlow = nameplate:CreateTexture(nil, "BACKGROUND")
	nameplate.selectionGlow:SetPoint("CENTER", nameplate.health, "CENTER", 0, 0)
	nameplate.selectionGlow:SetTexture(ShaguPlates.media["img:dot"])
	nameplate.selectionGlow:SetDrawLayer("BACKGROUND")
	nameplate.selectionGlow:SetVertexColor(glowr, glowg, glowb, 0.5)
	nameplate.selectionGlow:Hide()

	nameplate.level = nameplate:CreateFontString(nil, "OVERLAY")
	-- nameplate.level:SetPoint("LEFT", nameplate.health, "LEFT", 3, -8)
	nameplate.level:SetPoint("TOP", nameplate.typeIcon, "BOTTOM", 0, 0)
	nameplate.level:SetDrawLayer("OVERLAY")
	nameplate.level:SetFont("Interface\\AddOns\\ShaguPlates\\fonts\\francois.ttf", font_size, nameplatesNameFontstyle)

	nameplate.rarityIcon = CreateFrame("Frame", nil, nameplate)
	nameplate.rarityIcon:SetFrameLevel(0)
	nameplate.rarityIcon:SetPoint("RIGHT", nameplate.typeIcon, "LEFT", 26, -1)
	nameplate.rarityIcon:SetHeight(44)
	nameplate.rarityIcon:SetWidth(42)
	nameplate.rarityIcon.icon = nameplate.rarityIcon:CreateTexture(nil, "BORDER")
	nameplate.rarityIcon.icon:SetTexCoord(1, 0, 0, 1)
	nameplate.rarityIcon.icon:SetVertexColor(1, 1, 0, 1)
	nameplate.rarityIcon.icon:SetAllPoints()
	nameplate.rarityIcon.icon:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\frame_elite")
	nameplate.rarityIcon:Hide()

	nameplate.rarityIconR = CreateFrame("Frame", nil, nameplate)
	nameplate.rarityIconR:SetFrameLevel(0)
	nameplate.rarityIconR:SetPoint("LEFT", nameplate.health, "RIGHT", -26, -1)
	nameplate.rarityIconR:SetHeight(44)
	nameplate.rarityIconR:SetWidth(42)
	nameplate.rarityIconR.icon = nameplate.rarityIconR:CreateTexture(nil, "BORDER")
	--nameplate.rarityIconR.icon:SetTexCoord(1, 0, 0, 1)
	nameplate.rarityIconR.icon:SetVertexColor(1, 1, 0, 1)
	nameplate.rarityIconR.icon:SetAllPoints()
	nameplate.rarityIconR.icon:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\frame_elite")
	nameplate.rarityIconR:Hide()
	
	nameplate.petHappiness = CreateFrame("Frame", nil, nameplate)
	nameplate.petHappiness:SetFrameLevel(0)
	nameplate.petHappiness:SetPoint("LEFT", nameplate.name, "RIGHT", -0, 4)
	nameplate.petHappiness:SetHeight(20)
	nameplate.petHappiness:SetWidth(20)
	nameplate.petHappiness.icon = nameplate.petHappiness:CreateTexture(nil, "OVERLAY")
	--nameplate.rarityIconR.icon:SetTexCoord(1, 0, 0, 1)
	--nameplate.combatIcon.icon:SetVertexColor(1, 1, 0, 1)
	nameplate.petHappiness.icon:SetAllPoints()
	nameplate.petHappiness.icon:SetTexture("Interface\\PetPaperDollFrame\\UI-PetHappiness")
	nameplate.petHappiness:Hide()
	
	nameplate.combatIcon = CreateFrame("Frame", nil, nameplate)
	nameplate.combatIcon:SetFrameLevel(0)
	nameplate.combatIcon:SetPoint("LEFT", nameplate.name, "RIGHT", -0, -0)
	nameplate.combatIcon:SetHeight(20)
	nameplate.combatIcon:SetWidth(20)
	nameplate.combatIcon.icon = nameplate.combatIcon:CreateTexture(nil, "OVERLAY")
	--nameplate.rarityIconR.icon:SetTexCoord(1, 0, 0, 1)
	--nameplate.combatIcon.icon:SetVertexColor(1, 1, 0, 1)
	nameplate.combatIcon.icon:SetAllPoints()
	nameplate.combatIcon.icon:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\combat\\swords_combat_2")
	nameplate.combatIcon:Hide()
	
	-- nameplate.attackIcon = CreateFrame("Frame", nil, nameplate)
	-- nameplate.attackIcon:SetFrameLevel(0)
	-- nameplate.attackIcon:SetPoint("RIGHT", nameplate.health, "LEFT", -10, -0)
	-- nameplate.attackIcon:SetHeight(25)
	-- nameplate.attackIcon:SetWidth(25)
	-- nameplate.attackIcon.icon = nameplate.attackIcon:CreateTexture(nil, "OVERLAY")
	-- nameplate.attackIcon.icon:SetAllPoints()
	-- nameplate.attackIcon.icon:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\combat\\swords_combat_2")
	-- nameplate.attackIcon:Hide()

	nameplate.raidicon:SetParent(nameplate.health)
	nameplate.raidicon:SetDrawLayer("OVERLAY")
	--nameplate.raidicon:SetTexture(ShaguPlates.media["img:raidicons"])
	nameplate.raidicon:SetTexture("Interface\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp")
	--nameplate.raidicon:ClearAllPoints()
	nameplate.raidicon:SetPoint(nameplatesRaidiconpos, nameplate.health, nameplatesRaidiconpos, nameplatesRaidiconoffx, nameplatesRaidiconoffy)
	nameplate.raidicon:SetWidth(nameplatesRaidiconsize)
	nameplate.raidicon:SetHeight(nameplatesRaidiconsize)

	nameplate.totem = CreateFrame("Frame", nil, nameplate)
	nameplate.totem:SetPoint("CENTER", nameplate, "CENTER", 0, 0)
	nameplate.totem:SetHeight(32)
	nameplate.totem:SetWidth(32)
	nameplate.totem.icon = nameplate.totem:CreateTexture(nil, "OVERLAY")
	nameplate.totem.icon:SetTexCoord(.078, .92, .079, .937)
	nameplate.totem.icon:SetAllPoints()
	CreateBackdrop(nameplate.totem)
	--nameplate.totem:Show()
	
	
	nameplate:SetScript("OnLeave", function()
		GameTooltip:Hide()
		nameplate.selectionGlow:Hide()
		local r,g,b = nameplate.original.name:GetTextColor()
		nameplate.name:SetTextColor(r,g,b, 1)
		
		nameplate.isInMouseOver = false
		nameplates:OnDataChanged(nameplate)
    end)
	
	nameplate:SetScript("OnMouseUp", function()
		if MouseIsOver(nameplate) then
			parent:Click(arg1)
		end
	end)
	
	--

	do -- debuffs
	  nameplate.debuffs = {}
	  CreateDebuffIcon(nameplate, 1)
	end
	
	for i=1,16 do
	  UpdateDebuffConfig(nameplate, i)
	end
	
	--

	do -- combopoints
	  local combopoints = { }
	  for i = 1, 5 do
		combopoints[i] = CreateFrame("Frame", nil, nameplate)
		combopoints[i]:Hide()
		combopoints[i]:SetFrameLevel(8)
		combopoints[i].tex = combopoints[i]:CreateTexture("OVERLAY")
		combopoints[i].tex:SetAllPoints()

		if i < 3 then
		  combopoints[i].tex:SetTexture(1, .3, .3, .75)
		elseif i < 4 then
		  combopoints[i].tex:SetTexture(1, 1, .3, .75)
		else
		  combopoints[i].tex:SetTexture(.3, 1, .3, .75)
		end
	  end
	  nameplate.combopoints = combopoints
	end
	
	for i=1,5 do
	  nameplate.combopoints[i]:SetWidth(combo_size)
	  nameplate.combopoints[i]:SetHeight(combo_size)
	  nameplate.combopoints[i]:SetPoint("TOPRIGHT", nameplate.health, "BOTTOMRIGHT", -(i-1)*(combo_size+default_border*3), -default_border*3)
	  CreateBackdrop(nameplate.combopoints[i], default_border)
	end
	
	--

	do -- castbar
	  local castbar = CreateFrame("StatusBar", nil, nameplate.health)
	  castbar:Hide()

	  castbar:SetScript("OnShow", function()
		if nameplatesDebuffsPosition == "BOTTOM" then
		  nameplate.debuffs[1]:SetPoint("TOPLEFT", this, "BOTTOMLEFT", 0, -4)
		end
	  end)

	  castbar:SetScript("OnHide", function()
		if nameplatesDebuffsPosition == "BOTTOM" then
		  nameplate.debuffs[1]:SetPoint("TOPLEFT", this:GetParent(), "BOTTOMLEFT", 0, -4)
		end
	  end)

	  castbar.text = castbar:CreateFontString("Status", "DIALOG", "GameFontNormal")
	  castbar.text:SetPoint("RIGHT", castbar, "LEFT", -4, 0)
	  castbar.text:SetNonSpaceWrap(false)
	  castbar.text:SetTextColor(1,1,1,.5)

	  castbar.spell = castbar:CreateFontString("Status", "DIALOG", "GameFontNormal")
	  castbar.spell:SetPoint("CENTER", castbar, "CENTER")
	  castbar.spell:SetNonSpaceWrap(false)
	  castbar.spell:SetTextColor(1,1,1,1)

	  castbar.icon = CreateFrame("Frame", nil, castbar)
	  castbar.icon.tex = castbar.icon:CreateTexture(nil, "BORDER")
	  castbar.icon.tex:SetAllPoints()

	  nameplate.castbar = castbar
	end
	
	nameplate.castbar:SetPoint("TOPLEFT", nameplate.health, "BOTTOMLEFT", 0, -default_border*3)
	nameplate.castbar:SetPoint("TOPRIGHT", nameplate.health, "BOTTOMRIGHT", 0, -default_border*3)
	nameplate.castbar:SetHeight(nameplatesHeightcast)
	nameplate.castbar:SetStatusBarTexture(nameplatesHealthtexture)
	nameplate.castbar:SetStatusBarColor(.9,.8,0,1)
	CreateBackdrop(nameplate.castbar, default_border)

	nameplate.castbar.text:SetFont("Interface\\AddOns\\ShaguPlates\\fonts\\francois.ttf", font_size, nameplatesNameFontstyle)
	nameplate.castbar.spell:SetFont("Interface\\AddOns\\ShaguPlates\\fonts\\francois.ttf", font_size, nameplatesNameFontstyle)
	nameplate.castbar.icon:SetPoint("BOTTOMLEFT", nameplate.castbar, "BOTTOMRIGHT", default_border*3, 0)
	--nameplate.castbar.icon:SetPoint("TOPLEFT", nameplate.health, "TOPRIGHT", default_border*3, 0)
	nameplate.castbar.icon:SetWidth(nameplatesHeightcast + default_border*3 + nameplatesHeighthealth)
	nameplate.castbar.icon:SetHeight(nameplatesHeightcast + default_border*3 + nameplatesHeighthealth)
	CreateBackdrop(nameplate.castbar.icon, default_border)
	
	

	parent.nameplate = nameplate
	HookScript(parent, "OnShow", nameplates.OnShow)
	HookScript(parent, "OnUpdate", nameplates.OnUpdate)
	
	if nameplate.guild:GetText() and string.len(nameplate.guild:GetText()) > 0 and nameplate.guild:IsShown() then
		nameplate:SetHeight(plate_height + font_size + 5)
	else
		nameplate:SetHeight(plate_height)
	end
	if guild and string.len(guild) > 0 then
	  nameplate.guild:SetPoint("BOTTOM", nameplate, "TOP", 0, 0)
	  nameplate.name:SetPoint("BOTTOM", nameplate.guild, "TOP", 0, 0)
	  nameplate.health:SetPoint("TOP", nameplate.guild, "BOTTOM", 0, healthoffset)
	else
	  nameplate.guild:SetPoint("BOTTOM", nameplate, "TOP", 0, 0)
	  nameplate.name:SetPoint("BOTTOM", nameplate, "TOP", 0, 0)
	  nameplate.health:SetPoint("TOP", nameplate.name, "BOTTOM", 0, healthoffset)
	end
	
	-- nameplates:OnDataChanged(nameplate)
	-- nameplates:OnUpdate(parent)
	nameplates.OnShow(parent)
	end
	
	-----------------------------------------------
	
	nameplates.OnShow = function(frame)
		local frame = frame or this
		local nameplate = frame.nameplate

		nameplates:OnDataChanged(nameplate)
		nameplates:OnUpdate(frame)
	end
	
	-----------------------------------------------

	nameplates.OnValueChanged = function(arg1)
		nameplates:OnDataChanged(this:GetParent().nameplate)
	end
	
	-----------------------------------------------
	
	local function updateGuildDispaly(nameplate, guild)
		if guild and string.len(guild) > 0 then
		  nameplate.guild:SetText("<"..guild..">")
		  if (not nameplate.isInMouseOver) then
			  if guild == GetGuildInfo("player") then
				nameplate.guild:SetTextColor(0, 0.9, 0, 1)
			  else
				nameplate.guild:SetTextColor(0.8, 0.8, 0.8, 1)
			  end
		  end
		  nameplate.guild:Show()
		  nameplate.guild:SetPoint("BOTTOM", nameplate, "TOP", 0, 0)
		  nameplate.name:SetPoint("BOTTOM", nameplate.guild, "TOP", 0, 0)
		  nameplate.health:SetPoint("TOP", nameplate.guild, "BOTTOM", 0, healthoffset)
		else
		  nameplate.guild:Hide()
		  nameplate.guild:SetPoint("BOTTOM", nameplate, "TOP", 0, 0)
		  nameplate.name:SetPoint("BOTTOM", nameplate, "TOP", 0, 0)
		  nameplate.health:SetPoint("TOP", nameplate.name, "BOTTOM", 0, healthoffset)
		end	
	end
	
	-----------------------------------------------

	nameplates.OnDataChanged = function(self, plate)
	local visible = plate:IsVisible()
	local hp = plate.original.healthbar:GetValue()
	local hpmin, hpmax = plate.original.healthbar:GetMinMaxValues()
	local name = plate.original.name:GetText()
	local level = plate.original.level:IsShown() and plate.original.level:GetObjectType() == "FontString" and tonumber(plate.original.level:GetText()) or "??"
	local levelDifficultyColor = GetDifficultyColor(255)
	if tonumber(level) then
		levelDifficultyColor = GetDifficultyColor(tonumber(level))
	end
	local isGrayLevel = levelDifficultyColor.r == 0.5 and levelDifficultyColor.g == 0.5 and levelDifficultyColor.b == 0.5
	local class, ulevel, elite, player, guild = GetUnitData(name, true)
	local target = plate.istarget
	local mouseover = UnitExists("mouseover")
	local unitstr = target and "target" or mouseover and "mouseover" or nil
	--local red, green, blue = plate.original.healthbar:GetStatusBarColor()
	--local unittype = GetUnitType(red, green, blue) or "ENEMY_NPC"
	local font_size = nameplatesUseUnitfonts and globalFontUnitSize or globalFontSize
	local rawborder, default_border = GetBorderSize("nameplates")
	local redOriginal, greenOriginal, blueOriginal = plate.original.healthbar:GetStatusBarColor()
	-- local r, g, b, a = redx, greenx, bluex, 1
	local race, raceEn
	
	-- ignore players with npc names if plate level is lower than player level
	-- if ulevel and ulevel > (level == "??" and -1 or level) then
		-- player = nil 
	-- end
	
	-- skip data updates on invisible frames
	if not visible then return end
	
	--print("unitstr = plate.original.name:GetText(): "..plate.original.name:GetText())
	--print("unitstr = plate.parent:GetName(1): "..plate.parent:GetName(1))

	-- use superwow unit guid as unitstr if possible
	if superwow_active then
		unitstr = plate.parent:GetName(1)
	end
	
	local originalPlateName = plate.original.name:GetText()
	local originalPlateLevel = level
	
	-- target event sometimes fires too quickly, where nameplate identifiers are not
	-- yet updated. So while being inside this event, we cannot trust the unitstr.
	if event == "PLAYER_TARGET_CHANGED" then unitstr = nil end
	
	
	-----------
	local isPlayer = (player ~= nil)
	
	elite = plate.original.levelicon:IsShown() and not isPlayer and "boss" or elite	
	
	
	--WAIT FOR SCAN--
	-- remove unitstr on unit name mismatch
	if unitstr and UnitName(unitstr) ~= name then 
		unitstr = nil
		
		--happens when unit dies
		--IMPORTANT
		plate.wait_for_scan = true
	end
	
	if (unitstr == nil) then
		plate.wait_for_scan = true
	end
	
	if isPlayer then
		if not class then
			plate.wait_for_scan = true
		end
		
		if (unitstr ~= nil) then
			race, raceEn = UnitRace(unitstr)
		end
		if (not raceEn) then
			plate.wait_for_scan = true
		end
	end
	--WAIT FOR SCAN END--
	
	------------

	-- always make sure to keep plate visible
	plate:Show()
	
	if target then
		if nameplatesTargetglow then
		  plate.glow:Show() 
		  plate.glow2:Show()
		else 
		  plate.glow:Hide()
		  plate.glow2:Hide()
		end
	else
		plate.glow:Hide()
		plate.glow2:Hide()
	end
	
	if target and nameplatesTargethighlight then
		plate.health.backdrop:SetBackdropBorderColor(plate.health.hlr, plate.health.hlg, plate.health.hlb, plate.health.hla)
		plate.power.backdrop:SetBackdropBorderColor(plate.health.hlr, plate.health.hlg, plate.health.hlb, plate.health.hla)
		plate.typeIcon.backdrop:SetBackdropBorderColor(plate.health.hlr, plate.health.hlg, plate.health.hlb, plate.health.hla)
	else
		plate.health.backdrop:SetBackdropBorderColor(er,eg,eb,ea)
		plate.power.backdrop:SetBackdropBorderColor(er,eg,eb,ea)
		plate.typeIcon.backdrop:SetBackdropBorderColor(er,eg,eb,ea)
	end
	
	--HEALTH
	
	-- use mobhealth values if addon is running
	if (MobHealth3 or MobHealthFrame) and target and name == UnitName('target') and MobHealth_GetTargetCurHP() then
	  hp = MobHealth_GetTargetCurHP() > 0 and MobHealth_GetTargetCurHP() or hp
	  hpmax = MobHealth_GetTargetMaxHP() > 0 and MobHealth_GetTargetMaxHP() or hpmax
	end
	
	plate.health:SetMinMaxValues(hpmin, hpmax)
	plate.health:SetValue(hp)

	if nameplatesShowhp then
	  local rhp, rhpmax, estimated
	  if hpmax > 100 or (round(hpmax/100*hp) ~= hp) then
		rhp, rhpmax = hp, hpmax
	  elseif ShaguPlates.libhealth and ShaguPlates.libhealth.enabled then
		rhp, rhpmax, estimated = ShaguPlates.libhealth:GetUnitHealthByName(name,level,tonumber(hp),tonumber(hpmax))
	  end

	  local setting = nameplatesHptextformat
	  local hasdata = ( estimated or hpmax > 100 or (round(hpmax/100*hp) ~= hp) )
	  
	  if setting == "cur" and hasdata then
		plate.health.text:SetText(string.format("%s", Abbreviate(rhp)))
	  else -- "percent" as fallback
		plate.health.text:SetText(string.format("%s%%", ceil(hp/hpmax*100)))
	  end
	  
	else
	  plate.health.text:SetText()
	end
	
	--HEALTH END
	
	--TOTEM

	-- hide frames according to the configuration
	local TotemIcon = TotemPlate(name)

	if TotemIcon then
	  -- create totem icon
		plate.totem.icon:SetTexture("Interface\\Icons\\" .. TotemIcon)
		
		plate.level:Hide()
		plate.name:Hide()
		plate.guild:Hide()
		plate.health:Hide()
		plate.power:Hide()
		plate.typeIcon:Hide()
		plate.classIcon:Hide()
		plate.rarityIcon:Hide()
		plate.rarityIconR:Hide()
		plate.combatIcon:Hide()
		plate.petHappiness:Hide()
		
		plate.glow:SetPoint("LEFT", plate.totem, "LEFT", -30, 0)
		plate.glow2:SetPoint("RIGHT", plate.totem, "RIGHT", 30, 0)
	  
		plate.totem:Show()
		
		return
	else
		plate.name:SetParent(plate.health)
		plate.glow:SetPoint("LEFT", plate.health, "LEFT", -30, 0)
		plate.glow2:SetPoint("RIGHT", plate.health, "RIGHT", 30, 0)
		
		plate.totem:Hide()
	end
	
	--TOTEM END
	
	--RARITY
	plate.rarityIcon.icon:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\frame_elite")
	plate.rarityIconR.icon:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\frame_elite")
	
	if elite == "elite" then
		plate.rarityIcon.icon:SetVertexColor(1, 1, 0, 1)
		plate.rarityIcon:Show()
		plate.rarityIconR.icon:SetVertexColor(1, 1, 0, 1)
		plate.rarityIconR:Show()
	elseif elite == "rareelite" then
		plate.rarityIcon.icon:SetVertexColor(1, 1, 1, 1)
		plate.rarityIcon:Show()
		plate.rarityIconR.icon:SetVertexColor(1, 1, 1, 1)
		plate.rarityIconR:Show()
	elseif elite == "rare" then
		plate.rarityIcon.icon:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\frame_rare")
		plate.rarityIconR.icon:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\frame_rare")
		plate.rarityIcon.icon:SetVertexColor(1, 1, 1, 1)
		plate.rarityIcon:Show()
		plate.rarityIconR.icon:SetVertexColor(1, 1, 1, 1)
		plate.rarityIconR:Show()
	elseif elite == "boss" then
		plate.rarityIcon.icon:SetVertexColor(0.5, 0, 0, 1)
		plate.rarityIcon:Show()
		plate.rarityIconR.icon:SetVertexColor(0.5, 0, 0, 1)
		plate.rarityIconR:Show()
	else
		plate.rarityIcon:Hide()
		plate.rarityIconR:Hide()
	end
	--RARITY END
	
	-- local playerCanAttackUnit = UnitCanAttack("player", unitstr)
	if plate.OnEnterScript == nil then
		local scrf = function()
			if not IsMouselooking() then			
				if (unitstr) then
					local playerCanAttackUnit = UnitCanAttack("player", unitstr)
					if playerCanAttackUnit then
						SetCursor("ATTACK_CURSOR")
					end
					
					GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
					GameTooltip:SetUnit(unitstr)
					GameTooltip:Show()
				end
				
				plate.selectionGlow:Show()
				
				plate.name:SetTextColor(1,1,0,1)
				plate.guild:SetTextColor(1,1,0,1)
				
				-- plate:SetFrameStrata("LOW")
				-- plate.target_strata = 1
				
				plate.isInMouseOver = true
				--nameplates:OnDataChanged(plate)
			end
		end
		plate:SetScript("OnEnter", scrf)
	end
	
	-- update combopoints
	for i=1, 5 do plate.combopoints[i]:Hide() end
	if target and nameplatesCpdisplay then
	  for i=1, GetComboPoints("target") do plate.combopoints[i]:Show() end
	end

	-- update debuffs
	for i=1,16 do
	  UpdateDebuffConfig(plate, i)
	end
	
	local index = 1

	if nameplatesShowdebuffs then
	  local verify = string.format("%s:%s", (name or ""), (level or ""))

	  -- update cached debuffs
	  if nameplatesGuessdebuffs and unitstr then
		plate:CacheDebuffs(unitstr, verify)
	  end

	  -- update all debuff icons
	  for i = 1, 16 do
		local effect, rank, texture, stacks, dtype, duration, timeleft

		if unitstr and nameplatesSelfdebuff == "1" then
		  effect, rank, texture, stacks, dtype, duration, timeleft = libdebuff:UnitOwnDebuff(unitstr, i)
		elseif unitstr then
		  effect, rank, texture, stacks, dtype, duration, timeleft = libdebuff:UnitDebuff(unitstr, i)
		elseif plate.verify == verify then
		  effect, rank, texture, stacks, dtype, duration, timeleft = plate:UnitDebuff(i)
		end

		if effect and texture then
		  if not plate.debuffs[index] then
			CreateDebuffIcon(plate, index)
			UpdateDebuffConfig(plate, index)
		  end

		  plate.debuffs[index]:Show()
		  plate.debuffs[index].icon:SetTexture(texture)
		  plate.debuffs[index].icon:SetTexCoord(.078, .92, .079, .937)

		  if stacks and stacks > 1 then
			plate.debuffs[index].stacks:SetText(stacks)
			plate.debuffs[index].stacks:Show()
		  else
			plate.debuffs[index].stacks:Hide()
		  end

		  if duration and timeleft and debuffdurations then
			plate.debuffs[index].cd:SetAlpha(0)
			plate.debuffs[index].cd:Show()
			CooldownFrame_SetTimer(plate.debuffs[index].cd, GetTime() + timeleft - duration, duration, 1)
		  end

		  index = index + 1
		end
	  end
	end

	-- hide remaining debuffs
	for i = index, 16 do
	  if plate.debuffs[i] then
		plate.debuffs[i]:Hide()
	  end
	end
	
	------------- NO SCAN DISPLAY
	if not TotemIcon then
		--display minimal info
		plate.name:SetText(originalPlateName.." [Awaiting scan...]")
		plate.name:SetPoint("BOTTOM", plate, "TOP", 0, 0)
		plate.name:Show()
		
		plate.guild:SetPoint("BOTTOM", plate, "TOP", 0, 0)
		plate.guild:Hide()
		
		plate.level:SetText(originalPlateLevel)
		plate.level:SetTextColor(levelDifficultyColor.r, levelDifficultyColor.g, levelDifficultyColor.b, 1)
		plate.level:ClearAllPoints()
		plate.level:SetPoint("LEFT", plate.health, "LEFT", 3, -8)
		plate.level:Show()
		
		plate.health:SetPoint("TOP", plate.name, "BOTTOM", 0, healthoffset)
		plate.health:SetWidth(nameplateWidth)
		plate.health:SetHeight(nameplatesHeighthealth)
		plate.health:SetStatusBarColor(redOriginal, greenOriginal, blueOriginal, 0.99999779462814)
		plate.health.text:ClearAllPoints()
		plate.health.text:SetPoint("RIGHT", plate.health, "RIGHT", -2, -8)
		plate.health:Show()		
		
		plate.power:SetWidth(nameplateWidth)
		plate.power:SetHeight(nameplatesHeightPower)
		plate.power:Hide()
		
		plate.typeIcon:SetHeight(nameplatesHeighthealth)
		plate.typeIcon:SetWidth(nameplatesHeighthealth)
		plate.typeIcon:Hide()
		
		plate.classIcon:Hide()

		plate.petHappiness:Hide()
		
		plate.combatIcon:SetPoint("LEFT", plate.name, "RIGHT", -0, -0)
		plate.combatIcon:Hide()
		
		plate.selectionGlow:SetWidth(nameplateWidth + 60)
		plate.selectionGlow:SetHeight(nameplatesHeighthealth + 60)
		
		plate.castbar:SetPoint("TOPLEFT", plate.health, "BOTTOMLEFT", 0, -default_border*3)
		plate.castbar:SetPoint("TOPRIGHT", plate.health, "BOTTOMRIGHT", 0, -default_border*3)		
		
		plate.rarityIcon:SetPoint("RIGHT", plate.health, "LEFT", 26, -1)
		
		updateGuildDispaly(plate, guild)
	end	
	-------------
	
	if plate.wait_for_scan then
		return
	end
	
	------------- SCANNED DISPLAY
	
	if not TotemIcon then
	
		local unitMaxPower = UnitManaMax(unitstr)
	
		if (not isPlayer) then
			scanTool:ClearLines()
			scanTool:SetUnit(unitstr)
			local scanTextLine2Text = scanTextLine2:GetText()
			--if not ownerText then return nil end
			--local owner, _ = string.split("'",ownerText)
			
			-- if (unitstr ~= nil) and UnitIsPossessed(unitstr) then
				-- guild = "PET"
			-- end
			
			if scanTextLine2Text and not string.find(scanTextLine2Text, "Level") then
				--local owner, _ = string.split("'",ownerText)
				guild = scanTextLine2Text
			end
		end
	
		plate.name:SetText(name)
		plate.typeIcon:Show()
		plate.classIcon:Show()
		
		plate.rarityIcon:SetPoint("RIGHT", plate.typeIcon, "LEFT", 26, -1)		
		
		if (not isPlayer) then
			plate.classIcon:Hide()
			local creatureType = UnitCreatureType(unitstr)
			if (creatureType ~= nil and creatureType ~= "" and creatureType ~= "Not specified") then
				plate.typeIcon.icon:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\creaturetypes\\"..string.upper(UnitCreatureType(unitstr))..".tga")
				
				if creatureType == "Critter" then
					plate.health:SetWidth(nameplateWidthCritter)
					plate.health:SetHeight(nameplatesHeighthealthCritter)
					plate.typeIcon:SetHeight(nameplatesHeighthealthCritter)
					plate.typeIcon:SetWidth(nameplatesHeighthealthCritter)
					plate.power:SetWidth(nameplateWidthCritter)
					
					plate.selectionGlow:SetWidth(nameplateWidthCritter + 60)
					plate.selectionGlow:SetHeight(nameplatesHeighthealthCritter + 60)
				else
					if isGrayLevel then
						plate.health:SetWidth(nameplateWidthGrayLevel)
						plate.power:SetWidth(nameplateWidthGrayLevel)
						
						plate.selectionGlow:SetWidth(nameplateWidthGrayLevel + 60)
					end
				end
			else
				plate.typeIcon.icon:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\creaturetypes\\UNKNOWN.tga")
				if isGrayLevel then
					plate.health:SetWidth(nameplateWidthGrayLevel)
					plate.power:SetWidth(nameplateWidthGrayLevel)
					
					plate.selectionGlow:SetWidth(nameplateWidthGrayLevel + 60)
				end
			end
			plate.typeIcon.icon:SetTexCoord(.078, .92, .079, .937)
			
			if UnitIsTapped(unitstr) and not UnitIsTappedByPlayer(unitstr) then
				plate.health:SetStatusBarColor(.5, .5, .5, .8)
			end
			
			local playerHasPetUI, playerPetIsHunterPet = HasPetUI()
			if (playerHasPetUI and playerPetIsHunterPet and guild and string.find(guild, UnitName("player").."'s Pet")) then
				petHappiness, petDamagePercentage, petLoyaltyRate = GetPetHappiness()
				--plate.name:SetText(name.." happiness level: "..petHappiness)
				
				if (petHappiness == 1) then
					plate.petHappiness.icon:SetTexCoord(0.375, 0.5625, 0, 0.359375)
					plate.combatIcon:SetPoint("LEFT", plate.petHappiness, "RIGHT", -0, -0)
					plate.petHappiness:Show()
				elseif (petHappiness == 2) then
					plate.petHappiness.icon:SetTexCoord(0.1875, 0.375, 0, 0.359375)
					plate.combatIcon:SetPoint("LEFT", plate.petHappiness, "RIGHT", -0, -0)
					plate.petHappiness:Show()
				elseif (petHappiness == 3) then
					-- plate.petHappiness.icon:SetTexCoord(0, 0.1875, 0, 0.359375)
					-- plate.combatIcon:SetPoint("LEFT", plate.petHappiness, "RIGHT", -0, -0)
					-- plate.petHappiness:Show()
					plate.petHappiness:Hide()
				end
			end
		end
		
		if (isPlayer) then
			if isGrayLevel then
				plate.health:SetWidth(nameplateWidthGrayLevel)
				plate.power:SetWidth(nameplateWidthGrayLevel)
			end
			--plate.classIcon.icon:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\classicons\\"..string.upper(class)..".tga")
			local classr, classl, classt, classb = getClassPos(string.upper(class))
			plate.classIcon.icon:SetTexCoord(classr, classl, classt, classb)
			--plate.classIcon.icon:SetTexCoord(.078, .92, .079, .937)
			plate.classIcon:Show()
			
			--print(name)
			--print(raceEn)
			--print(race)
			local gender_code = UnitSex(unitstr)
			--print(gender_code)
			if gender_code == 3 then
				plate.typeIcon.icon:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\races\\"..string.lower(raceEn).."_female.tga")
			else
				plate.typeIcon.icon:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\races\\"..string.lower(raceEn).."_male.tga")
			end
			
			if (not (UnitInRaid(unitstr) or UnitInParty(unitstr))) then 
				--r, g, b = UnitSelectionColor(unitstr)
				--r, g, b, a = UnitSelectionColor(unitstr)	
				
				--print(name)
				--print(UnitIsPVP(unitstr))
				--print(UnitCanAttack("player", unitstr))

				--r, g, b = 1, 1, 0
				
				--local playerCanAttackUnit = UnitCanAttack("player", unitstr)
				local unitCanAttackPlayer = UnitCanAttack(unitstr, "player")
				local playerFaction = UnitFactionGroup("player")
				local unitFaction = UnitFactionGroup(unitstr)
				local playerIsPvP = UnitIsPVP("player")
				local unitIsPvP = UnitIsPVP(unitstr)
				
				if (playerCanAttackUnit) and (not UnitCanAttackPlayer) then
					plate.health:SetStatusBarColor(1, 1, 0, 0.99999779462814)
				elseif (not playerCanAttackUnit) and (not unitCanAttackPlayer) then
					if (playerFaction == unitFaction) and (unitIsPvP) then
						plate.health:SetStatusBarColor(0, 0.99999779462814, 0, 0.99999779462814)
					else
						plate.health:SetStatusBarColor(0, 0, 0.99999779462814, 0.99999779462814)
					end
				elseif (not playerCanAttackUnit) and (unitCanAttackPlayer) then
					if ((playerFaction ~= unitFaction)) and (playerIsPvP) then
						plate.health:SetStatusBarColor(0, 0, 0.99999779462814, 0.99999779462814)
					end
				else
					--TODO UNHANDLED
					plate.health:SetStatusBarColor(1, 1, 1, 0.99999779462814)
				end
			else
				--unit is in your party or raid
				plate.health:SetStatusBarColor(0.4, 0.6, 1, 0.99999779462814)
			end
		end
		
		
		plate.glow:SetPoint("LEFT", plate.typeIcon, "LEFT", -30, 0)
		plate.glow2:SetPoint("RIGHT", plate.health, "RIGHT", 30, 0)
		
		
		
		
		if unitMaxPower > 0 then
			local unitPower = UnitMana(unitstr)
			plate.power.text:SetText(string.format("%s", Abbreviate(unitPower)))
			
			local unitPowerType = UnitPowerType(unitstr)
		
			if unitPowerType == 0 then
				plate.power:SetStatusBarColor(0, 0, 0.9, 0.99999779462814)
			elseif unitPowerType == 1 then
				plate.power:SetStatusBarColor(1, 0, 0, 0.99999779462814)
			elseif unitPowerType == 2 or unitPowerType == 3 then
				plate.power:SetStatusBarColor(1, 1, 0, 0.99999779462814)
			else
				plate.power:SetStatusBarColor(1, 1, 0, 0.99999779462814)
			end
			
			plate.power:SetMinMaxValues(0,  unitMaxPower)
			
			if unitPowerType == 1 and unitPower < 1 then
				plate.power:SetValue(unitMaxPower)
				plate.power:SetStatusBarColor(0.5, 0, 0, 0.99999779462814)
			else
				plate.power:SetValue(unitPower)
			end
			
			plate.health.text:ClearAllPoints()
			plate.health.text:SetPoint("RIGHT", plate.health, "RIGHT", -2, -4)
			plate.level:ClearAllPoints()
			plate.level:SetPoint("TOP", plate.typeIcon, "BOTTOM", 0, 0)
			plate.power:Show()
			plate.castbar:SetPoint("TOPLEFT", plate.power, "BOTTOMLEFT", 0, (-default_border*3)-4)
			plate.castbar:SetPoint("TOPRIGHT", plate.power, "BOTTOMRIGHT", 0, (-default_border*3)-4)
		else
			plate.health.text:ClearAllPoints()
			plate.health.text:SetPoint("RIGHT", plate.health, "RIGHT", -2, -8)
			plate.level:ClearAllPoints()
			plate.level:SetPoint("LEFT", plate.health, "LEFT", 3, -8)
			plate.power:Hide()
			plate.castbar:SetPoint("TOPLEFT", plate.health, "BOTTOMLEFT", 0, -default_border*3)
			plate.castbar:SetPoint("TOPRIGHT", plate.health, "BOTTOMRIGHT", 0, -default_border*3)
		end
		
		
		
		
		
		
		
		if (UnitAffectingCombat(unitstr)) then
			plate.combatIcon:Show()
		else
			plate.combatIcon:Hide()
		end
		
		if CheckInteractDistance(unitstr, 3) then
			plate.distanceToPlayer = 9.9
		elseif CheckInteractDistance(unitstr, 2) then
			plate.distanceToPlayer = 11.11
		elseif CheckInteractDistance(unitstr, 4) then
			plate.distanceToPlayer = 28
		else
			plate.distanceToPlayer = 999
		end
		
		if plate.distanceToPlayer < 10 then
			plate.desiredYOffset = -40
		elseif plate.distanceToPlayer < 30 then
			plate.desiredYOffset = -10
		else
			plate.desiredYOffset = 0
		end
		
		
		
		updateGuildDispaly(plate, guild)
		
		return
	end
	
	-------------

	-- print(initialized)
	-- print(parentcount)
	-- print(platecount)
	--print(table.getn(registry))

	-- init other variables
	-- local isGrayLevel = false
	-- local difficultyColor = {r=1, g=1, b=1}
	
	-- if ulevel ~= nil then
		-- if (ulevel > 0) then
			-- difficultyColor = GetDifficultyColor(ulevel)
			-- if (difficultyColor ~= nil) then
				-- isGrayLevel = difficultyColor.r == 0.5 and difficultyColor.g == 0.5 and difficultyColor.b == 0.5
			-- else
				-- difficultyColor = {r=1, g=1, b=1}
			-- end
		-- else
			-- difficultyColor = {r=0.5, g=0.5, b=0.5}
		-- end
	-- end
	
	-- if (unitstr ~= nil) then
		--print("ulevel1: "..ulevel)
		--print(ulevel)
		
		-- plate.unitstr = unitstr
		
		-- if CheckInteractDistance(unitstr, 3) then
			-- plate.distanceToPlayer = 9.9
		-- elseif CheckInteractDistance(unitstr, 2) then
			-- plate.distanceToPlayer = 11.11
		-- elseif CheckInteractDistance(unitstr, 4) then
			-- plate.distanceToPlayer = 28
		-- else
			-- plate.distanceToPlayer = 999
		-- end
		
		-- if plate.distanceToPlayer < 10 then
			-- plate.desiredYOffset = -40
		-- elseif plate.distanceToPlayer < 30 then
			-- plate.desiredYOffset = -20
		-- else
			-- plate.desiredYOffset = 0
		-- end
		
		-- if plate.currentYOffset == nil then
			-- plate.currentYOffset = plate.desiredYOffset
		-- end
		
		-- if plate.distanceToPlayer < 12 then
			-- plate:SetPoint("TOP", plate.parent, "TOP", 0, -50)
		-- elseif plate.distanceToPlayer < 30 then
			-- plate:SetPoint("TOP", plate.parent, "TOP", 0, -20)
		-- else
			-- plate:SetPoint("TOP", plate.parent, "TOP", 0, 0)
		-- end
		
	-- end

	--guild = GetGuildInfo(unitstr)

	--local TotemIcon = TotemPlate(name)
	--plate.classIcon:SetTexture("Interface\\Icons\\" .. "Image:Spell_Fire_SearingTotem")
	--plate.classIcon:Show()

	
	-- plate.level:SetTextColor(difficultyColor.r, difficultyColor.g, difficultyColor.b, 1)

	-- if (unitstr ~= nil) and not player and not TotemIcon then
		-- scanTool:ClearLines()
		-- scanTool:SetUnit(unitstr)
		-- local scanTextLine2Text = scanTextLine2:GetText()
		-- --if not ownerText then return nil end
		-- --local owner, _ = string.split("'",ownerText)
		
		-- -- if (unitstr ~= nil) and UnitIsPossessed(unitstr) then
			-- -- guild = "PET"
		-- -- end
		
		-- if scanTextLine2Text and not string.find(scanTextLine2Text, "Level") then
			-- --local owner, _ = string.split("'",ownerText)
			-- guild = scanTextLine2Text
		-- end
	-- end

	--guild = nil
	

	--local unittype = GetUnitType(red, green, blue) or "ENEMY_NPC"

	--if player and unittype == "ENEMY_NPC" then 
	-- if (unitstr == nil) then
		-- unitstr is null
	-- else
		
		-- if not player then
			-- plate.classIcon:Hide()
			-- local creatureType = UnitCreatureType(unitstr)
			-- if (creatureType ~= nil and creatureType ~= "" and creatureType ~= "Not specified") then
				-- plate.typeIcon.icon:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\creaturetypes\\"..string.upper(UnitCreatureType(unitstr))..".tga")
				
				-- if creatureType == "Critter" then
					-- plate.health:SetWidth(nameplateWidthCritter)
					-- plate.health:SetHeight(nameplatesHeighthealthCritter)
					-- plate.typeIcon:SetHeight(nameplatesHeighthealthCritter)
					-- plate.typeIcon:SetWidth(nameplatesHeighthealthCritter)
					-- plate.power:SetWidth(nameplateWidthCritter)
					
					-- plate.selectionGlow:SetWidth(nameplateWidthCritter + 60)
					-- plate.selectionGlow:SetHeight(nameplatesHeighthealthCritter + 60)
				-- else
					-- if isGrayLevel then
						-- plate.health:SetWidth(nameplateWidthGrayLevel)
						-- plate.power:SetWidth(nameplateWidthGrayLevel)
						
						-- plate.selectionGlow:SetWidth(nameplateWidthGrayLevel + 60)
					-- end
				-- end
			-- else
				-- plate.typeIcon.icon:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\creaturetypes\\UNKNOWN.tga")
				-- if isGrayLevel then
					-- plate.health:SetWidth(nameplateWidthGrayLevel)
					-- plate.power:SetWidth(nameplateWidthGrayLevel)
					
					-- plate.selectionGlow:SetWidth(nameplateWidthGrayLevel + 60)
				-- end
			-- end
			-- plate.typeIcon.icon:SetTexCoord(.078, .92, .079, .937)
			
			-- if UnitIsTapped(unitstr) and not UnitIsTappedByPlayer(unitstr) then
			  -- r, g, b, a = .5, .5, .5, .8
			-- end
		-- else
		-- if isPlayer then
			-- if isGrayLevel then
				-- plate.health:SetWidth(nameplateWidthGrayLevel)
				-- plate.power:SetWidth(nameplateWidthGrayLevel)
			-- end
			-- --plate.classIcon.icon:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\classicons\\"..string.upper(class)..".tga")
			-- local classr, classl, classt, classb = getClassPos(string.upper(class))
			-- plate.classIcon.icon:SetTexCoord(classr, classl, classt, classb)
			-- --plate.classIcon.icon:SetTexCoord(.078, .92, .079, .937)
			-- plate.classIcon:Show()
			
			-- --print(name)
			-- --print(raceEn)
			-- --print(race)
			-- local gender_code = UnitSex(unitstr)
			-- --print(gender_code)
			-- if gender_code == 3 then
				-- plate.typeIcon.icon:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\races\\"..string.lower(raceEn).."_female.tga")
			-- else
				-- plate.typeIcon.icon:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\races\\"..string.lower(raceEn).."_male.tga")
			-- end
			
			-- if (not (UnitInRaid(unitstr) or UnitInParty(unitstr))) then 
				-- --r, g, b = UnitSelectionColor(unitstr)
				-- --r, g, b, a = UnitSelectionColor(unitstr)	
				
				-- --print(name)
				-- --print(UnitIsPVP(unitstr))
				-- --print(UnitCanAttack("player", unitstr))

				-- --r, g, b = 1, 1, 0
				
				-- --local playerCanAttackUnit = UnitCanAttack("player", unitstr)
				-- local unitCanAttackPlayer = UnitCanAttack(unitstr, "player")
				-- local playerFaction = UnitFactionGroup("player")
				-- local unitFaction = UnitFactionGroup(unitstr)
				-- local playerIsPvP = UnitIsPVP("player")
				-- local unitIsPvP = UnitIsPVP(unitstr)
				
				-- if (playerCanAttackUnit) and (not UnitCanAttackPlayer) then
					-- r, g, b, a = 1, 1, 0, 0.99999779462814
				-- elseif (not playerCanAttackUnit) and (not unitCanAttackPlayer) then
					-- if (playerFaction == unitFaction) and (unitIsPvP) then
						-- r, g, b, a = 0, 0.99999779462814, 0, 0.99999779462814
					-- else
						-- r, g, b, a = 0, 0, 0.99999779462814, 0.99999779462814
					-- end
				-- elseif (not playerCanAttackUnit) and (unitCanAttackPlayer) then
					-- if ((playerFaction ~= unitFaction)) and (playerIsPvP) then
						-- r, g, b, a = 0, 0, 0.99999779462814, 0.99999779462814
					-- end
				-- end
			-- end
		-- end
	-- end
	
	-- local unitMaxPower = UnitManaMax(unitstr)

	-- plate.health:SetStatusBarColor(r, g, b, a)

	-- if r ~= plate.cache.r or g ~= plate.cache.g or b ~= plate.cache.b then
	 -- plate.health:SetStatusBarColor(r, g, b, a)
	 -- plate.cache.r, plate.cache.g, plate.cache.b = r, g, b
	-- end

	end

	-----------------------------------------------

	nameplates.OnUpdate = function(frame)
	local update
	local frame = frame or this
	local nameplate = frame.nameplate
	if nameplate == nil then
		return
	end
	local original = nameplate.original
	local name = original.name:GetText()
	local target = UnitExists("target") and frame:GetAlpha() == 1 or nil
	local mouseover = UnitExists("mouseover") and original.glow:IsShown() or nil
	local namefightcolor = nameplatesNamefightcolor

	-- trigger queued event update
	if nameplate.eventcache then
	  nameplates:OnDataChanged(nameplate)
	  nameplate.eventcache = nil
	end

	-- reset strata cache on target change
	if nameplate.istarget ~= target then
	  nameplate.target_strata = nil
	end

	-- keep target nameplate above others
	if (target or nameplate.isInMouseOver) and nameplate.target_strata ~= 1 then
	  nameplate:SetFrameStrata("LOW")
	  nameplate.target_strata = 1
	elseif (not target and not nameplate.isInMouseOver) and nameplate.target_strata ~= 0 then
	  nameplate:SetFrameStrata("BACKGROUND")
	  nameplate.target_strata = 0
	end

	-- cache target value
	nameplate.istarget = target

	-- set non-target plate alpha
	if target or not UnitExists("target") then
	  nameplate:SetAlpha(1)
	else
	  frame:SetAlpha(.95)
	  nameplate:SetAlpha(nameplatesNotargalpha)
	end

	-- queue update on visual target update
	if nameplate.cache.target ~= target then
	  nameplate.cache.target = target
	  update = true
	end

	-- queue update on visual mouseover update
	if nameplate.cache.mouseover ~= mouseover then
	  nameplate.cache.mouseover = mouseover
	  update = true
	end

	-- trigger update when unit was found
	if nameplate.wait_for_scan and GetUnitData(name, true) then
	  nameplate.wait_for_scan = nil
	  update = true
	end

	-- trigger update when name color changed
	local r, g, b = original.name:GetTextColor()
	if r + g + b ~= nameplate.cache.namecolor then
	  nameplate.cache.namecolor = r + g + b

	  if namefightcolor then
		if r > .9 and g < .2 and b < .2 then
		  nameplate.name:SetTextColor(1,0.4,0.2,1) -- infight
		else
		  nameplate.name:SetTextColor(r,g,b,1)
		end
	  else
		nameplate.name:SetTextColor(1,1,1,1)
	  end
	  update = true
	end

	local r, g, b = original.level:GetTextColor()
	r, g, b = r + .3, g + .3, b + .3
	if r + g + b ~= nameplate.cache.levelcolor then
	  nameplate.cache.levelcolor = r + g + b
	  -- nameplate.level:SetTextColor(r,g,b,1)
	  update = true
	end

	-- scan for debuff timeouts
	if nameplate.debuffcache then
	  for id, data in pairs(nameplate.debuffcache) do
		if ( not data.stop or data.stop < GetTime() ) and not data.empty then
		  data.empty = true
		  update = true
		end
	  end
	end

	-- use timer based updates
	if not nameplate.tick or nameplate.tick < GetTime() then
	  update = true
	end

	-- if (GetActivePlateCount() > 10) then
		-- if tonumber(nameplate.level:GetText()) > 30 then
			-- nameplate:Show()
		-- else
			-- nameplate:Hide()
		-- end
	-- else
		-- nameplate:Show()
	-- end

	-- run full updates if required
	if update then
	  nameplates:OnDataChanged(nameplate)
	  if (GetActivePlateCount() < 25) then
		nameplate.tick = GetTime() + .1
	  elseif  (GetActivePlateCount() < 40) then
		nameplate.tick = GetTime() + .5
	  else
		nameplate.tick = GetTime() + 1
	  end
	  --nameplate.tick = GetTime() + .5
	end

	-- castbar update
	if true then
	  local channel, cast, nameSubtext, text, texture, startTime, endTime, isTradeSkill

	  -- detect cast or channel bars
	  cast, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(target and "target" or name)
	  if not cast then channel, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(target and "target" or name) end

	  -- read enemy casts from SuperWoW if enabled
	  if superwow_active then
		cast, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(nameplate.parent:GetName(1))
		if not cast then channel, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(nameplate.parent:GetName(1)) end
	  end

	  if not cast and not channel then
		nameplate.castbar:Hide()
	  elseif cast or channel then
		local effect = cast or channel
		local duration = endTime - startTime
		local max = duration / 1000
		local cur = GetTime() - startTime / 1000

		-- invert castbar values while channeling
		if channel then cur = max + startTime/1000 - GetTime() end

		nameplate.castbar:SetMinMaxValues(0,  duration/1000)
		nameplate.castbar:SetValue(cur)
		nameplate.castbar.text:SetText(round(cur,1))
		nameplate.castbar.spell:SetText(effect)
		nameplate.castbar:Show()

		if texture then
		  nameplate.castbar.icon.tex:SetTexture(texture)
		  nameplate.castbar.icon.tex:SetTexCoord(.1,.9,.1,.9)
		end
	  end
	else
	  nameplate.castbar:Hide()
	end

	end

	-- set nameplate game settings
	nameplates.SetGameVariables = function()
		-- update visibility (hostile)
		if nameplatesShowhostile then
		  _G.NAMEPLATES_ON = true
		  ShowNameplates()
		else
		  _G.NAMEPLATES_ON = nil
		  HideNameplates()
		end

		-- update visibility (hostile)
		if nameplatesShowfriendly then
		  _G.FRIENDNAMEPLATES_ON = true
		  ShowFriendNameplates()
		else
		  _G.FRIENDNAMEPLATES_ON = nil
		  HideFriendNameplates()
		end
		
		
		-- _G.NAMEPLATES_ON = true
		-- ShowNameplates()
		
		-- _G.FRIENDNAMEPLATES_ON = true
		-- ShowFriendNameplates()
		
		
		_G.NAMEPLATES_ON = true
		ShowNameplates()
		
		_G.FRIENDNAMEPLATES_ON = nil
		HideFriendNameplates()
		
		
	end

	nameplates:SetGameVariables()

	-- nameplates.UpdateConfig = function()
	-- -- update nameplate visibility
	-- nameplates:SetGameVariables()

	-- -- apply all config changes
	-- for plate in pairs(registry) do
	  -- nameplates.OnConfigChange(plate)
	-- end
	-- end

	if ShaguPlates.client <= 112000 then

	local hookOnUpdate = nameplates.OnUpdate
	nameplates.OnUpdate = function(self)
	  -- initialize shortcut variables
	  local plate = this.nameplate or this

		-- if this:GetWidth() > 100 then
			-- this:SetWidth(100)
		-- end
		
		-- if this:GetHeight() > 10 then
			-- this:SetHeight(10)
		-- end
		
		--if (GetActivePlateCount() > 10) then
		-- if (GetActivePlateCount() > 1) then
			-- this:SetWidth(10)
			-- this:SetHeight(10)
		-- else
			-- if this:GetWidth() == 10 and this:GetHeight() == 10 then
				-- this:SetWidth(80)
				-- this:SetHeight(10)
			-- end
		-- end
		
		this:SetWidth(1)
		this:SetHeight(1)
		
		if plate.desiredYOffset and plate.currentYOffset then
			--print("GetCameraZoom(): "..GetCameraZoom())
		
		
			local offsetAnimationStep = 1.0
			
			if math.abs(plate.desiredYOffset-plate.currentYOffset) > 30 then
				plate.currentYOffset = plate.desiredYOffset
			end
		
			if (math.abs(plate.desiredYOffset-plate.currentYOffset) <= offsetAnimationStep) then
				plate.currentYOffset = plate.desiredYOffset
			else
				
			end
			
			if plate.desiredYOffset-plate.currentYOffset > 0 then
				plate.currentYOffset = plate.currentYOffset + offsetAnimationStep
			elseif plate.desiredYOffset-plate.currentYOffset < 0 then
				plate.currentYOffset = plate.currentYOffset - offsetAnimationStep
			end
			
			plate:SetPoint("TOP", plate.parent, "TOP", 0, plate.currentYOffset)
			
		end
		
		-- local zoom = GetCameraZoom()
		
		--plate:SetPoint("TOP", plate.parent, "TOP", 0, nameplateOffsetY)
		-- print("zoom")
		-- print("zoom: "..zoom)
		
		-- plate:SetPoint("TOP", plate.parent, "TOP", 0, -40)
		
		--this.nameplate:SetPoint("BOTTOM", this, "TOP", 0, 0)
		
		--this.nameplate:SetPoint("TOP", this, "TOP", 0, 0)
		
		--this.nameplate:SetPoint("TOP", self, "TOP", 0, 0)

	  hookOnUpdate(self)
	end

	end

	ShaguPlates.nameplates = nameplates
	end)