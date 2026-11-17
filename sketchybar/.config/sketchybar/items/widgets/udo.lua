local colors = require("colors")
local settings = require("settings")

local udo = sbar.add("item", "widgets.udo", {
  position = "right",
  icon = { drawing = false },
  label = {
    string = "",
    font = {
      style = settings.font.style_map["Bold"],
      size = 12.0,
    },
    color = colors.white,
  },
  update_freq = 5,
  updates = "on", -- keep polling while hidden, else a new session is never picked up
})

local function update()
  sbar.exec("udo status --short",
    function(result)
      local text = (result or ""):gsub("%s+$", "")
      if text == "" then
        udo:set({ drawing = false})
      else
        udo:set({ drawing = true, label = { string = text } })
      end
    end)
end

udo:subscribe({ "routine", "forced", "system_woke" }, function(_)
  update()
end)

sbar.add("bracket", "widgets.udo.bracket", { udo.name }, {
  background = { color = colors.bg1 }
})

sbar.add("item", "widgets.udo.padding", {
  position = "right",
  width = settings.group_paddings
})
