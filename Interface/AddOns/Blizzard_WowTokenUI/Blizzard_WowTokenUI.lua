
BalanceEnabled = nil;
BalanceAmount = 0;

function SecureFormatShortDate(day, month, year)
	if (LOCALE_enGB) then
		return string.format(SHORTDATE_EU, day, month, year);
	else
		return string.format(SHORTDATE, day, month, year);
	end
end

function WowTokenRedemptionFrame_OnLoad(self)
	WowTokenRedemptionFrame_Update(self);
	C_WowTokenSecure.CancelRedeem();
	self:SetPoint("CENTER", UIParent, "CENTER", 0, 60);

	self.portrait:Hide();
	self.PortraitFrame:Hide();
	self.TopLeftCorner:Show();
	self.TopBorder:SetPoint("TOPLEFT", self.TopLeftCorner, "TOPRIGHT",  0, 0);
	self.LeftBorder:SetPoint("TOPLEFT", self.TopLeftCorner, "BOTTOMLEFT",  0, 0);

	self:RegisterEvent("TOKEN_REDEEM_FRAME_SHOW");
	self:RegisterEvent("TOKEN_REDEEM_GAME_TIME_UPDATED");
	self:RegisterEvent("TOKEN_REDEEM_BALANCE_UPDATED");
	self:RegisterEvent("TOKEN_STATUS_CHANGED");
end


function GetBalanceString()
	local info = SecureCurrencyUtil.GetActiveCurrencyInfo();
	return info.formatLong(C_WowTokenSecure.GetBalanceRedeemAmount(), 0);
end

function WowTokenRedemptionFrame_Update(self)
	BalanceEnabled = select(3, C_WowTokenPublic.GetCommerceSystemStatus());
	if (BalanceEnabled) then
		C_WowTokenSecure.SetBalanceAmountString(GetBalanceString());
		WowTokenRedemptionFrame_EnableBalance(self);
	else
		self:SetWidth(325);
		self.RightInset:Hide();
		self.RightDisplay:Hide();
	end
end

function WowTokenRedemptionFrame_EnableBalance(self)
	self:SetWidth(650);
	self.RightInset:Show();
	self.RightDisplay:Show();
	self.RightDisplay.Title:SetFontObject("GameFontNormalHuge");
	self.RightDisplay.Image:SetDesaturated(false);
	self.RightDisplay.Image:SetAlpha(1);
	self.RightDisplay.Description:SetFontObject("GameFontHighlight");
	self.RightDisplay.Description:SetText(string.format(TOKEN_REDEEM_BALANCE_DESCRIPTION, GetBalanceString()));
	self.RightDisplay.RedeemButton:Enable();
end

function WowTokenRedemptionFrame_DisableBalance(self)
	self:SetWidth(650);
	self.RightInset:Show();
	self.RightDisplay:Show();
	self.RightDisplay.Title:SetFontObject("GameFontDisableHuge");
	self.RightDisplay.Image:SetDesaturated(true);
	self.RightDisplay.Image:SetAlpha(.2);
	self.RightDisplay.Description:SetFontObject("GameFontDisable");
	self.RightDisplay.RedeemButton:Disable();
end

function GetTimeLeftMinuteString(minutes)
	local weeks = 7 * 24 * 60; -- 7 days, 24 hours, 60 minutes
	local days = 24 * 60; -- 24 hours, 60 minutes
	local hours = 60; -- 60 minutes

	local str = "";
	if (math.floor(minutes / weeks) > 0) then
		local wks = math.floor(minutes / weeks);

		minutes = minutes - (wks * weeks);
		str = str .. string.format(WEEKS_ABBR, wks);
	end

	if (math.floor(minutes / days) > 0) then
		local dys = math.floor(minutes / days);

		minutes = minutes - (dys * days);
		str = str .. " " .. string.format(DAYS_ABBR, dys);
	end

	if (math.floor(minutes / hours) > 0) then
		local hrs = math.floor(minutes / hours);

		minutes = minutes - (hrs * hours);
		str = str .. " " .. string.format(HOURS_ABBR, hrs);
	end

	if (minutes > 0) then
		str = str .. " " .. string.format(MINUTES_ABBR, minutes);
	end

	return str;
end

