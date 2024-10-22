---------------
--NOTE - Please do not change this section
local _, tbl, secureCapsuleGet = ...;
if tbl then
	tbl.SecureCapsuleGet = secureCapsuleGet or SecureCapsuleGet;
	tbl.setfenv = tbl.SecureCapsuleGet("setfenv");
	tbl.getfenv = tbl.SecureCapsuleGet("getfenv");
	tbl.type = tbl.SecureCapsuleGet("type");
	tbl.unpack = tbl.SecureCapsuleGet("unpack");
	tbl.error = tbl.SecureCapsuleGet("error");
	tbl.pcall = tbl.SecureCapsuleGet("pcall");
	tbl.pairs = tbl.SecureCapsuleGet("pairs");
	tbl.setmetatable = tbl.SecureCapsuleGet("setmetatable");
	tbl.getmetatable = tbl.SecureCapsuleGet("getmetatable");
	tbl.pcallwithenv = tbl.SecureCapsuleGet("pcallwithenv");

	local function CleanFunction(f)
		local f = function(...)
			local function HandleCleanFunctionCallArgs(success, ...)
				if success then
					return ...;
				else
					tbl.error("Error in secure capsule function execution: "..(...));
				end
			end
			return HandleCleanFunctionCallArgs(tbl.pcallwithenv(f, tbl, ...));
		end
		setfenv(f, tbl);
		return f;
	end

	local function CleanTable(t, tableCopies)
		if not tableCopies then
			tableCopies = {};
		end

		local cleaned = {};
		tableCopies[t] = cleaned;

		for k, v in tbl.pairs(t) do
			if tbl.type(v) == "table" then
				if ( tableCopies[v] ) then
					cleaned[k] = tableCopies[v];
				else
					cleaned[k] = CleanTable(v, tableCopies);
				end
			elseif tbl.type(v) == "function" then
				cleaned[k] = CleanFunction(v);
			else
				cleaned[k] = v;
			end
		end
		return cleaned;
	end

	local function Import(name)
		local skipTableCopy = true;
		local val = tbl.SecureCapsuleGet(name, skipTableCopy);
		if tbl.type(val) == "function" then
			tbl[name] = CleanFunction(val);
		elseif tbl.type(val) == "table" then
			tbl[name] = CleanTable(val);
		else
			tbl[name] = val;
		end
	end

	Import("tinsert");
	Import("NineSliceLayouts");
	Import("NineSliceUtil");
	Import("NineSlicePanelMixin");
	Import("TOOLTIP_DEFAULT_BACKGROUND_COLOR");
	Import("GREEN_FONT_COLOR");
	Import("RED_FONT_COLOR");
	Import("DISABLED_FONT_COLOR");
	Import("SharedTooltip_SetBackdropStyle");
	Import("Round");


	if tbl.getmetatable(tbl) == nil then
		local secureEnvMetatable =
		{
			__metatable = false,
			__environment = false,
		}
		tbl.setmetatable(tbl, secureEnvMetatable);
	end
	setfenv(1, tbl);
end
----------------

local envTbl = tbl or _G;

local function SetupTextFont(fontString, fontObject)
	if fontString and fontObject then
		fontString:SetFontObject(fontObject);
	end
end

function SharedTooltip_OnLoad(self)
	NineSliceUtil.DisableSharpening(self.NineSlice);
	local style = nil;
	local isEmbedded = false;
	SharedTooltip_SetBackdropStyle(self, style, isEmbedded);
	self:SetClampRectInsets(0, 0, 15, 0);

	SetupTextFont(self.TextLeft1, self.textLeft1Font);
	SetupTextFont(self.TextRight1, self.textRight1Font);
	SetupTextFont(self.TextLeft2, self.textLeft2Font);
	SetupTextFont(self.TextRight2, self.textRight2Font);
end

function SharedTooltip_OnHide(self)
	self:SetPadding(0, 0, 0, 0);
end

local DEFAULT_TOOLTIP_OFFSET_X = -17;
local DEFAULT_TOOLTIP_OFFSET_Y = 70;

function SharedTooltip_SetDefaultAnchor(tooltip, parent)
	tooltip:SetOwner(parent or GetAppropriateTopLevelParent(), "ANCHOR_NONE");
	tooltip:SetPoint("BOTTOMRIGHT", GetAppropriateTopLevelParent(), "BOTTOMRIGHT", DEFAULT_TOOLTIP_OFFSET_X, DEFAULT_TOOLTIP_OFFSET_Y);
end

function SharedTooltip_ClearInsertedFrames(self)
	if self.insertedFrames then
		for i = 1, #self.insertedFrames do
			self.insertedFrames[i]:Hide();
		end
	end
	self.insertedFrames = nil;
