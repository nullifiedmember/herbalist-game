-- Тюрьмы: здание для каждого города и камера для внутренней комнаты. Рисует Aseprite (v18).
local L = dofile("C:/Claude/herbalist_game/game/tools/aseprite/lib.lua")
local hex = L.hex
local floor, sqrt, sin, cos, max, min, abs = math.floor, math.sqrt, math.sin, math.cos, math.max, math.min, math.abs

local W, H = 200, 176
local GY = H - 8   -- линия земли

local function dark(c, k) return L.mul(c, k or 0.7) end

local function brick_fn(a, b, mortar, seed)
  return function(x, y)
    local row = floor(y / 5)
    local col = (x + (row % 2) * 6) % 12
    if y % 5 == 0 or col == 0 then return mortar end
    local c = L.hash(floor((x + (row % 2) * 6) / 12), row, seed or 1) < 0.5 and a or b
    if y % 5 == 1 and col > 0 then c = L.mul(c, 1.12) end
    return c
  end
end

local function plank_fn(a, b, gap, seed, w)
  w = w or 5
  return function(x, y)
    local k = floor(x / w)
    if x % w == 0 then return gap end
    local c = (k % 2 == 0) and a or b
    if L.hash(k, floor(y / 7), seed or 2) < 0.15 then c = L.mul(c, 0.85) end
    if x % w == 1 then c = L.mul(c, 1.12) end
    return c
  end
end

local function tile_fn(a, b, edge)
  return function(x, y)
    local row = floor(y / 5)
    local cx = (x + (row % 2) * 4) % 8
    local ry = y % 5
    if ry == 4 then return edge end
    if cx == 0 then return L.mul(a, 0.8) end
    return (ry <= 1) and b or a
  end
end

local function box(img, x, y, w, h, fn)
  for yy = y, y + h - 1 do for xx = x, x + w - 1 do L.put(img, xx, yy, fn(xx, yy)) end end
end

local function barred(img, x, y, w, h, bar, bg, step)
  L.rect(img, x, y, w, h, bg)
  for xx = x + 1, x + w - 2, step or 3 do L.rect(img, xx, y, 1, h, bar) end
  L.rect(img, x, y + floor(h / 2), w, 1, dark(bar, 0.8))
  L.rect(img, x - 1, y - 1, w + 2, 1, dark(bar, 0.6))
  L.rect(img, x - 1, y + h, w + 2, 1, dark(bar, 0.6))
end

local function arch_door(img, cx, by, w, h, bg, frame, fn)
  local x0 = cx - floor(w / 2)
  for yy = by - h, by - 1 do
    for xx = x0, x0 + w - 1 do
      local top = by - h + w / 2
      local ok = true
      if yy < top then
        local dx, dy = xx + 0.5 - cx, yy + 0.5 - top
        ok = dx * dx + dy * dy <= (w / 2) ^ 2
      end
      if ok then L.put(img, xx, yy, fn and fn(xx, yy) or bg) end
    end
  end
end

local function battlements(img, x, y, w, fn, tw, th)
  tw, th = tw or 8, th or 7
  for xx = x, x + w - 1, tw * 2 do
    for yy = y - th, y - 1 do for dx = 0, tw - 1 do
      if xx + dx < x + w then L.put(img, xx + dx, yy, fn(xx + dx, yy)) end
    end end
  end
end

local function gable(img, xl, xr, ybase, apx, apy, fn)
  L.poly(img, {{xl, ybase}, {apx, apy}, {xr, ybase}}, hex"#000000", fn)
end

local function glow(img, cx, cy, r, col, amax)
  for y = floor(cy - r), math.ceil(cy + r) do for x = floor(cx - r), math.ceil(cx + r) do
    local d = sqrt((x + 0.5 - cx) ^ 2 + (y + 0.5 - cy) ^ 2)
    if d <= r and not L.opaque(img, x, y) then L.put(img, x, y, L.withA(col, floor((amax or 70) * (1 - d / r) ^ 1.5))) end
  end end
end

-- светлая кромка слева-сверху и тёмная справа-снизу на готовой постройке (объём)
local function bevel(img, hi_k, lo_k)
  local src = L.new(img.width, img.height)
  src:drawImage(img)
  for y = 0, img.height - 1 do for x = 0, img.width - 1 do
    if L.opaque(src, x, y) and L.alpha(src:getPixel(x, y)) == 255 then
      local c = src:getPixel(x, y)
      if not L.opaque(src, x - 1, y) or not L.opaque(src, x, y - 1) then img:putPixel(x, y, L.mul(c, hi_k or 1.18)) end
      if not L.opaque(src, x + 1, y) or not L.opaque(src, x, y + 1) then img:putPixel(x, y, L.mul(c, lo_k or 0.78)) end
    end
  end end
end

local function ground_shadow(img, cx, w)
  L.ellipse(img, cx, GY + 3, w / 2 + 6, 4, hex("#000000", 70), true)