function GetGameTimeRedemptionString()
	local isSub, remaining = C_WowTokenSecure.GetGameTimeRedemptionInfo();

	local now = time();
	local oldTime = now + (remaining * 60); -- remaining is in minutes
	local newTime = oldTime + (30 * 24 * 60 * 60); -- 30 days * 24 hours * 60 minutes * 60 seconds

	local oldDate = date("*t", oldTime);
	local newDate = date("*t", newTime);

	local str = isSub and TOKEN_REDEEM_GAME_TIME_RENEWAL_FORMAT or TOKEN_REDEEM_GAME_TIME_EXPIRATION_FORMAT;

	return string.format(str, SecureFormatShortDate(oldDate.day, oldDate.month, oldDate.year), SecureFormatShortDate(newDate.day, newDate.month, newDate.year))
end

function GetBalanceRedemptionString()
	local currentBalance, addedBalance, canRedeem = C_WowTokenSecure.GetBalanceRedemptionInfo();

	local info = SecureCurrencyUtil.GetActiveCurrencyInfo();
	local balanceStr = info.formatLong(currentBalance, 0);
	local addedStr = info.formatLong(currentBalance + addedBalance, 0);

	return string.format(TOKEN_REDEEM_BALANCE_FORMAT, balanceStr, addedStr);
end

function WowTokenRedemptionFrame_OnShow(self)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPEN);
end

function WowTokenRedemptionFrame_OnHide(self)
	PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE);
end

function WowTokenRedemptionFrame_OnEvent(self, event, ...)
	if (event == "TOKEN_REDEEM_FRAME_SHOW") then
		self.LeftDisplay.RedeemButton:Disable();
		self.RightDisplay.RedeemButton:Disable();
		if (not C_WowTokenPublic.GetCommerceSystemStatus()) then
			self.LeftDisplay.Format:SetText(TOKEN_REDEMPTION_UNAVAILABLE);
			self.LeftDisplay.Spinner:Hide();
			if (BalanceEnabled) then
				self.RightDisplay.Format:SetText(TOKEN_REDEMPTION_UNAVAILABLE);
				self.RightDisplay.Spinner:Hide();
			end
		else
			C_WowTokenPublic.UpdateTokenCount();
			C_WowTokenSecure.GetRemainingGameTime();
			self.LeftDisplay.Format:Hide();
			self.LeftDisplay.Spinner:Show();
			if (BalanceEnabled) then
				C_WowTokenSecure.CanRedeemForBalance();
				self.RightDisplay.Format:Hide();
				self.RightDisplay.Spinner:Show();
				local info = SecureCurrencyUtil.GetActiveCurrencyInfo();
				self.RightDisplay.RedeemButton:SetText(string.format(TOKEN_REDEEM_BALANCE_BUTTON_LABEL, info.formatLong(C_WowTokenSecure.GetBalanceRedeemAmount(), 0)));
			end
		end
		self:Show();
	elseif (event == "TOKEN_REDEEM_GAME_TIME_UPDATED") then
		self.LeftDisplay.Format:SetText(GetGameTimeRedemptionString());
		self.LeftDisplay.Spinner:Hide();
		self.LeftDisplay.Format:Show();
		self.LeftDisplay.RedeemButton:Enable();
	elseif (event == "TOKEN_REDEEM_BALANCE_UPDATED") then
		local currentBalance, _, canRedeem, cannotRedeemReason = C_WowTokenSecure.GetBalanceRedemptionInfo();
		if (canRedeem) then
			WowTokenRedemptionFrame_EnableBalance(self);
			self.RightDisplay.Format:SetText(HTML_START_CENTERED..GetBalanceRedemptionString()..HTML_END);
			self.RightDisplay.Spinner:Hide();
			self.RightDisplay.Format:Show();
			self.RightDisplay.RedeemButton:Enable();
		else
			WowTokenRedemptionFrame_DisableBalance(self);
			-- Right now, near cap is the only reason the server will send us cannot accept here.
			-- Have a good (but not perfect) default in case reasons are added before we patch the UI with a better message.
			if (cannotRedeemReason == LE_TOKEN_RESULT_ERROR_BALANCE_NEAR_CAP) then
				local info = SecureCurrencyUtil.GetActiveCurrencyInfo();
				local amountStr = info.formatLong(currentBalance, 0);
				self.RightDisplay.Format:SetText(HTML_START_CENTERED..string.format(TOKEN_REDEEM_BALANCE_ERROR_CAP_FORMAT, amountStr)..HTML_END);
			else
				self.RightDisplay.Format:SetText(HTML_START_CENTERED..TOKEN_REDEMPTION_UNAVAILABLE..HTML_END);
			end
			self.RightDisplay.Spinner:Hide();
			self.RightDisplay.Format:Show();
		end
	elseif (event == "TOKEN_STATUS_CHANGED") then
		WowTokenRedemptionFrame_Update(self);
	end
