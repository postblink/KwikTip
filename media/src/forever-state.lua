-- Synthetic Forever Normal instance; no real character state.
IsInInstance = function() return true, 'party' end
GetInstanceInfo = function() return 'The Hall of Thanes', 'party', 1, 'Normal', 5, 0, false, 3065 end
InCombatLockdown = function() return false end
local loaded, reason = C_AddOns.LoadAddOn('KwikTip_Forever')
assert(loaded, tostring(reason))
assert(SlashCmdList.KWIKTIP, 'missing slash handler')
SlashCmdList.KWIKTIP('boss 1')
assert(KwikTipHUD and KwikTipHUD:IsShown(), 'preview HUD not shown')
-- Presentation only: remove simulator player/action/party chrome, enlarge HUD.
for _, child in ipairs({UIParent:GetChildren()}) do
  if child ~= KwikTipHUD and child ~= GameTooltip then pcall(child.Hide, child) end
end
KwikTipHUD:ClearAllPoints()
KwikTipHUD:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
KwikTipHUD:SetScale(2)
