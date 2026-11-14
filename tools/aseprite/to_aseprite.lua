-- Сохранить готовые PNG из art/ как исходники Aseprite (tools/aseprite/src/*.aseprite), чтобы их можно было править.
-- Запуск: run.ps1 to_aseprite.lua <имена через запятую>
local OUT = "C:/Claude/herbalist_game/game/art/"
local SRC = "C:/Claude/herbalist_game/game/tools/aseprite/src/"
local names = app.params["only"] or ""
for name in string.gmatch(names, "([^,]+)") do
  local s = Sprite{fromFile = OUT .. name .. ".png"}
  if s then
    s:saveAs(SRC .. name .. ".aseprite")
    s:close()
  end
end