end

function WowTokenRedemptionFrame_OnAttributeChanged(self, name, value)
	--Note - Setting attributes is how the external UI should communicate with this frame. That way, their taint won't be spread to this code.
	if ( name == "action" ) then
		if ( value == "EscapePressed" ) then
			local handled = false;
			if ( self:IsShown() ) then
				C_WowTokenSecure.CancelRedeem();
				self:Hide();
				handled = true;
			end
			self:SetAttribute("escaperesult", handled);
		end
	elseif ( name == "getbalancestring" ) then
		self:SetAttribute("balancestring", GetBalanceString());
	end
end

function WowTokenRedemptionRedeemButton_OnClick(self)
	WowTokenRedemptionFrame:Hide();
	local type = LE_TOKEN_REDEEM_TYPE_GAME_TIME;
	local dialogKey = "WOW_TOKEN_REDEEM_CONFIRMATION_SUB";
	if (self:GetID() == 2) then
		type = LE_TOKEN_REDEEM_TYPE_BALANCE;
		dialogKey = "WOW_TOKEN_REDEEM_CONFIRMATION_BALANCE";
	end
	C_WowTokenSecure.RedeemToken(type);
	WowTokenDialog_SetDialog(WowTokenDialog, dialogKey);
	PlaySound(SOUNDKIT.IG_MAINMENU_OPEN);
end

function WowTokenRedemptionFrameCloseButton_OnClick(self)
	C_WowTokenSecure.CancelRedeem();
	WowTokenRedemptionFrame:Hide();
	PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE);
end

------------------------------------------------------------------------------------------------------------------------------------------------------
-- This section is based on code from MoneyFrame.lua to keep it in the secure environment, if you change it there you should probably change it here as well.
------------------------------------------------------------------------------------------------------------------------------------------------------
local COPPER_PER_SILVER = 100;
local SILVER_PER_GOLD = 100;
local COPPER_PER_GOLD = COPPER_PER_SILVER * SILVER_PER_GOLD;