end

-- ============================================================ здания
local B = {}

function B.knights()
  local img = L.new(W, H)
  local stone = brick_fn(hex"#8d93a3", hex"#7c8394", hex"#5d6374", 3)
  local stone2 = brick_fn(hex"#767d8e", hex"#69707f", hex"#4d5362", 4)
  -- башни слева и справа
  for _, tx in ipairs({22, 142}) do
    box(img, tx, GY - 118, 36, 118, stone2)
    battlements(img, tx - 2, GY - 118, 40, stone, 8, 7)
    L.rect(img, tx - 2, GY - 120, 40, 3, hex"#9aa1b2")
    barred(img, tx + 14, GY - 86, 8, 16, hex"#c9d0de", hex"#1a1b26", 2)
    barred(img, tx + 14, GY - 52, 8, 14, hex"#c9d0de", hex"#1a1b26", 2)
  end
  -- главный корпус
  box(img, 50, GY - 84, 100, 84, stone)
  battlements(img, 48, GY - 84, 104, stone, 8, 7)
  L.rect(img, 48, GY - 86, 104, 3, hex"#9aa1b2")
  -- решётка-опускная
  arch_door(img, 100, GY, 36, 52, hex"#12121a", hex"#444", nil)
  for xx = 83, 117, 4 do L.rect(img, xx, GY - 52, 1, 52, hex"#8b93a6") end
  for yy = GY - 48, GY - 4, 9 do L.rect(img, 83, yy, 35, 1, hex"#6b7284") end
  -- знамя
  L.rect(img, 96, GY - 78, 8, 2, hex"#4b4350")
  L.poly(img, {{94, GY - 76}, {106, GY - 76}, {106, GY - 62}, {100, GY - 58}, {94, GY - 62}}, hex"#b02a2a")
  L.poly(img, {{98, GY - 72}, {102, GY - 72}, {102, GY - 66}, {100, GY - 64}, {98, GY - 66}}, hex"#f0d060")
  barred(img, 64, GY - 66, 12, 18, hex"#c9d0de", hex"#1a1b26", 3)
  barred(img, 124, GY - 66, 12, 18, hex"#c9d0de", hex"#1a1b26", 3)
  bevel(img)
  L.outline(img, hex"#1d1f2b")
  return img
end

function B.gothic()
  local img = L.new(W, H)
  local st = brick_fn(hex"#4c4558", hex"#40394d", hex"#2b2636", 8)
  box(img, 40, GY - 96, 120, 96, st)
  -- высокая крыша и шпили
  gable(img, 34, 166, GY - 96, 100, GY - 160, tile_fn(hex"#2e2a3c", hex"#3b3650", hex"#1c1927"))
  for _, sx in ipairs({40, 160}) do
    box(img, sx - 8, GY - 130, 16, 130, brick_fn(hex"#554e63", hex"#483f56", hex"#2b2636", 5))
    gable(img, sx - 11, sx + 11, GY - 130, sx, GY - 168, tile_fn(hex"#2e2a3c", hex"#3b3650", hex"#1c1927"))
    L.line(img, sx, GY - 168, sx, GY - 176, hex"#8a80a0")
  end
  -- остроконечная дверь
  L.poly(img, {{84, GY}, {84, GY - 36}, {100, GY - 62}, {116, GY - 36}, {116, GY}}, hex"#0e0b14")
  for xx = 87, 113, 5 do L.rect(img, xx, GY - 56 + abs(xx - 100) * 2 - 6, 1, 56 - abs(xx - 100) * 2 + 6, hex"#7b7390") end
  for yy = GY - 40, GY - 4, 10 do L.rect(img, 86, yy, 28, 1, hex"#5d5670") end
  -- окна с фиолетовым светом
  for _, wx in ipairs({52, 140}) do
    L.poly(img, {{wx, GY - 52}, {wx, GY - 68}, {wx + 4, GY - 78}, {wx + 8, GY - 68}, {wx + 8, GY - 52}}, hex"#7a3fb5")
    L.rect(img, wx + 3, GY - 76, 2, 24, hex"#2b2636")
    L.rect(img, wx, GY - 62, 8, 1, hex"#2b2636")
  end
  -- цепи и череп над дверью
  for _, cx in ipairs({74, 126}) do
    for k = 0, 12 do L.put(img, cx + (k % 2), GY - 80 + k * 4, hex"#8a8296"); L.put(img, cx + (k % 2), GY - 79 + k * 4, hex"#5d5670") end
  end
  L.ellipse(img, 100, GY - 70, 4, 4, hex"#dcd6c6")
  L.rect(img, 98, GY - 70, 1, 2, hex"#1a1522"); L.rect(img, 101, GY - 70, 1, 2, hex"#1a1522"); L.rect(img, 99, GY - 66, 3, 1, hex"#1a1522")
  bevel(img)
  L.outline(img, hex"#14101c")
  glow(img, 100, GY - 62, 20, hex"#8a5ad0", 40)
  return img
