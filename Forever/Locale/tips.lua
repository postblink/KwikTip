-- Forever-only tip overlays. UI translations are shared; Retail area aliases
-- and tip overrides are never copied into the Forever package.
-- Until Forever translations are authored, all locales use English tip prose.
local ADDON_NAME, KwikTip = ...

KwikTip.TIP_OVERRIDE_BY_ENCOUNTERID = {}
KwikTip.TIP_OVERRIDE_BY_NPCID = {}
KwikTip.AREA_OVERRIDE_BY_ID = {}
KwikTip.SUBZONE_LOCALE_BY_AREA_ID = {}