function GetSecureMoneyString(money, separateThousands)
	local goldString, silverString, copperString;
	local floor = math.floor;

	local gold = floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD));
	local silver = floor((money - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER);
	local copper = money % COPPER_PER_SILVER;

	if ( GetCVar("colorblindMode") == "1" ) then
		if (separateThousands) then
			goldString = SecureCurrencyUtil.FormatLargeNumber(gold)..GOLD_AMOUNT_SYMBOL;
		else
			goldString = gold..GOLD_AMOUNT_SYMBOL;
		end
		silverString = silver..SILVER_AMOUNT_SYMBOL;
		copperString = copper..COPPER_AMOUNT_SYMBOL;
	else
		if (separateThousands) then
			goldString = string.format(GOLD_AMOUNT_TEXTURE_STRING, SecureCurrencyUtil.FormatLargeNumber(gold), 0, 0);
		else
			goldString = string.format(GOLD_AMOUNT_TEXTURE, gold, 0, 0);
		end
		silverString = string.format(SILVER_AMOUNT_TEXTURE, silver, 0, 0);
		copperString = string.format(COPPER_AMOUNT_TEXTURE, copper, 0, 0);
	end

	local moneyString = "";
	local separator = "";
	if ( gold > 0 ) then
		moneyString = goldString;
		separator = " ";
	end
	if ( silver > 0 ) then
		moneyString = moneyString..separator..silverString;
		separator = " ";
	end
	if ( copper > 0 or moneyString == "" ) then
		moneyString = moneyString..separator..copperString;
	end

	return moneyString;
end

function GetTimeLeftString()
	local _, duration = C_WowTokenPublic.GetCurrentMarketPrice();
	local timeToSellString;
	if (duration == 1) then
		timeToSellString = AUCTION_TIME_LEFT1_DETAIL;
	elseif (duration == 2) then
		timeToSellString = AUCTION_TIME_LEFT2_DETAIL;
	elseif (duration == 3) then
		timeToSellString = AUCTION_TIME_LEFT3_DETAIL;
	else
		timeToSellString = AUCTION_TIME_LEFT4_DETAIL;
	end
	return timeToSellString;
end

-- These are file locals because we don't want to keep variables on the frame itself
local currentDialog, currentDialogName, currentTicker, remainingDialogTime;
local dialogs;
dialogs = {
	["WOW_TOKEN_REDEEM_CONFIRMATION_SUB"] = {
		completionIcon = false,
		cautionIcon = true,
		title = TOKEN_CONFIRMATION_TITLE,
		description = TOKEN_CONFIRM_GAME_TIME_DESCRIPTION,
		confirmationDesc = nil, -- Now set in reaction to an event
		additionalConfirmationDescription = function()
			if (C_WowTokenSecure.WillKickFromWorld()) then
				return "|n|n"..TOKEN_YOU_WILL_BE_LOGGED_OUT;
			else
				return "";
			end
		end,
		confDescIsFunction = true,
		button1 = ACCEPT,
		button1OnClick = function(self)
			self:Hide();
			if (C_WowTokenSecure.GetTokenCount() > 0) then
				C_WowTokenSecure.RedeemTokenConfirm(LE_TOKEN_REDEEM_TYPE_GAME_TIME);
				WowTokenDialog_SetDialog(WowTokenDialog, "WOW_TOKEN_REDEEM_IN_PROGRESS");
			else
				WowTokenOutbound.RedeemFailed(LE_TOKEN_RESULT_ERROR_OTHER);
			end
			PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE);
		end,
		button2 = CANCEL,
		button2OnClick = function(self) self:Hide(); C_WowTokenSecure.CancelRedeem(); PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE); end,
		validate = function() return C_WowTokenSecure.IsRedemptionStillValid(); end,
		onHide = function(self)
			dialogs["WOW_TOKEN_REDEEM_CONFIRMATION_SUB"].spinner = true;
			dialogs["WOW_TOKEN_REDEEM_CONFIRMATION_SUB"].confirmationDesc = nil;
		end,
		spinner = true,
		point = { "CENTER", UIParent, "CENTER", 0, 240 },
	};
	["WOW_TOKEN_REDEEM_COMPLETION_SUB"] = {
		completionIcon = true,
		cautionIcon = false,
		title = TOKEN_COMPLETE_TITLE,
		description = TOKEN_COMPLETE_GAME_TIME_DESCRIPTION,
		button1 = OKAY,
		button1OnClick = function(self) self:Hide(); PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE); end,
		point = { "CENTER", UIParent, "CENTER", 0, 240 },
	};
	["WOW_TOKEN_REDEEM_COMPLETION_KICK_SUB"] = {
		title = BLIZZARD_STORE_TRANSACTION_IN_PROGRESS,
		description = TOKEN_COMPLETE_GAME_TIME_DESCRIPTION,
		confirmationDesc = TOKEN_YOU_WILL_BE_LOGGED_OUT,
		button1 = OKAY,
		button1OnClick = function(self) self:Hide(); PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE); end,
		point = { "CENTER", UIParent, "CENTER", 0, 240 },
	};
	["WOW_TOKEN_REDEEM_CONFIRMATION_BALANCE"] = {
		completionIcon = false,
		cautionIcon = true,
		title = TOKEN_CONFIRMATION_TITLE,
		description = TOKEN_REDEEM_BALANCE_CONFIRMATION_DESCRIPTION,
		formatDesc = true,
		descFormatArgs = function() local info = SecureCurrencyUtil.GetActiveCurrencyInfo(); return { info.formatLong(C_WowTokenSecure.GetBalanceRedeemAmount(), 0) }; end,
		confirmationDesc = nil, -- Now set in reaction to an event
		confDescIsFunction = true,
		button1 = ACCEPT,
		validate = function() return C_WowTokenSecure.IsRedemptionStillValid(); end,
		button1OnClick = function(self)
			self:Hide();
			if (C_WowTokenSecure.GetTokenCount() > 0) then
				C_WowTokenSecure.RedeemTokenConfirm(LE_TOKEN_REDEEM_TYPE_BALANCE);
				WowTokenDialog_SetDialog(WowTokenDialog, "WOW_TOKEN_REDEEM_IN_PROGRESS");
			else
				WowTokenOutbound.RedeemFailed(LE_TOKEN_RESULT_ERROR_OTHER);
			end
			PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE);
		end,
		button2 = CANCEL,
		button2OnClick = function(self) self:Hide(); C_WowTokenSecure.CancelRedeem(); PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE); end,
		onHide = function(self)
			dialogs["WOW_TOKEN_REDEEM_CONFIRMATION_BALANCE"].spinner = true;
			dialogs["WOW_TOKEN_REDEEM_CONFIRMATION_BALANCE"].confirmationDesc = nil;
		end,
		spinner = true,
		point = { "CENTER", UIParent, "CENTER", 0, 240 },
	};
	["WOW_TOKEN_REDEEM_COMPLETION_BALANCE"] = {
		completionIcon = true,
		cautionIcon = false,
		title = TOKEN_COMPLETE_TITLE,
		description = TOKEN_COMPLETE_BALANCE_DESCRIPTION,
		formatDesc = true,
		descFormatArgs = function()
			return { GetBalanceString() };
		end,
		button1 = OKAY,
		button1OnClick = function(self) self:Hide(); PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE); end,
		point = { "CENTER", UIParent, "CENTER", 0, 240 },
	};
	["WOW_TOKEN_CREATE_AUCTION"] = {
		completionIcon = false,
		cautionIcon = true,
		title = TOKEN_CREATE_AUCTION_TITLE,
		confirmationDesc = TOKEN_CONFIRM_CREATE_AUCTION,
		confirmationDescLine2 = function() return string.format(TOKEN_CONFIRM_CREATE_AUCTION_LINE_2, GetTimeLeftString()) end,
		price = function() return GetSecureMoneyString(C_WowTokenPublic.GetGuaranteedPrice()); end,
		button1 = CREATE_AUCTION,
		button1OnClick = function(self) C_WowTokenSecure.ConfirmSellToken(true); self:Hide(); PlaySound(SOUNDKIT.LOOT_WINDOW_COIN_SOUND); end,
		button2 = CANCEL,
		button2OnClick = function(self) C_WowTokenSecure.ConfirmSellToken(false); self:Hide(); PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE); end,
		onShow = function(self)
			self:SetAttribute("isauctiondialogshown", true);
		end,
		onHide = function(self)
			self:SetAttribute("isauctiondialogshown", false);
			WowTokenOutbound.AuctionWowTokenUpdate();
		end,
		onCancelled = function(self)
			C_WowTokenSecure.ConfirmSellToken(false);
			PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE);
		end,
		timed = true,
		showCautionText = 20,
		point = { "TOPLEFT", UIParent, "TOPLEFT", 286, -157 },
	};
	["WOW_TOKEN_BUYOUT_AUCTION"] = {
		completionIcon = false,
		cautionIcon = true,
		title = TOKEN_BUYOUT_AUCTION_TITLE,
		confirmationDesc = TOKEN_BUYOUT_AUCTION_CONFIRMATION_DESCRIPTION;
		formatConfirmationDesc = true,
		confDescFormatArgs = function() return { GetSecureMoneyString(C_WowTokenPublic.GetGuaranteedPrice(), true); } end,
		onShow = function(self)
			self:SetAttribute("isauctiondialogshown", true);
			self.Title:SetFontObject("GameFontHighlight");
			self.ConfirmationDesc:SetFontObject("NumberFontNormal");
		end,
		onHide = function(self)
			self:SetAttribute("isauctiondialogshown", false);
			WowTokenOutbound.AuctionWowTokenUpdate();
			self.Title:SetFontObject("GameFontNormalLarge");
			self.ConfirmationDesc:SetFontObject("GameFontNormal");
		end,
		button1 = ACCEPT,
		button1OnClick = function(self) C_WowTokenSecure.ConfirmBuyToken(true); self:Hide(); PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE); end,
		button2 = CANCEL,
		button2OnClick = function(self) C_WowTokenSecure.ConfirmBuyToken(false); self:Hide(); PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE); end,
		timed = true,
		showCautionText = 20,
		spacing = 6,
		width = 420,
		baseHeight = 34,
		point = { "TOPLEFT", UIParent, "TOPLEFT", 286, -157 },
	};
	["WOW_TOKEN_REDEEM_IN_PROGRESS"] = {
		title = TOKEN_TRANSACTION_IN_PROGRESS,
		spinner = true,
		noButtons = true,
		point = { "CENTER", UIParent, "CENTER", 0, 240 },
	};
};