end

function B.cats()
  local img = L.new(W, H)
  local wall = brick_fn(hex"#efdcc4", hex"#e6cfb2", hex"#c9ae90", 12)
  box(img, 36, GY - 88, 128, 88, wall)
  -- розовая черепица и кошачьи ушки
  gable(img, 28, 172, GY - 88, 100, GY - 138, tile_fn(hex"#d9748f", hex"#ee94ab", hex"#9c4560"))
  for _, ex in ipairs({58, 142}) do
    L.poly(img, {{ex - 14, GY - 100}, {ex - 10, GY - 140}, {ex + 8, GY - 108}}, hex"#d9748f")
    L.poly(img, {{ex - 9, GY - 104}, {ex - 8, GY - 130}, {ex + 2, GY - 110}}, hex"#f7b8c8")
  end
  -- арочная дверь с решёткой-рыбками
  arch_door(img, 100, GY, 36, 50, hex"#2a1a22", hex"#444", nil)
  for xx = 85, 115, 5 do L.rect(img, xx, GY - 46, 1, 46, hex"#f3c4d0") end
  L.rect(img, 83, GY - 22, 35, 1, hex"#c97a92")
  -- лапка над дверью
  L.ellipse(img, 100, GY - 62, 3, 2.5, hex"#6b3a4a")
  for _, d in ipairs({{-5, -4}, {-2, -6}, {2, -6}, {5, -4}}) do L.ellipse(img, 100 + d[1], GY - 62 + d[2], 1.4, 1.4, hex"#6b3a4a") end
  -- круглые окошки с решёткой
  for _, wx in ipairs({60, 140}) do
    L.ellipse(img, wx, GY - 52, 10, 10, hex"#2a1a22")
    for k = -6, 6, 4 do L.rect(img, wx + k, GY - 61, 1, 18, hex"#f3c4d0") end
    L.ellipse(img, wx, GY - 52, 10, 10, hex"#2a1a22", false)
  end
  -- цветочные горшки
  for _, px in ipairs({52, 148}) do
    L.rect(img, px - 6, GY - 8, 12, 8, hex"#b8634a")
    L.ellipse(img, px, GY - 11, 7, 5, hex"#5fa05a")
    L.put(img, px - 3, GY - 12, hex"#ffd0e0"); L.put(img, px + 2, GY - 13, hex"#fff0a0")
  end
  bevel(img, 1.1, 0.8)
  L.outline(img, hex"#5a3040")
  return img
end

function B.spider()
  local img = L.new(W, H)
  -- кокон-башня
  local body = function(x, y)
    local t = (x - 100) / 40
    local c = hex"#c9c9d8"
    if t < -0.35 then c = hex"#e2e2ee" elseif t > 0.3 then c = hex"#9696ab" end
    if (x + y * 2) % 11 == 0 or (x - y * 2) % 13 == 0 then c = L.mul(c, 0.86) end
    return c
  end
  for y = GY - 130, GY - 1 do
    local f = (y - (GY - 130)) / 130
    local hw = 40 * sin(math.pi * (0.12 + 0.88 * f) ^ 0.9) * 1.0
    if f > 0.9 then hw = hw * (1 - (f - 0.9) * 3) end
    for x = floor(100 - hw), floor(100 + hw) do L.put(img, x, y, body(x, y)) end
  end
  -- чёрный проём, окутанный нитями
  L.ellipse(img, 100, GY - 24, 14, 22, hex"#15121e")
  for k = -10, 10, 4 do L.line(img, 100 + k, GY - 46, 100 + k * 0.6, GY - 2, hex"#b9b9d0") end
  for yy = GY - 40, GY - 6, 8 do L.line(img, 87, yy, 113, yy + 2, hex"#8c8ca4") end
  -- паутина с вершины и по бокам
  for _, a in ipairs({-70, -48, -28, 28, 48, 70}) do L.line(img, 100, GY - 128, 100 + a * 1.3, GY - 98 + abs(a) * 0.3, hex"#d8d8e8") end
  for _, sx in ipairs({-1, 1}) do
    for k = 0, 3 do
      local x0 = 100 + sx * (52 + k * 8)
      L.line(img, x0, GY - 40 - k * 14, 100 + sx * 36, GY - 60 - k * 10, hex"#d8d8e8")
      L.ellipse(img, x0, GY - 36 - k * 14, 5, 8, hex"#b8b8cd")
      L.ellipse(img, x0 - 1, GY - 38 - k * 14, 3, 5, hex"#d4d4e4")
    end
  end
  bevel(img, 1.1, 0.85)
  L.outline(img, hex"#3d3a52")
  glow(img, 100, GY - 24, 18, hex"#9a6af0", 35)
  return img
end

