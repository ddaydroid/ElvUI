local E, L, V, P, G = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule('UnitFrames');

local _, ns = ...
local ElvUF = ns.oUF
assert(ElvUF, "ElvUI was unable to locate oUF.")

function UF:Construct_FocusFrame(frame)	
	frame.Health = self:Construct_HealthBar(frame, true, true, 'RIGHT')
	frame.Health.frequentUpdates = true;
	
	frame.Power = self:Construct_PowerBar(frame, true, true, 'LEFT', false)
	
	frame.Name = self:Construct_NameText(frame)
	
	frame.Buffs = self:Construct_Buffs(frame)
	
	frame.Castbar = self:Construct_Castbar(frame, 'LEFT')
	frame.Castbar.SafeZone = nil
	frame.Castbar.LatencyTexture:Hide()
	frame.RaidIcon = UF:Construct_RaidIcon(frame)	
	frame.Debuffs = self:Construct_Debuffs(frame)
	frame.HealPrediction = self:Construct_HealComm(frame)
	frame.AuraBars = self:Construct_AuraBarHeader(frame)

	frame:Point('BOTTOMRIGHT', ElvUF_Target, 'TOPRIGHT', 0, 220)
	E:CreateMover(frame, frame:GetName()..'Mover', 'Focus Frame')
end