function WowTokenDialog_SetDialog(self, dialogName)
	local dialog = dialogs[dialogName];
	if (not dialog) then
		return;
	end

	if (dialog.validate) then
		if (not dialog.validate()) then
			return;
		end
	end

	if (self:IsShown() and currentDialog == dialog) then
		return;
	else
		self:Hide();
		currentDialog = dialog;
		currentDialogName = dialogName;
	end

	local min = math.min;
	local max = math.max;
	self:ClearAllPoints();
	self:SetPoint(unpack(dialog.point));

	local descArgs = nil;
	local confDescArgs = nil;

	if (dialog.descFormatArgs) then
		descArgs = dialog.descFormatArgs();
	end

	if (dialog.confDescFormatArgs) then
		confDescArgs = dialog.confDescFormatArgs();
	end

	local width = 256;
	local height = dialog.baseHeight or 54;
	local extraWidth = 80;
	local maxStringWidth = 354;
	local spacing = dialog.spacing or 16;

	if (dialog.completionIcon) then
		self.CompletionIcon:Show();
		self.Title:ClearAllPoints();
		self.Title:SetPoint("TOP", self.CompletionIcon, "BOTTOM", 0, -12);
		height = height + 83;
	else
		self.CompletionIcon:Hide();
		self.Title:ClearAllPoints();
		self.Title:SetPoint("TOP", 0, -16);
		height = height + 12;
	end

	self.Title:SetWidth(0);
	self.Title:SetText(dialog.title);
	self.Title:SetWidth(min(maxStringWidth, self.Title:GetWidth()));
	height = height + 12 + self.Title:GetHeight();
	width = max(width, self.Title:GetWidth());

	if (dialog.cautionIcon) then
		self.CautionIcon:Show();
		extraWidth = extraWidth + 36;
	else
		self.CautionIcon:Hide();
	end

	if (dialog.description) then
		self.Description:Show();
		self.ConfirmationDesc:ClearAllPoints();
		self.ConfirmationDesc:SetPoint("TOP", self.Description, "BOTTOM", 0, -spacing);
		self.Description:SetWidth(0);
		local description;
		if (dialog.formatDesc) then
			description = string.format(dialog.description, unpack(descArgs));
		else
			description = dialog.description;
		end
		if (dialog.additionalDescription) then
			description = description .. dialog.additionalDescription();
		end
		self.Description:SetText(description);
		self.Description:SetWidth(min(maxStringWidth, self.Description:GetWidth()));
		height = height + spacing + self.Description:GetHeight();
		width = max(width, self.Description:GetWidth());
	else
		self.Description:Hide();
	end

	if (dialog.confirmationDesc) then
		self.ConfirmationDesc:SetWidth(0);
		local confirmationDesc;
		if (dialog.confDescIsFunction) then
			confirmationDesc = dialog.confirmationDesc();
		elseif (dialog.formatConfirmationDesc) then
			confirmationDesc = string.format(dialog.confirmationDesc, unpack(confDescArgs));
		else
			confirmationDesc = dialog.confirmationDesc;
		end
		if (dialog.additionalConfirmationDescription) then
			confirmationDesc = confirmationDesc .. dialog.additionalConfirmationDescription();
		end
		self.ConfirmationDesc:SetText(confirmationDesc);
		self.ConfirmationDesc:SetWidth(min(maxStringWidth, self.ConfirmationDesc:GetWidth()));
		self.ConfirmationDesc:Show();
		height = height + spacing + self.ConfirmationDesc:GetHeight();
		width = max(width, self.ConfirmationDesc:GetWidth());
		local target = dialog.description and self.Description or self.Title;
		if (dialog.price) then
			self.PriceLabel:SetWidth(0);
			self.ConfirmationDescLine2:ClearAllPoints();
			self.ConfirmationDescLine2:SetPoint("TOP", target, "BOTTOM", 0, -20 - self.ConfirmationDesc:GetHeight());
			if (type(dialog.price) == "function") then
				self.PriceLabel:SetText(dialog.price());
			else
				self.PriceLabel:SetText(dialog.price);
			end
			self.PriceLabel:Show();
			local totalWidth = self.ConfirmationDesc:GetWidth() + self.PriceLabel:GetWidth() + 2;
			local confFinalWidth = self.ConfirmationDesc:GetWidth() + 1;
			local confDescOffset = confFinalWidth - (totalWidth / 2);
			self.ConfirmationDesc:ClearAllPoints();
			self.ConfirmationDesc:SetPoint("TOPRIGHT", target, "BOTTOM", confDescOffset, -spacing);
			self.ConfirmationDesc:SetJustifyH("RIGHT");
		else
			self.ConfirmationDesc:SetJustifyH("CENTER");
			self.ConfirmationDesc:ClearAllPoints();
			self.ConfirmationDesc:SetPoint("TOP", target, "BOTTOM", 0, -spacing);
			self.ConfirmationDescLine2:ClearAllPoints();
			self.ConfirmationDescLine2:SetPoint("TOP", self.ConfirmationDesc, "BOTTOM", 0, -12);
			self.PriceLabel:Hide();
		end
		if (dialog.confirmationDescLine2) then
			self.ConfirmationDescLine2:SetWidth(0);
			if (type(dialog.confirmationDescLine2) == "function") then
				self.ConfirmationDescLine2:SetText(dialog.confirmationDescLine2());
			else
				self.ConfirmationDescLine2:SetText(dialog.confirmationDescLine2);
			end
			self.ConfirmationDescLine2:SetWidth(min(maxStringWidth, self.ConfirmationDescLine2:GetWidth()));
			self.ConfirmationDescLine2:Show();
			height = height + self.ConfirmationDescLine2:GetHeight();
			width = max(width, self.ConfirmationDescLine2:GetWidth());
		else
			self.ConfirmationDescLine2:Hide();
		end
	else
		self.ConfirmationDesc:Hide();
		self.PriceLabel:Hide();
		self.ConfirmationDescLine2:Hide();
	end

	if (dialog.spinner) then
		self.Spinner:Show();
		self.Spinner:ClearAllPoints();
		if (dialog.noButtons) then
			self.Spinner:SetPoint("BOTTOM", 0, 16);
		else
			self.Spinner:SetPoint("BOTTOM", 0, 32);
			height = height + 16;
		end
		self.Button1:Disable();
	else
		self.Spinner:Hide();
		self.Button1:Enable();
	end

	if (dialog.noButtons) then
		self.Button1:Hide();
		self.Button2:Hide();
	else
		self.Button1:Show();
	end

	if (dialog.button2) then
		self.Button1:ClearAllPoints();
		self.Button2:ClearAllPoints();
		self.Button1:SetPoint("BOTTOMRIGHT", self, "BOTTOM", -8, 16);
		self.Button2:SetPoint("BOTTOMLEFT", self, "BOTTOM", 8, 16);
		self.Button2:Show();
		self.Button2:SetText(dialog.button2);
	else
		self.Button2:Hide();
		self.Button1:ClearAllPoints();
		self.Button1:SetPoint("BOTTOM", 0, 16);
	end

	self.Button1:SetText(dialog.button1);

	local finalWidth;
	if (dialog.width) then
		finalWidth = dialog.width;
	else
		finalWidth = width + extraWidth;
	end
	self:SetSize(finalWidth, height);

	self.CautionText:Hide();
	if (dialog.timed) then
		remainingDialogTime = C_WowTokenSecure.GetPriceLockDuration();
		if (not currentTicker) then
			currentTicker = C_Timer.NewTicker(1, function()
				if (remainingDialogTime == 0) then
					currentTicker:Cancel();
					if (dialog.onCancelled) then
						dialog.onCancelled(WowTokenDialog);
					end
					currentTicker = nil;
					self:Hide();
				elseif (remainingDialogTime <= (dialog.showCautionText and dialog.showCautionText or 20)) then
					self.CautionText:SetText(string.format(TOKEN_PRICE_LOCK_EXPIRE, remainingDialogTime));
					self.CautionText:Show();
					local newHeight = height + self.CautionText:GetHeight() + 20;
					if (dialog.button2) then
						self.Button1:ClearAllPoints();
						self.Button2:ClearAllPoints();
						self.Button1:SetPoint("BOTTOMRIGHT", self, "BOTTOM", -8, 46);
						self.Button2:SetPoint("BOTTOMLEFT", self, "BOTTOM", 8, 46);
					else
						self.Button1:ClearAllPoints();
						self.Button1:SetPoint("BOTTOM", 0, 46);
					end
					self:SetSize(finalWidth, newHeight);
				else
					self.CautionText:Hide();
					if (dialog.button2) then
						self.Button1:ClearAllPoints();
						self.Button2:ClearAllPoints();
						self.Button1:SetPoint("BOTTOMRIGHT", self, "BOTTOM", -8, 16);
						self.Button2:SetPoint("BOTTOMLEFT", self, "BOTTOM", 8, 16);
					else
						self.Button1:ClearAllPoints();
						self.Button1:SetPoint("BOTTOM", 0, 16);
					end
					self:SetSize(finalWidth, height);
				end
				remainingDialogTime = remainingDialogTime - 1;
			end);
		end
	else
		if (currentTicker) then
			currentTicker:Cancel();
			currentTicker = nil;
		end
	end

	self:Show();
