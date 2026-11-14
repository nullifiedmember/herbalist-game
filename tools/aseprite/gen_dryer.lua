-- Сушилка для трав (v19): комната для окна сушки (dry_room, ×4 в игре) и постройка во дворе (dryer).
local L = dofile("C:/Claude/herbalist_game/game/tools/aseprite/lib.lua")
local hex = L.hex
local floor, sin = math.floor, math.sin

local W, H = 330, 195
local POLES = {40, 82, 124}         -- y жердей (в пикселях арта)
local POST_L, POST_R = 34, 296

local function plank_wall(img)
  local tones = {hex"#6b4a30", hex"#77543a", hex"#5f412a", hex"#7f5b3f"}
  for x = 0, W - 1 do
    local k = floor(x / 22)
    local base = tones[(k * 7 % 4) + 1]
    for y = 0, H - 1 do
      local c = base
      local lx = x % 22
      if lx == 0 then c = hex"#3a2618" elseif lx == 1 then c = L.mul(base, 1.15) end
      -- волокна
      if L.hash(x, floor(y / 3), 11) > 0.93 then c = L.mul(c, 0.86) end
      if (y + k * 13) % 61 == 0 and lx > 3 and lx < 19 then c = L.mul(c, 0.8) end
      img:putPixel(x, y, c)
    end
    -- гвозди
    for _, ny in ipairs({12, 150}) do
      if x % 22 == 4 or x % 22 == 18 then L.put(img, x, ny + (k % 2) * 3, hex"#2a2420"); L.put(img, x, ny - 1 + (k % 2) * 3, hex"#8a8078") end
    end
  end
  -- поперечная доска-обвязка
  L.rect(img, 0, 158, W, 6, hex"#5a3c26"); L.rect(img, 0, 158, W, 1, hex"#8a6444")
end

local function window(img)
  local x0, y0, w, h = 120, 14, 64, 44
  L.rect(img, x0 - 4, y0 - 4, w + 8, h + 8, hex"#4a301c")
  L.rect(img, x0 - 3, y0 - 3, w + 6, 1, hex"#8a6444")
  for y = 0, h - 1 do
    local c = L.mix(hex"#a8d4ec", hex"#f4e8c8", y / h)
    L.rect(img, x0, y0 + y, w, 1, c)
  end
  -- лес за окном
  for i = 0, 7 do
    local tx = x0 + 4 + i * 8
    local th = 14 + (i * 5) % 9
    L.poly(img, {{tx, y0 + h - th}, {tx + 6, y0 + h}, {tx - 6, y0 + h}}, hex"#6a9a7a")
  end
  L.rect(img, x0 + w / 2 - 1, y0, 3, h, hex"#4a301c")
  L.rect(img, x0, y0 + h / 2 - 1, w, 3, hex"#4a301c")
  L.rect(img, x0 - 6, y0 + h + 4, w + 12, 4, hex"#5a3c26")
  L.rect(img, x0 - 6, y0 + h + 4, w + 12, 1, hex"#9a7454")
  -- луч света на стене
  for y = y0 + h + 8, 160 do
    local k = (y - y0 - h) / 110
    for x = floor(x0 + 10 + k * 40), floor(x0 + w + 10 + k * 70) do
      local c = img:getPixel(x, y)
      img:putPixel(x, y, L.mix(c, hex"#f8d8a0", 0.12))
    end
  end
end

local function floor_boards(img)
  for y = 164, H - 1 do
    for x = 0, W - 1 do
      local row = floor((y - 164) / 8)
      local c = (row % 2 == 0) and hex"#4a3020" or hex"#553826"
      if (y - 164) % 8 == 0 then c = hex"#2e1e14" end
      if (x + row * 37) % 70 == 0 then c = hex"#2e1e14" end
      if L.hash(x, y, 4) > 0.95 then c = L.mul(c, 1.12) end
      img:putPixel(x, y, c)
    end
  end
end