function B.elves()
  local img = L.new(W, H)
  local bark = plank_fn(hex"#6a4a2c", hex"#5c3f25", hex"#3a2616", 4, 4)
  -- ствол-дом
  for y = GY - 120, GY - 1 do
    local f = (GY - y) / 120
    local hw = 46 - f * 8 + (y > GY - 14 and (y - (GY - 14)) * 1.2 or 0)
    for x = floor(100 - hw), floor(100 + hw) do L.put(img, x, y, bark(x, y)) end
  end
  -- крона
  for _, b in ipairs({{100, 30, 52}, {66, 46, 34}, {136, 46, 34}, {84, 22, 30}, {118, 24, 30}}) do
    L.ellipse(img, b[1], b[2], b[3], b[3] * 0.72, hex"#3f7a3c")
  end
  for _, b in ipairs({{92, 24, 30}, {70, 40, 20}, {124, 30, 22}}) do L.ellipse(img, b[1], b[2], b[3], b[3] * 0.6, hex"#5fa850") end
  for k = 1, 40 do local x, y = 52 + L.hash(k, 3, 9) * 96, 10 + L.hash(k, 5, 9) * 46; if L.opaque(img, floor(x), floor(y)) then L.put(img, floor(x), floor(y), hex"#8fd070") end end
  -- дверь-арка из корней: решётка из переплетённых корней
  arch_door(img, 100, GY, 34, 48, hex"#1a1410", hex"#444", nil)
  for k = -12, 12, 6 do L.line(img, 100 + k, GY - 48, 100 + k + (k > 0 and 3 or -3), GY, hex"#7a5430"); L.line(img, 101 + k, GY - 48, 101 + k + (k > 0 and 3 or -3), GY, hex"#4b321c") end
  L.line(img, 84, GY - 24, 116, GY - 20, hex"#7a5430")
  -- окошки с ветками и фонарики
  for _, wx in ipairs({64, 136}) do
    L.ellipse(img, wx, GY - 70, 6, 8, hex"#161b10")
    for k = -3, 3, 3 do L.line(img, wx + k, GY - 77, wx + k, GY - 63, hex"#7a5430") end
    L.ellipse(img, wx, GY - 70, 6, 8, hex"#161b10", false)
  end
  for _, lx in ipairs({78, 122}) do
    L.rect(img, lx, GY - 96, 1, 6, hex"#4b321c")
    L.ellipse(img, lx, GY - 88, 3, 4, hex"#ffe08a")
  end
  bevel(img, 1.12, 0.8)
  L.outline(img, hex"#1c2410")
  glow(img, 78, GY - 88, 14, hex"#ffe08a", 60)
  glow(img, 122, GY - 88, 14, hex"#ffe08a", 60)
  return img
end

function B.mages()
  local img = L.new(W, H)
  local st = brick_fn(hex"#8c86b0", hex"#7d78a0", hex"#5a5580", 21)
  box(img, 36, GY - 76, 128, 76, st)
  -- башня-кристалл
  box(img, 76, GY - 150, 48, 74, brick_fn(hex"#9690bc", hex"#847ea8", hex"#5a5580", 22))
  gable(img, 70, 130, GY - 150, 100, GY - 186, tile_fn(hex"#4a3f98", hex"#6a5ad0", hex"#2a2260"))
  -- парящие кристаллы
  for _, c in ipairs({{54, GY - 120, 4, 10}, {146, GY - 130, 4, 12}, {100, GY - 196, 3, 8}}) do
    L.poly(img, {{c[1], c[2] - c[4]}, {c[1] + c[3], c[2]}, {c[1], c[2] + c[4] * 0.6}, {c[1] - c[3], c[2]}}, hex"#7a66ff", function(x, y) return x < c[1] and hex"#a898ff" or hex"#5848d0" end)
  end
  -- окно-щель башни и дверь с энергетическими прутьями
  L.rect(img, 98, GY - 128, 4, 24, hex"#7ad8ff")
  L.rect(img, 98, GY - 90, 4, 12, hex"#7ad8ff")
  arch_door(img, 100, GY, 36, 50, hex"#1d1840", hex"#444", nil)
  for xx = 85, 115, 5 do L.rect(img, xx, GY - 48, 2, 48, hex"#ff7aef"); L.rect(img, xx, GY - 48, 1, 48, hex"#ffc0f6") end
  -- руны по стене
  for k = 0, 7 do
    local rx = 44 + k * 14
    if abs(rx - 100) > 22 then L.rect(img, rx, GY - 54, 1, 6, hex"#c9c4ee"); L.rect(img, rx, GY - 54 + (k % 3) * 2, 4, 1, hex"#c9c4ee") end
  end
  for _, wx in ipairs({50, 138}) do barred(img, wx, GY - 56, 12, 20, hex"#e0dcff", hex"#241e50", 3) end
  bevel(img)
  L.outline(img, hex"#221c46")
  glow(img, 100, GY - 24, 22, hex"#ff7aef", 40)
  glow(img, 100, GY - 196, 14, hex"#7a66ff", 50)
  return img
end