end

function WowTokenDialog_HideDialog(dialogName)
	if (currentDialog and currentDialogName == dialogName) then
		if (dialogName == "WOW_TOKEN_CREATE_AUCTION") then
			C_WowTokenSecure.ConfirmSellToken(false);
		elseif (dialogName == "WOW_TOKEN_BUYOUT_AUCTION") then
			C_WowTokenSecure.ConfirmBuyToken(false);
		end
		WowTokenDialog:Hide();
	end
end

function WowTokenDialog_OnLoad(self)
	self:RegisterEvent("TOKEN_SELL_CONFIRM_REQUIRED");
	self:RegisterEvent("TOKEN_BUY_CONFIRM_REQUIRED");
	self:RegisterEvent("TOKEN_REDEEM_CONFIRM_REQUIRED");
	self:RegisterEvent("TOKEN_REDEEM_RESULT");
	self:RegisterEvent("AUCTION_HOUSE_CLOSED");
end

function WowTokenDialog_OnShow(self)
	if (currentDialog and currentDialog.onShow) then
		currentDialog.onShow(self);
	end
end

function WowTokenDialog_OnHide(self)
	if (currentDialog and currentDialog.onHide) then
		currentDialog.onHide(self);
	end

	if (self:IsShown()) then
		if (currentDialog.onCancelled) then
			currentDialog.onCancelled(self);
		end
		self:Hide();
	end

	currentDialog = nil;