local function rack(img)
  local wood = {hex"#3e2716", hex"#6e4826", hex"#9a6a3a", hex"#c08a52"}
  -- столбы с ножками
  for _, px in ipairs({POST_L, POST_R}) do
    L.rect(img, px - 4, 26, 8, 146, wood[2])
    L.rect(img, px - 4, 26, 2, 146, wood[3])
    L.rect(img, px + 3, 26, 1, 146, wood[1])
    for y = 30, 168, 9 do L.put(img, px - 1, y, wood[1]); L.put(img, px, y + 4, wood[1]) end
    L.line(img, px - 18, 174, px - 3, 152, wood[2]); L.line(img, px - 17, 174, px - 2, 152, wood[3])
    L.line(img, px + 18, 174, px + 3, 152, wood[2]); L.line(img, px + 17, 174, px + 2, 152, wood[1])
    L.rect(img, px - 6, 22, 12, 5, wood[2]); L.rect(img, px - 6, 22, 12, 1, wood[4])
  end
  -- жерди и крючки
  for _, py in ipairs(POLES) do
    L.rect(img, POST_L - 2, py - 2, POST_R - POST_L + 4, 5, wood[2])
    L.rect(img, POST_L - 2, py - 2, POST_R - POST_L + 4, 1, wood[4])
    L.rect(img, POST_L - 2, py - 1, POST_R - POST_L + 4, 1, wood[3])
    L.rect(img, POST_L - 2, py + 2, POST_R - POST_L + 4, 1, wood[1])
    -- обмотка у столбов
    for _, px in ipairs({POST_L, POST_R}) do
      for k = -3, 3, 2 do L.put(img, px + k, py - 2, hex"#d8c890"); L.put(img, px + k + 1, py + 2, hex"#b8a870") end
    end
    for k = 0, 7 do
      local hx = 58 + k * 30
      L.put(img, hx, py + 3, hex"#6a6e7a"); L.put(img, hx, py + 4, hex"#9aa0b0"); L.put(img, hx, py + 5, hex"#6a6e7a")
      L.put(img, hx + 1, py + 6, hex"#9aa0b0"); L.put(img, hx + 2, py + 5, hex"#6a6e7a")
    end
  end
  -- мешки и корзинка у стены
  L.ellipse(img, 312, 166, 12, 10, hex"#b89a6a"); L.ellipse(img, 310, 164, 10, 8, hex"#ccb080")
  L.rect(img, 306, 154, 8, 3, hex"#8a6a40")
  L.ellipse(img, 14, 168, 10, 7, hex"#9a7a4a"); L.rect(img, 6, 160, 16, 2, hex"#6a4a2a")
end

local function room()
  local img = L.new(W, H)
  plank_wall(img)
  window(img)
  floor_boards(img)
  -- сухие пучки под потолком как декор
  for i = 0, 9 do
    local x = 10 + i * 33
    L.line(img, x, 0, x, 4, hex"#c8b890")
    local cols = {hex"#7a8a4a", hex"#9a7aaa", hex"#c0a050"}
    local c = cols[(i % 3) + 1]
    for k = 0, 5 do L.line(img, x - 2 + k % 3, 4, x - 3 + k, 12 + (k % 2) * 2, L.mul(c, 0.85 + 0.05 * k)) end
    L.rect(img, x - 2, 3, 5, 2, hex"#8a6a40")
  end
  rack(img)
  return img
end

-- постройка во дворе: каркас-«домик» с тремя жердями и пучками
local function yard()
  local img = L.new(66, 74)
  local wood = {hex"#3e2716", hex"#6e4826", hex"#9a6a3a", hex"#c08a52"}
  L.ellipse(img, 33, 70, 30, 3.5, hex("#000000", 70))
  for _, px in ipairs({8, 57}) do
    L.rect(img, px - 2, 10, 4, 60, wood[2]); L.rect(img, px - 2, 10, 1, 60, wood[3]); L.rect(img, px + 1, 10, 1, 60, wood[1])
    L.line(img, px - 7, 70, px - 1, 60, wood[2]); L.line(img, px + 7, 70, px + 1, 60, wood[2])
  end
  -- крыша-навес
  L.poly(img, {{2, 12}, {33, 0}, {64, 12}, {64, 16}, {33, 4}, {2, 16}}, wood[2], function(x, y) return (x + y) % 6 < 3 and hex"#8a5a32" or hex"#74482a" end)
  local cols = {{hex"#3e7a3a", hex"#5aa04a", hex"#86c066"}, {hex"#6a4a8a", hex"#8a6aaa", hex"#b896d0"}, {hex"#8a6a1a", hex"#c09a2a", hex"#e8c860"}, {hex"#6a7a3a", hex"#8a9a4a", hex"#b0b870"}}
  for r, py in ipairs({22, 38, 54}) do
    L.rect(img, 6, py, 54, 3, wood[2]); L.rect(img, 6, py, 54, 1, wood[4])
    for k = 0, 4 do
      local hx = 14 + k * 10
      local c = cols[((r + k) % 4) + 1]
      L.line(img, hx, py + 3, hx, py + 5, hex"#c8b890")
      for s = -2, 2 do
        L.line(img, hx + s * 0.5, py + 5, hx + s, py + 13 - math.abs(s), c[(s + 2) % 3 + 1])
      end
      L.put(img, hx - 1, py + 5, hex"#8a6a40"); L.put(img, hx, py + 5, hex"#8a6a40"); L.put(img, hx + 1, py + 5, hex"#8a6a40")
    end
  end
  L.outline(img, hex"#24180e")
  return img
end

L.save(room(), "dry_room", true)
L.save(yard(), "dryer", true)