function B.orcs()
  local img = L.new(W, H)
  local logs = plank_fn(hex"#6b4a30", hex"#5a3c26", hex"#2e1c10", 31, 6)
  box(img, 26, GY - 82, 148, 82, logs)
  -- заострённые верхушки брёвен
  for xx = 26, 172, 6 do
    L.poly(img, {{xx, GY - 82}, {xx + 3, GY - 94 - (xx % 12 == 0 and 4 or 0)}, {xx + 6, GY - 82}}, hex"#000000", function(x, y) return (x < xx + 3) and hex"#7c5838" or hex"#5a3c26" end)
  end
  -- ворота из костей
  L.rect(img, 76, GY - 56, 48, 56, hex"#1a1008")
  for xx = 80, 120, 8 do
    L.rect(img, xx, GY - 54, 3, 52, hex"#e8e0c8"); L.rect(img, xx, GY - 54, 1, 52, hex"#fffbe8"); L.rect(img, xx + 2, GY - 54, 1, 52, hex"#b8ae90")
    L.ellipse(img, xx + 1, GY - 55, 3, 2, hex"#e8e0c8"); L.ellipse(img, xx + 1, GY - 3, 3, 2, hex"#e8e0c8")
  end
  L.rect(img, 78, GY - 28, 44, 3, hex"#d8d0b8")
  -- череп-тотем над воротами
  L.ellipse(img, 100, GY - 70, 8, 7, hex"#e8e0c8")
  L.rect(img, 95, GY - 71, 3, 3, hex"#1a1008"); L.rect(img, 102, GY - 71, 3, 3, hex"#1a1008"); L.rect(img, 99, GY - 66, 3, 2, hex"#1a1008")
  for _, tx in ipairs({40, 160}) do
    L.rect(img, tx - 1, GY - 108, 3, 30, hex"#4b3220")
    L.poly(img, {{tx - 10, GY - 104}, {tx + 10, GY - 104}, {tx + 10, GY - 88}, {tx, GY - 82}, {tx - 10, GY - 88}}, hex"#a02a22")
    L.rect(img, tx - 3, GY - 98, 6, 4, hex"#f0d060")
  end
  -- шкуры и рога
  for _, hx in ipairs({48, 152}) do
    L.poly(img, {{hx - 8, GY - 60}, {hx + 8, GY - 60}, {hx + 6, GY - 30}, {hx, GY - 24}, {hx - 6, GY - 30}}, hex"#8a6a48")
    L.rect(img, hx - 4, GY - 54, 3, 3, hex"#5a4028"); L.rect(img, hx + 2, GY - 44, 3, 3, hex"#5a4028")
  end
  bevel(img, 1.15, 0.78)
  L.outline(img, hex"#1c120a")
  return img
end

