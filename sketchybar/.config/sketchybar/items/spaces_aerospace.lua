local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local aerospace = "/opt/homebrew/bin/aerospace"
local workspace_ids = { "1", "2", "3", "4", "5", "6" }

-- Triggered from aerospace.toml (exec-on-workspace-change / on-focus-changed)
sbar.add("event", "aerospace_workspace_change")
sbar.add("event", "aerospace_windows_change")

local spaces = {}
local brackets = {}
local paddings = {}

for _, ws in ipairs(workspace_ids) do
  local space = sbar.add("item", "space." .. ws, {
    icon = {
      string = ws,
      font = { family = settings.font.numbers },
      width = 19, -- fixed so rounding can't make spaces differ by 1px
      padding_left = 10,
      padding_right = 0,
      color = colors.white,
      highlight_color = colors.red,
    },
    label = {
      padding_right = 10,
      padding_left = 7,
      color = colors.grey,
      highlight_color = colors.white,
      font = "sketchybar-app-font:Regular:16.0",
      y_offset = -1,
      string = "-",
    },
    padding_right = 1,
    padding_left = 1,
    background = {
      color = colors.bg1,
      border_width = 1,
      height = 26,
      border_color = colors.black,
    },
  })

  spaces[ws] = space

  -- Single item bracket for space items to achieve double border on highlight
  brackets[ws] = sbar.add("bracket", { space.name }, {
    background = {
      color = colors.transparent,
      border_color = colors.bg2,
      height = 28,
      border_width = 2
    }
  })

  -- Padding space
  paddings[ws] = sbar.add("item", "space.padding." .. ws, {
    width = settings.group_paddings,
  })

  space:subscribe("mouse.clicked", function(_)
    sbar.exec(aerospace .. " workspace " .. ws)
  end)
end

local function update()
  local ws_cmd = aerospace .. " list-workspaces --all --format"
      .. " '%{workspace}|%{monitor-appkit-nsscreen-screens-id}|%{workspace-is-visible}'"
  local win_cmd = aerospace .. " list-windows --all --format '%{workspace}|%{app-name}'"

  sbar.exec(ws_cmd, function(ws_out)
    sbar.exec(win_cmd, function(win_out)
      local apps = {}
      for line in tostring(win_out):gmatch("[^\n]+") do
        local ws, app = line:match("^([^|]*)|(.*)$")
        if ws then
          apps[ws] = apps[ws] or {}
          apps[ws][app] = true
        end
      end

      for line in tostring(ws_out):gmatch("[^\n]+") do
        local ws, display, visible = line:match("^([^|]*)|([^|]*)|([^|]*)$")
        local space = spaces[ws]
        if space then
          local selected = visible == "true"
          local icon_line = ""
          for app, _ in pairs(apps[ws] or {}) do
            local lookup = app_icons[app]
            icon_line = icon_line .. ((lookup == nil) and app_icons["Default"] or lookup)
          end
          if icon_line == "" then
            icon_line = "-"
          end

          space:set({
            display = tonumber(display),
            icon = { highlight = selected },
            label = { string = icon_line, highlight = selected },
            background = { border_color = selected and colors.black or colors.bg2 },
          })
          brackets[ws]:set({
            display = tonumber(display),
            background = { border_color = selected and colors.red or colors.bg2 },
          })
          paddings[ws]:set({ display = tonumber(display) })
        end
      end
    end)
  end)
end

local observer = sbar.add("item", {
  drawing = false,
  updates = true,
})

observer:subscribe({
  "aerospace_workspace_change",
  "aerospace_windows_change",
  "front_app_switched",
  "display_change",
  "system_woke",
}, function(_)
  update()
end)

update()
