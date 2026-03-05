-- hello_startup.lua
-- Type: startup
-- Runs once when the app loads the Lua engine.
-- Returns a timestamped message (visible via "Run now" in the plugin detail screen).

function main()
  local ts = os.date("%Y-%m-%d %H:%M:%S")
  return "NagarikPatro Lua engine ready at " .. ts
end