function UF:Update_FocusFrame(frame, db)
	frame.db = db
	local BORDER = E:Scale(2)
	local SPACING = E:Scale(1)
	local UNIT_WIDTH = db.width
	local UNIT_HEIGHT = db.height
	
	local USE_POWERBAR = db.power.enable
	local USE_MINI_POWERBAR = db.power.width ~= 'fill' and USE_POWERBAR
	local USE_POWERBAR_OFFSET = db.power.offset ~= 0 and USE_POWERBAR
	local POWERBAR_OFFSET = db.power.offset
	local POWERBAR_HEIGHT = db.power.height
	local POWERBAR_WIDTH = db.width - (BORDER*2)
	
	local unit = self.unit
	
	frame.colors = ElvUF.colors
	frame:Size(UNIT_WIDTH, UNIT_HEIGHT)
	_G[frame:GetName()..'Mover']:Size(frame:GetSize())
	
	--Adjust some variables
	do
		if not USE_POWERBAR then
			POWERBAR_HEIGHT = 0
		end	
		
		if USE_MINI_POWERBAR then
			POWERBAR_WIDTH = POWERBAR_WIDTH / 2
		end
	end
	
	
	--Health
	do
		local health = frame.Health
		health.Smooth = self.db.smoothbars

		--Text
		if db.health.text then
			health.value:Show()
			
			local x, y = self:GetPositionOffset(db.health.position)
			health.value:ClearAllPoints()
			health.value:Point(db.health.position, health, db.health.position, x, y)
		else
			health.value:Hide()
		end
		
		--Colors
		health.colorSmooth = nil
		health.colorHealth = nil
		health.colorClass = nil
		health.colorReaction = nil
		if self.db['colors'].healthclass ~= true then
			if self.db['colors'].colorhealthbyvalue == true then
				health.colorSmooth = true
			else
				health.colorHealth = true
			end		
		else
			health.colorClass = true
			health.colorReaction = true
		end	
		
		--Position
		health:ClearAllPoints()
		health:Point("TOPRIGHT", frame, "TOPRIGHT", -BORDER, -BORDER)
		if USE_POWERBAR_OFFSET then			
			health:Point("TOPRIGHT", frame, "TOPRIGHT", -(BORDER+POWERBAR_OFFSET), -BORDER)
			health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", BORDER+POWERBAR_OFFSET, BORDER+POWERBAR_OFFSET)
		elseif USE_MINI_POWERBAR then
			health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", BORDER, BORDER + (POWERBAR_HEIGHT/2))
		else
			health:Point("BOTTOMLEFT", frame, "BOTTOMLEFT", BORDER, BORDER + POWERBAR_HEIGHT)
		end
	end
	
	--Name
	do
		local name = frame.Name
		if db.name.enable then
			name:Show()
			
			if not db.power.hideonnpc then
				local x, y = self:GetPositionOffset(db.name.position)
				name:ClearAllPoints()
				name:Point(db.name.position, frame.Health, db.name.position, x, y)				
			end
		else
			name:Hide()
		end
	end	
	
	--Power
	do
		local power = frame.Power
		if USE_POWERBAR then
			if not frame:IsElementEnabled('Power') then
				frame:EnableElement('Power')
				power:Show()
			end		
			
			power.Smooth = self.db.smoothbars
			
			--Text
			if db.power.text then
				power.value:Show()
				
				local x, y = self:GetPositionOffset(db.power.position)
				power.value:ClearAllPoints()
				power.value:Point(db.power.position, frame.Health, db.power.position, x, y)			
			else
				power.value:Hide()
			end
			
			--Colors
			power.colorClass = nil
			power.colorReaction = nil	
			power.colorPower = nil
			if self.db['colors'].powerclass then
				power.colorClass = true
				power.colorReaction = true
			else
				power.colorPower = true
			end		
			
			--Position
			power:ClearAllPoints()
			if USE_POWERBAR_OFFSET then
				power:Point("TOPLEFT", frame, "TOPLEFT", BORDER, -POWERBAR_OFFSET)
				power:Point("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -BORDER, BORDER)
				power:SetFrameStrata("LOW")
				power:SetFrameLevel(2)
			elseif USE_MINI_POWERBAR then
				power:Width(POWERBAR_WIDTH - BORDER*2)
				power:Height(POWERBAR_HEIGHT - BORDER*2)
				power:Point("LEFT", frame, "BOTTOMLEFT", (BORDER*2 + 4), BORDER + (POWERBAR_HEIGHT/2))
				power:SetFrameStrata("MEDIUM")
				power:SetFrameLevel(frame:GetFrameLevel() + 3)
			else
				power:Point("TOPLEFT", frame.Health.backdrop, "BOTTOMLEFT", BORDER, -(BORDER + SPACING))
				power:Point("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -BORDER, BORDER)
			end
		elseif frame:IsElementEnabled('Power') then
			frame:DisableElement('Power')
			power:Hide()	
			power.value:Hide()
		end
	end
	
	--Auras Disable/Enable
	--Only do if both debuffs and buffs aren't being used.
	do
		if db.debuffs.enable or db.buffs.enable then
			if not frame:IsElementEnabled('Aura') then
				frame:EnableElement('Aura')
			end	
		else
			if frame:IsElementEnabled('Aura') then
				frame:DisableElement('Aura')
			end			
		end
		
		frame.Buffs:ClearAllPoints()
		frame.Debuffs:ClearAllPoints()
	end
	
	--Buffs
	do
		local buffs = frame.Buffs
		local rows = db.buffs.numrows
		
		if USE_POWERBAR_OFFSET then
			buffs:SetWidth(UNIT_WIDTH - POWERBAR_OFFSET)
		else
			buffs:SetWidth(UNIT_WIDTH)
		end

		buffs.forceShow = frame.forceShowAuras
		buffs.num = db.buffs.perrow * rows
		buffs.size = db.buffs.sizeOverride ~= 0 and db.buffs.sizeOverride or ((((buffs:GetWidth() - (buffs.spacing*(buffs.num/rows - 1))) / buffs.num)) * rows)
		
		if db.buffs.sizeOverride and db.buffs.sizeOverride > 0 then
			buffs:SetWidth(db.buffs.perrow * db.buffs.sizeOverride)
		end
		
		local x, y = self:GetAuraOffset(db.buffs.initialAnchor, db.buffs.anchorPoint)
		local attachTo = self:GetAuraAnchorFrame(frame, db.buffs.attachTo)

		buffs:Point(db.buffs.initialAnchor, attachTo, db.buffs.anchorPoint, x, y)
		buffs:Height(buffs.size * rows)
		buffs.initialAnchor = db.buffs.initialAnchor
		buffs["growth-y"] = db.buffs['growth-y']
		buffs["growth-x"] = db.buffs['growth-x']

		if db.buffs.enable then			
			buffs:Show()
		else
			buffs:Hide()
		end
	end
	
	--Debuffs
	do
		local debuffs = frame.Debuffs
		local rows = db.debuffs.numrows
		
		if USE_POWERBAR_OFFSET then
			debuffs:SetWidth(UNIT_WIDTH - POWERBAR_OFFSET)
		else
			debuffs:SetWidth(UNIT_WIDTH)
		end

		debuffs.forceShow = frame.forceShowAuras
		debuffs.num = db.debuffs.perrow * rows
		debuffs.size = db.debuffs.sizeOverride ~= 0 and db.debuffs.sizeOverride or ((((debuffs:GetWidth() - (debuffs.spacing*(debuffs.num/rows - 1))) / debuffs.num)) * rows)
		
		if db.debuffs.sizeOverride and db.debuffs.sizeOverride > 0 then
			debuffs:SetWidth(db.debuffs.perrow * db.debuffs.sizeOverride)
		end
		
		local x, y = self:GetAuraOffset(db.debuffs.initialAnchor, db.debuffs.anchorPoint)
		local attachTo = self:GetAuraAnchorFrame(frame, db.debuffs.attachTo, db.buffs.attachTo == 'DEBUFFS' and db.debuffs.attachTo == 'BUFFS')

		debuffs:Point(db.debuffs.initialAnchor, attachTo, db.debuffs.anchorPoint, x, y)
		debuffs:Height(debuffs.size * rows)
		debuffs.initialAnchor = db.debuffs.initialAnchor
		debuffs["growth-y"] = db.debuffs['growth-y']
		debuffs["growth-x"] = db.debuffs['growth-x']

		if db.debuffs.enable then			
			debuffs:Show()
		else
			debuffs:Hide()
		end
	end	
	
	--Castbar
	do
		local castbar = frame.Castbar
		castbar:Width(db.castbar.width - 4)
		castbar:Height(db.castbar.height)

		--Icon
		if db.castbar.icon then
			castbar.Icon = castbar.ButtonIcon
			castbar.Icon.bg:Width(db.castbar.height + 4)
			castbar.Icon.bg:Height(db.castbar.height + 4)
			
			castbar:Width(db.castbar.width - castbar.Icon.bg:GetWidth() - 4)
			castbar.Icon.bg:Show()
		else
			castbar.ButtonIcon.bg:Hide()
			castbar.Icon = nil
		end
		
		if db.castbar.spark then
			castbar.Spark:Show()
		else
			castbar.Spark:Hide()
		end
		
		castbar:ClearAllPoints()
		castbar:Point("TOPRIGHT", frame, "BOTTOMRIGHT", -(BORDER + db.castbar.xOffset), (-(BORDER*2+BORDER) + db.castbar.yOffset))
		
		if db.castbar.enable and not frame:IsElementEnabled('Castbar') then
			frame:EnableElement('Castbar')
		elseif not db.castbar.enable and frame:IsElementEnabled('Castbar') then
			frame:DisableElement('Castbar')	
		end			
	end	
	
	--OverHealing
	do
		local healPrediction = frame.HealPrediction
		
		if db.healPrediction then
			if not frame:IsElementEnabled('HealPrediction') then
				frame:EnableElement('HealPrediction')
			end

			healPrediction.myBar:ClearAllPoints()
			healPrediction.myBar:Width(db.width - (BORDER*2))
			healPrediction.myBar:SetPoint('BOTTOMLEFT', frame.Health:GetStatusBarTexture(), 'BOTTOMRIGHT')
			healPrediction.myBar:SetPoint('TOPLEFT', frame.Health:GetStatusBarTexture(), 'TOPRIGHT')	

			healPrediction.otherBar:ClearAllPoints()
			healPrediction.otherBar:SetPoint('TOPLEFT', healPrediction.myBar:GetStatusBarTexture(), 'TOPRIGHT')	
			healPrediction.otherBar:SetPoint('BOTTOMLEFT', healPrediction.myBar:GetStatusBarTexture(), 'BOTTOMRIGHT')	
			healPrediction.otherBar:Width(db.width - (BORDER*2))	
		else
			if frame:IsElementEnabled('HealPrediction') then
				frame:DisableElement('HealPrediction')
			end		
		end
	end	
	
	--AuraBars
	do
		local auraBars = frame.AuraBars
		
		if db.aurabar.enable then
			if not frame:IsElementEnabled('AuraBars') then
				frame:EnableElement('AuraBars')
			end
			
			local healthColor = UF.db.colors.health
			local attachTo = frame
			
			if db.aurabar.attachTo == 'BUFFS' then
				attachTo = frame.Buffs
			elseif db.aurabar.attachTo == 'DEBUFFS' then
				attachTo = frame.Debuffs
			end
			
			local anchorPoint, anchorTo = 'BOTTOM', 'TOP'
			if db.aurabar.anchorPoint == 'BELOW' then
				anchorPoint, anchorTo = 'TOP', 'BOTTOM'
			end
			
			auraBars:ClearAllPoints()
			auraBars:SetPoint(anchorPoint..'LEFT', attachTo, anchorTo..'LEFT')
			auraBars:SetPoint(anchorPoint..'RIGHT', attachTo, anchorTo..'RIGHT')
			auraBars.buffColor = {healthColor.r, healthColor.b, healthColor.g}
			auraBars.down = db.aurabar.growthDirection == 'DOWN'
			auraBars:SetAnchors()
		else
			if frame:IsElementEnabled('AuraBars') then
				frame:DisableElement('AuraBars')
			end		
		end
	end
		
	frame:UpdateAllElements()
end

tinsert(UF['unitstoload'], 'focus')