end

function SharedTooltip_SetBackdropStyle(self, style, embedded)
	if embedded or self.IsEmbedded then
		self.NineSlice:Hide();
	else
		local layoutName = style and style.layoutType or "TooltipDefaultLayout";
		local layout = NineSliceUtil.GetLayout(layoutName);
		NineSliceUtil.ApplyLayout(self.NineSlice, layout);
		self.NineSlice:Show();
	end

	local bgR, bgG, bgB = TOOLTIP_DEFAULT_BACKGROUND_COLOR:GetRGB();
	self.NineSlice:SetCenterColor(bgR, bgG, bgB, 1);

	if self.TopOverlay then
		if style and style.overlayAtlasTop then
			self.TopOverlay:SetAtlas(style.overlayAtlasTop, true);
			self.TopOverlay:SetScale(style.overlayAtlasTopScale or 1.0);
			self.TopOverlay:SetPoint("CENTER", self, "TOP", style.overlayAtlasTopXOffset or 0, style.overlayAtlasTopYOffset or 0);
			self.TopOverlay:Show();
		else
			self.TopOverlay:Hide();
		end
	end

	if self.BottomOverlay then
		if style and style.overlayAtlasBottom then
			self.BottomOverlay:SetAtlas(style.overlayAtlasBottom, true);
			self.BottomOverlay:SetScale(style.overlayAtlasBottomScale or 1.0);
			self.BottomOverlay:SetPoint("CENTER", self, "BOTTOM", style.overlayAtlasBottomXOffset or 0, style.overlayAtlasBottomYOffset or 0);
			self.BottomOverlay:Show();
		else
			self.BottomOverlay:Hide();
		end
	end

	if style and style.padding then
		self:SetPadding(style.padding.right, style.padding.bottom, style.padding.left, style.padding.top);
	end
end

function GameTooltip_AddBlankLinesToTooltip(tooltip, numLines)
	if numLines ~= nil then
		for i = 1, numLines do
			tooltip:AddLine(" ");
		end
	end
end

function GameTooltip_AddBlankLineToTooltip(tooltip)
	GameTooltip_AddBlankLinesToTooltip(tooltip, 1);
end

function GameTooltip_SetTitle(tooltip, text, overrideColor, wrap)
	tooltip:ClearLines();
	GameTooltip_AddColoredLine(tooltip, text, overrideColor or HIGHLIGHT_FONT_COLOR, wrap)
end

function GameTooltip_ShowDisabledTooltip(tooltip, owner, text, tooltipAnchor)
	tooltip:SetOwner(owner, tooltipAnchor);

	local wrap = true;
	GameTooltip_SetTitle(tooltip, text, RED_FONT_COLOR, wrap);

	tooltip:Show();
end

function GameTooltip_AddNormalLine(tooltip, text, wrap, leftOffset)
	GameTooltip_AddColoredLine(tooltip, text, NORMAL_FONT_COLOR, wrap, leftOffset);
end

function GameTooltip_AddBodyLine(...)
	GameTooltip_AddNormalLine(...);
end

function GameTooltip_AddHighlightLine(tooltip, text, wrap, leftOffset)
	GameTooltip_AddColoredLine(tooltip, text, HIGHLIGHT_FONT_COLOR, wrap, leftOffset);
end

function GameTooltip_AddInstructionLine(tooltip, text, wrap, leftOffset)
	GameTooltip_AddColoredLine(tooltip, text, GREEN_FONT_COLOR, wrap, leftOffset);
end

function GameTooltip_AddErrorLine(tooltip, text, wrap, leftOffset)
	GameTooltip_AddColoredLine(tooltip, text, RED_FONT_COLOR, wrap, leftOffset);
end

function GameTooltip_AddDisabledLine(tooltip, text, wrap, leftOffset)
	GameTooltip_AddColoredLine(tooltip, text, DISABLED_FONT_COLOR, wrap, leftOffset);
end

function GameTooltip_AddColoredLine(tooltip, text, color, wrap, leftOffset)
	local r, g, b = color:GetRGB();
	if wrap == nil then
		wrap = true;
	end
	tooltip:AddLine(text, r, g, b, wrap, leftOffset);
end

function GameTooltip_AddColoredDoubleLine(tooltip, leftText, rightText, leftColor, rightColor, wrap, leftOffset)
	local leftR, leftG, leftB = leftColor:GetRGB();
	local rightR, rightG, rightB = rightColor:GetRGB();
	if wrap == nil then
		wrap = true;
	end
	tooltip:AddDoubleLine(leftText, rightText, leftR, leftG, leftB, rightR, rightG, rightB, wrap, leftOffset);
