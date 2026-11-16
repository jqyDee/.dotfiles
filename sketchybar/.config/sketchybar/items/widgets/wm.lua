local colors = require("colors")
local settings = require("settings")

-- TODO: remove when chosen which wm to go with
-- Shows which window manager is running: A (AeroSpace), Y (yabai), - (none)
local wm = sbar.add("item", "widgets.wm", {
  position = "right",
  icon = { drawing = false },
  label = {
    string = "-",
    font = {
      style = settings.font.style_map["Bold"],
      size = 12.0,
    },
    color = colors.white,
  },
  update_freq = 30,
})

local function update()
  sbar.exec("pgrep -x AeroSpace >/dev/null && echo A || (pgrep -x yabai >/dev/null && echo Y || echo -)",
    function(result)
      wm:set({ label = { string = tostring(result):gsub("%s+", "") } })
    end)
end

wm:subscribe({ "routine", "forced", "system_woke" }, function(_)
  update()
end)

sbar.add("bracket", "widgets.wm.bracket", { wm.name }, {
  background = { color = colors.bg1 }
})

sbar.add("item", "widgets.wm.padding", {
  position = "right",
  width = settings.group_paddings
})
