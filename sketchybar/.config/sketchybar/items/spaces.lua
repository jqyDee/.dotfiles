-- Pick the spaces representation matching the running window manager
local function is_running(process)
  local handle = io.popen("pgrep -x " .. process)
  local result = handle:read("*a")
  handle:close()
  return result ~= ""
end

if is_running("AeroSpace") then
  require("items.spaces_aerospace")
else
  require("items.spaces_yabai")
end