end

function GameTooltip_ShowSimpleTooltip(tooltip, text, overrideColor, wrap, owner, point, offsetX, offsetY)
	tooltip:SetOwner(owner, point, offsetX, offsetY);
	GameTooltip_SetTitle(tooltip, text, overrideColor, wrap);
	tooltip:Show();
end

function GameTooltip_InsertFrame(tooltipFrame, frame, verticalPadding)
	verticalPadding = verticalPadding or 0;

	local textSpacing = tooltipFrame:GetCustomLineSpacing() or 2;
	local textHeight = Round(envTbl[tooltipFrame:GetName().."TextLeft2"]:GetLineHeight());
	local neededHeight = Round(frame:GetHeight() + verticalPadding);
	local numLinesNeeded = math.ceil(neededHeight / (textHeight + textSpacing));
	local currentLine = tooltipFrame:NumLines();
	GameTooltip_AddBlankLinesToTooltip(tooltipFrame, numLinesNeeded);
	frame:SetParent(tooltipFrame);
	frame:ClearAllPoints();
	frame:SetPoint("TOPLEFT", tooltipFrame:GetName().."TextLeft"..(currentLine + 1), "TOPLEFT", 0, -verticalPadding);
	if not tooltipFrame.insertedFrames then
		tooltipFrame.insertedFrames = { };
	end
	local frameWidth = frame:GetWidth();
	if tooltipFrame:GetMinimumWidth() < frameWidth then
		tooltipFrame:SetMinimumWidth(frameWidth);
	end
	frame:Show();
	tinsert(tooltipFrame.insertedFrames, frame);
	-- return space taken so inserted frame can resize if needed
	return (numLinesNeeded * textHeight) + (numLinesNeeded - 1) * textSpacing;
end

function GameTooltip_AddNewbieTip(frame, normalText, r, g, b, newbieText, noNormalText)
	-- Nothing to do, this was added for Glue support.
end

TooltipBackdropTemplateMixin = {};

function TooltipBackdropTemplateMixin:TooltipBackdropOnLoad()
	NineSliceUtil.DisableSharpening(self.NineSlice);

	local bgColor = self.backdropColor or TOOLTIP_DEFAULT_BACKGROUND_COLOR;
	local bgAlpha = self.backdropColorAlpha or 1;
	local bgR, bgG, bgB = bgColor:GetRGB();
	self:SetBackdropColor(bgR, bgG, bgB, bgAlpha);

	if self.backdropBorderColor then
		local borderR, borderG, borderB = self.backdropBorderColor:GetRGB();
		local borderAlpha = self.backdropBorderColorAlpha or 1;
		self:SetBackdropBorderColor(borderR, borderG, borderB, borderAlpha);
	end
end

function TooltipBackdropTemplateMixin:SetBackdropColor(r, g, b, a)
	self.NineSlice:SetCenterColor(r, g, b, a);
end

function TooltipBackdropTemplateMixin:GetBackdropColor()
	return self.NineSlice:GetCenterColor();
end

function TooltipBackdropTemplateMixin:SetBackdropBorderColor(r, g, b, a)
	self.NineSlice:SetBorderColor(r, g, b, a);
end

function TooltipBackdropTemplateMixin:GetBackdropBorderColor()
	return self.NineSlice:GetBorderColor();
end

function TooltipBackdropTemplateMixin:SetBorderBlendMode(blendMode)
	self.NineSlice:SetBorderBlendMode(blendMode);
end

DisabledTooltipButtonMixin = {};

function DisabledTooltipButtonMixin:OnEnter()
	if not self:IsEnabled() then
		local disabledTooltip, disabledTooltipAnchor = self:GetDisabledTooltip();
		if disabledTooltip ~= nil then
			GameTooltip_ShowDisabledTooltip(GetAppropriateTooltip(), self, disabledTooltip, disabledTooltipAnchor);
		end
	end
end

function DisabledTooltipButtonMixin:OnLeave()
	local tooltip = GetAppropriateTooltip();
	tooltip:Hide();
end

function DisabledTooltipButtonMixin:SetDisabledTooltip(disabledTooltip, disabledTooltipAnchor)
	self.disabledTooltip = disabledTooltip;
	self.disabledTooltipAnchor = disabledTooltipAnchor;
end

function DisabledTooltipButtonMixin:GetDisabledTooltip()
	return self.disabledTooltip, self.disabledTooltipAnchor;
end

function DisabledTooltipButtonMixin:SetDisabledState(disabled, disabledTooltip, disabledTooltipAnchor)
	self:SetEnabled(not disabled);
	self:SetDisabledTooltip(disabledTooltip, disabledTooltipAnchor);
end