local lib = LibStub("LibActionButton-1.0")

local desaturationCurve = C_CurveUtil.CreateCurve()
desaturationCurve:SetType(Enum.LuaCurveType.Step)
desaturationCurve:AddPoint(0, 0)
desaturationCurve:AddPoint(0.001, 1)

local function forceCooldownVisuals(cooldownFrame)
  if not cooldownFrame then return end

  -- Force the swipe fill
  if cooldownFrame.SetDrawSwipe then
    cooldownFrame:SetDrawSwipe(true)
  end

  -- Force Blizzard cooldown numbers to be allowed (not hidden)
  if cooldownFrame.SetHideCountdownNumbers then
    cooldownFrame:SetHideCountdownNumbers(false)
  end
end

local function updateCooldown(button)
  local duration

  local actionType, actionID = GetActionInfo(button.action)
  if actionType == 'item' then
    local startTime, durationSecond = C_Item.GetItemCooldown(actionID)
    if durationSecond > 1.5 then -- GCD
      duration = C_DurationUtil.CreateDuration()
      duration:SetTimeFromStart(startTime, durationSecond)
    end
  elseif actionType then -- don't waste calculation time on empty actions
    -- handles actions, as well as items or spells in macros
    local cooldown = C_ActionBar.GetActionCooldown(button.action)
    if cooldown and not cooldown.isOnGCD then
      duration = C_ActionBar.GetActionCooldownDuration(button.action)
    end
  end

  if duration then
    button.icon:SetDesaturation(duration:EvaluateRemainingDuration(desaturationCurve))
  else
    button.icon:SetDesaturation(0)
  end
end

-- Hook all LibActionButton buttons
local function HookLibActionButton()
  for button in pairs(lib.buttonRegistry) do
    if button and button.UpdateAction then
      hooksecurefunc(button, 'UpdateAction', updateCooldown)
      button.cooldown:HookScript('OnCooldownDone', GenerateClosure(updateCooldown, button))
      EventRegistry:RegisterFrameEventAndCallback('SPELL_UPDATE_COOLDOWN', GenerateClosure(updateCooldown, button))

      forceCooldownVisuals(button.cooldown)
      forceCooldownVisuals(button.chargeCooldown)
        end
    end
end

-- Wait for the world to load & Bartender4 to create its buttons
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(self)
  C_Timer.After(3, HookLibActionButton)
  self:UnregisterEvent("PLAYER_ENTERING_WORLD")

  local count = _G["BT4Button172Count"]
  if count then
      count:SetAlpha(0)
  end
end)