end

function WowTokenDialog_OnEvent(self, event, ...)
	if (event == "TOKEN_SELL_CONFIRM_REQUIRED") then
		WowTokenDialog_SetDialog(self, "WOW_TOKEN_CREATE_AUCTION");
		WowTokenOutbound.AuctionWowTokenUpdate();
	elseif (event == "TOKEN_BUY_CONFIRM_REQUIRED") then
		WowTokenDialog_SetDialog(self, "WOW_TOKEN_BUYOUT_AUCTION");
		WowTokenOutbound.AuctionWowTokenUpdate();
	elseif (event == "TOKEN_REDEEM_CONFIRM_REQUIRED") then
		local choice = ...;
		local dialogKey, confirmationDescFunc;
		if (choice == LE_TOKEN_REDEEM_TYPE_GAME_TIME) then
			dialogKey = "WOW_TOKEN_REDEEM_CONFIRMATION_SUB";
			confirmationDescFunc = GetGameTimeRedemptionString;
		elseif (choice == LE_TOKEN_REDEEM_TYPE_BALANCE) then
			dialogKey = "WOW_TOKEN_REDEEM_CONFIRMATION_BALANCE";
			confirmationDescFunc = GetBalanceRedemptionString;
		end

		if (not dialogKey or currentDialogName ~= dialogKey) then
			return;
		end
		self:Hide();
		dialogs[dialogKey].spinner = false;
		dialogs[dialogKey].confirmationDesc = confirmationDescFunc;
		WowTokenDialog_SetDialog(self, dialogKey);
	elseif (event == "TOKEN_REDEEM_RESULT") then
		local result, choice = ...;
		if (result == LE_TOKEN_RESULT_SUCCESS) then
			local dialogKey;
			if (choice == LE_TOKEN_REDEEM_TYPE_GAME_TIME) then
				if (C_WowTokenSecure.WillKickFromWorld()) then
					dialogKey = "WOW_TOKEN_REDEEM_COMPLETION_KICK_SUB";
				else
					dialogKey = "WOW_TOKEN_REDEEM_COMPLETION_SUB";
				end
			elseif (choice == LE_TOKEN_REDEEM_TYPE_BALANCE) then
				dialogKey = "WOW_TOKEN_REDEEM_COMPLETION_BALANCE";
			end
			if (not dialogKey) then
				return;
			end
			WowTokenDialog_SetDialog(self, dialogKey);
		else
			WowTokenOutbound.RedeemFailed(result);
			C_WowTokenSecure.CancelRedeem();
			self:Hide();
		end
	elseif (event == "AUCTION_HOUSE_CLOSED") then
		WowTokenDialog_HideDialog("WOW_TOKEN_CREATE_AUCTION");
		WowTokenDialog_HideDialog("WOW_TOKEN_BUYOUT_AUCTION");
	end
end

function WowTokenDialogButton_OnClick(self)
	local id = self:GetID();
	local onClick;
	if (id == 1) then
		onClick = "button1OnClick";
	else
		onClick = "button2OnClick";
	end

	if (currentDialog and currentDialog[onClick]) then
		currentDialog[onClick](WowTokenDialog);
	else
		if (id == 2 and currentDialog.onCancelled) then
			currentDialog.onCancelled(WowTokenDialog);
		end
		WowTokenDialog:Hide();
	end

	if (currentTicker) then
		currentTicker:Cancel();
		currentTicker = nil;
	end
end

function WoWTokenButton_OnShow(self)
	if ( self:IsEnabled() ) then
		-- we need to reset our textures just in case we were hidden before a mouse up fired
		self.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up");
		self.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up");
		self.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up");
	end
	local textWidth = self.Text:GetWidth();
	local width = self:GetWidth();
	if ( (width - 40) < textWidth ) then
		self:SetWidth(textWidth + 40);
	end
end