function B.goblins()
  local img = L.new(W, H)
  local plates = {hex"#7a8aa0", hex"#a86a3a", hex"#5f9a6a", hex"#8a8f98", hex"#b89a4a", hex"#6a6a88"}
  local px = function(x, y)
    local gx, gy = floor(x / 18), floor(y / 14 + (floor(x / 18) % 2) * 0.5)
    local c = plates[floor(L.hash(gx, gy, 41) * #plates) + 1]
    if x % 18 == 0 or y % 14 == 0 then return L.mul(c, 0.55) end
    if (x % 18 == 2 and y % 14 == 2) or (x % 18 == 16 and y % 14 == 12) then return hex"#e8dfc0" end
    return c
  end
  box(img, 40, GY - 78, 120, 78, px)
  -- кривая крыша из листов
  L.poly(img, {{30, GY - 74}, {170, GY - 80}, {160, GY - 100}, {44, GY - 98}}, hex"#000000", function(x, y) return (x + y) % 12 < 6 and hex"#8a4a2a" or hex"#6c3a20" end)
  -- труба и дым
  box(img, 130, GY - 126, 16, 28, brick_fn(hex"#9a5a3a", hex"#85492c", hex"#5a3020", 4))
  for k = 0, 3 do L.ellipse(img, 138 + k * 3, GY - 134 - k * 9, 6 + k, 4 + k, hex("#8a8a98", 150 - k * 30)) end
  -- дверь: решётка из каркасов кроватей
  L.rect(img, 78, GY - 52, 44, 52, hex"#14100c")
  for xx = 82, 118, 6 do L.rect(img, xx, GY - 50, 2, 48, hex"#b0623a"); L.rect(img, xx, GY - 50, 1, 48, hex"#e08a50") end
  L.rect(img, 80, GY - 34, 40, 2, hex"#8a8f98"); L.rect(img, 80, GY - 14, 40, 2, hex"#8a8f98")
  -- шестерёнки и лампа
  for _, g in ipairs({{54, GY - 56, 8}, {148, GY - 30, 6}}) do
    L.ellipse(img, g[1], g[2], g[3], g[3], hex"#c8b060")
    L.ellipse(img, g[1], g[2], g[3] * 0.4, g[3] * 0.4, hex"#3a2c1a")
    for a = 0, 7 do local an = a * math.pi / 4; L.rect(img, floor(g[1] + cos(an) * (g[3] + 1)) - 1, floor(g[2] + sin(an) * (g[3] + 1)) - 1, 2, 2, hex"#c8b060") end
  end
  L.rect(img, 100, GY - 74, 1, 8, hex"#3a2c1a"); L.ellipse(img, 100, GY - 62, 4, 4, hex"#ffe060")
  barred(img, 52, GY - 36, 14, 14, hex"#d8d0b0", hex"#1a1410", 3)
  bevel(img, 1.12, 0.78)
  L.outline(img, hex"#241a12")
  glow(img, 100, GY - 62, 16, hex"#ffe060", 60)
  return img
end

function B.dwarves()
  local img = L.new(W, H)
  -- скальный массив
  local rock = brick_fn(hex"#86796a", hex"#756a5c", hex"#4e463c", 51)
  for y = GY - 130, GY - 1 do
    local f = (y - (GY - 130)) / 130
    local hw = 30 + 66 * f ^ 0.55
    for x = floor(100 - hw), floor(100 + hw) do
      local c = rock(x, y)
      if L.hash(floor(x / 3), floor(y / 3), 6) > 0.9 then c = L.mul(c, 0.8) end
      L.put(img, x, y, c)
    end
  end
  -- каменное крыльцо и арка
  L.rect(img, 70, GY - 4, 60, 4, hex"#9a8e7e")
  arch_door(img, 100, GY - 4, 40, 56, hex"#16110c", hex"#444", nil)
  -- железная дверь с заклёпками и решёткой-оконцем
  L.rect(img, 84, GY - 50, 32, 46, hex"#454a58")
  for yy = GY - 48, GY - 8, 8 do L.rect(img, 84, yy, 32, 1, hex"#2e323e"); for xx = 87, 113, 8 do L.put(img, xx, yy + 3, hex"#9aa4bc") end end
  barred(img, 92, GY - 44, 16, 12, hex"#c9d0de", hex"#0a0a10", 3)
  -- кирки крест-накрест и горн
  L.line(img, 78, GY - 82, 98, GY - 62, hex"#7a4a22"); L.line(img, 122, GY - 82, 102, GY - 62, hex"#7a4a22")
  L.line(img, 74, GY - 86, 84, GY - 84, hex"#aab4cc"); L.line(img, 126, GY - 86, 116, GY - 84, hex"#aab4cc")
  L.rect(img, 138, GY - 54, 18, 14, hex"#ffb040"); L.rect(img, 140, GY - 52, 14, 10, hex"#ff7a20")
  L.rect(img, 136, GY - 56, 22, 2, hex"#2e323e"); L.rect(img, 136, GY - 40, 22, 2, hex"#2e323e")
  for _, mx in ipairs({56, 144}) do L.rect(img, mx, GY - 90, 4, 18, hex"#4b3220"); L.rect(img, mx - 2, GY - 92, 8, 3, hex"#2e323e") end
  bevel(img)
  L.outline(img, hex"#241d16")
  glow(img, 147, GY - 47, 16, hex"#ff9a30", 55)
  return img
end

function B.japan()
  local img = L.new(W, H)
  -- белая штукатурка и тёмный каркас
  box(img, 38, GY - 70, 124, 70, function(x, y) return (x + y) % 7 == 0 and hex"#e6e0d0" or hex"#f3eee0" end)
  for xx = 38, 160, 24 do L.rect(img, xx, GY - 70, 4, 70, hex"#3a2a22") end
  L.rect(img, 38, GY - 70, 124, 4, hex"#3a2a22"); L.rect(img, 38, GY - 8, 124, 3, hex"#3a2a22")
  -- двухъярусная крыша с загнутыми углами
  local roof = tile_fn(hex"#4a5260", hex"#5d6676", hex"#2a2f3a")
  L.poly(img, {{14, GY - 66}, {186, GY - 66}, {172, GY - 88}, {28, GY - 88}}, hex"#000000", roof)
  L.poly(img, {{4, GY - 70}, {14, GY - 66}, {28, GY - 88}, {10, GY - 80}}, hex"#4a5260")
  L.poly(img, {{196, GY - 70}, {186, GY - 66}, {172, GY - 88}, {190, GY - 80}}, hex"#4a5260")
  L.poly(img, {{46, GY - 88}, {154, GY - 88}, {136, GY - 116}, {64, GY - 116}}, hex"#000000", roof)
  L.poly(img, {{38, GY - 94}, {46, GY - 88}, {64, GY - 116}, {50, GY - 106}}, hex"#4a5260")
  L.poly(img, {{162, GY - 94}, {154, GY - 88}, {136, GY - 116}, {150, GY - 106}}, hex"#4a5260")
  -- красная дверь-рама с бамбуковыми прутьями
  L.rect(img, 80, GY - 52, 40, 52, hex"#b32a2a")
  L.rect(img, 84, GY - 48, 32, 48, hex"#1a1410")
  for xx = 86, 114, 5 do L.rect(img, xx, GY - 48, 3, 48, hex"#7cae4a"); L.rect(img, xx, GY - 48, 1, 48, hex"#b6e07a"); L.rect(img, xx + 2, GY - 48, 1, 48, hex"#4c7a2a") end
  for yy = GY - 36, GY - 12, 18 do L.rect(img, 84, yy, 32, 2, hex"#5a8a34") end
  L.rect(img, 76, GY - 56, 48, 4, hex"#b32a2a")
  -- бумажные фонарики
  for _, lx in ipairs({56, 144}) do
    L.rect(img, lx, GY - 44, 1, 6, hex"#3a2a22")
    L.ellipse(img, lx, GY - 36, 5, 6, hex"#e84a3a"); L.rect(img, lx - 3, GY - 36, 7, 1, hex"#a02a22")
  end
  for _, wx in ipairs({50, 138}) do barred(img, wx, GY - 56, 14, 22, hex"#7cae4a", hex"#2a2018", 4) end
  bevel(img, 1.1, 0.8)
  L.outline(img, hex"#241a14")
  glow(img, 56, GY - 36, 12, hex"#ff9a50", 45)
  glow(img, 144, GY - 36, 12, hex"#ff9a50", 45)
  return img
end

-- ============================================================ камера в комнате (84×76)
local function cell_img(o)
  local w, h = 84, 76
  local img = L.new(w, h)
  -- ниша
  L.rect(img, 2, 8, w - 4, h - 12, o.bg)
  L.rect(img, 2, h - 18, w - 4, 14, o.floor)
  for xx = 2, w - 3, 8 do L.rect(img, xx, h - 18, 1, 14, L.mul(o.floor, 0.8)) end
  -- нары
  L.rect(img, 8, h - 34, 40, 6, o.bed)
  L.rect(img, 8, h - 34, 40, 1, L.mul(o.bed, 1.25))
  L.rect(img, 10, h - 28, 3, 10, L.mul(o.bed, 0.6)); L.rect(img, 43, h - 28, 3, 10, L.mul(o.bed, 0.6))
  L.rect(img, 8, h - 40, 14, 6, o.pillow)
  L.rect(img, 22, h - 36, 24, 2, o.blanket)
  if o.extra then o.extra(img, w, h) end
  -- решётка
  local top, bot = 6, h - 3
  for xx = 6, w - 7, o.step or 7 do
    if o.bar_fn then o.bar_fn(img, xx, top, bot) else
      L.rect(img, xx, top, 3, bot - top, o.bar); L.rect(img, xx, top, 1, bot - top, L.mul(o.bar, 1.3)); L.rect(img, xx + 2, top, 1, bot - top, L.mul(o.bar, 0.65))
    end
  end
  L.rect(img, 3, top - 2, w - 6, 4, o.frame); L.rect(img, 3, top - 2, w - 6, 1, L.mul(o.frame, 1.3))
  L.rect(img, 3, bot - 3, w - 6, 4, o.frame)
  L.rect(img, 0, top - 2, 3, bot - top + 6, o.frame); L.rect(img, w - 3, top - 2, 3, bot - top + 6, o.frame)
  -- замок
  L.rect(img, floor(w / 2) - 3, floor(h / 2), 6, 6, o.lock); L.rect(img, floor(w / 2) - 1, floor(h / 2) + 2, 2, 2, hex"#14100c")
  L.outline(img, o.out)
  return img
end

local CELLS = {
  knights = {bg = hex"#1a1c26", floor = hex"#5a5f70", bed = hex"#7a5a3a", pillow = hex"#cfc8b8", blanket = hex"#6a7a9a", bar = hex"#a9b1c4", frame = hex"#6b7284", lock = hex"#e0c050", out = hex"#14151e"},
  gothic = {bg = hex"#120e1a", floor = hex"#3a3446", bed = hex"#4a3a58", pillow = hex"#8a7ea0", blanket = hex"#5a2a50", bar = hex"#807890", frame = hex"#4a4358", lock = hex"#b8b0c8", out = hex"#0a0710",
    extra = function(img, w, h)
      for _, cx in ipairs({60, 68}) do for k = 0, 9 do L.put(img, cx + (k % 2), 10 + k * 3, hex"#9a92aa") end end
      L.ellipse(img, 72, h - 24, 3, 3, hex"#dcd6c6")
    end},
  cats = {bg = hex"#2a1a22", floor = hex"#e6c6a8", bed = hex"#f0a8c0", pillow = hex"#fff0f4", blanket = hex"#f7c8d4", bar = hex"#f6d4de", frame = hex"#d9748f", lock = hex"#ffe08a", out = hex"#5a3040",
    extra = function(img, w, h) L.ellipse(img, 62, h - 20, 5, 5, hex"#e04a6a"); L.ellipse(img, 61, h - 21, 2, 2, hex"#ff9aaa"); L.line(img, 66, h - 18, 74, h - 14, hex"#e04a6a") end},
  spider = {bg = hex"#17141f", floor = hex"#4a4660", bed = hex"#c9c9d8", pillow = hex"#e6e6f2", blanket = hex"#a9a9bd", bar = hex"#d8d8e8", frame = hex"#9696ab", lock = hex"#9a6af0", out = hex"#2a2740", step = 9,
    bar_fn = function(img, x, top, bot) L.line(img, x, top, x + 2, bot, hex"#d8d8e8"); L.line(img, x + 3, top, x + 1, bot, hex"#9a9ab4") end},
  elves = {bg = hex"#14180e", floor = hex"#4a5a30", bed = hex"#8ab860", pillow = hex"#d8eab0", blanket = hex"#3f7a3c", bar = hex"#7a5430", frame = hex"#4b321c", lock = hex"#ffe08a", out = hex"#1c2410",
    bar_fn = function(img, x, top, bot) for y = top, bot do local off = floor(sin(y * 0.25 + x) * 1.2 + 0.5); L.put(img, x + off, y, hex"#7a5430"); L.put(img, x + off + 1, y, hex"#4b321c"); L.put(img, x + off - 1, y, hex"#9a7040") end end},
  mages = {bg = hex"#14102e", floor = hex"#5a5580", bed = hex"#6a5ad0", pillow = hex"#c4bcff", blanket = hex"#4a3f98", bar = hex"#ff7aef", frame = hex"#7a66ff", lock = hex"#7ad8ff", out = hex"#221c46", step = 6,
    bar_fn = function(img, x, top, bot) L.rect(img, x, top, 2, bot - top, hex"#ff7aef"); L.rect(img, x, top, 1, bot - top, hex"#ffc0f6") end},
  orcs = {bg = hex"#1a1008", floor = hex"#4a3a28", bed = hex"#8a6a48", pillow = hex"#6a4a30", blanket = hex"#a02a22", bar = hex"#e8e0c8", frame = hex"#5a3c26", lock = hex"#c8b060", out = hex"#1c120a",
    bar_fn = function(img, x, top, bot) L.rect(img, x, top, 3, bot - top, hex"#e8e0c8"); L.rect(img, x, top, 1, bot - top, hex"#fffbe8"); L.rect(img, x + 2, top, 1, bot - top, hex"#b8ae90"); L.ellipse(img, x + 1, top, 3, 2, hex"#e8e0c8") end},
  goblins = {bg = hex"#14100c", floor = hex"#5a4a3a", bed = hex"#8a8f98", pillow = hex"#c8b060", blanket = hex"#5f9a6a", bar = hex"#b0623a", frame = hex"#8a8f98", lock = hex"#e8dfc0", out = hex"#241a12", step = 8,
    bar_fn = function(img, x, top, bot) L.rect(img, x, top, 2, bot - top, hex"#b0623a"); L.rect(img, x, top, 1, bot - top, hex"#e08a50"); L.rect(img, x - 1, floor((top + bot) / 2) - 8, 4, 2, hex"#8a8f98") end},
  dwarves = {bg = hex"#16110c", floor = hex"#6a5e50", bed = hex"#7a4a22", pillow = hex"#c9b89a", blanket = hex"#8f2316", bar = hex"#454a58", frame = hex"#2e323e", lock = hex"#ffb040", out = hex"#0e0b08", step = 8,
    bar_fn = function(img, x, top, bot) L.rect(img, x, top, 4, bot - top, hex"#454a58"); L.rect(img, x, top, 1, bot - top, hex"#7d879e"); L.rect(img, x + 3, top, 1, bot - top, hex"#2e323e") end},
  japan = {bg = hex"#1a1410", floor = hex"#c9ae80", bed = hex"#e6dcc0", pillow = hex"#f6f0e0", blanket = hex"#b32a2a", bar = hex"#7cae4a", frame = hex"#3a2a22", lock = hex"#e84a3a", out = hex"#241a14", step = 7,
    bar_fn = function(img, x, top, bot) L.rect(img, x, top, 3, bot - top, hex"#7cae4a"); L.rect(img, x, top, 1, bot - top, hex"#b6e07a"); L.rect(img, x + 2, top, 1, bot - top, hex"#4c7a2a"); for yy = top + 14, bot - 6, 18 do L.rect(img, x, yy, 3, 1, hex"#3a5a1a") end end},
}

local only = app.params["only"] or "all"
local ORDER = {"knights", "gothic", "cats", "spider", "elves", "mages", "orcs", "goblins", "dwarves", "japan"}
if only == "all" or only == "prison" then
  for _, land in ipairs(ORDER) do
    local img = B[land]()
    L.save(img, "prison_" .. land, true)
    L.save(cell_img(CELLS[land]), "pr18_cell_" .. land, true)
  end
end
