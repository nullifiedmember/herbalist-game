-- Приюты для животных (v19): у кошкодевочек — кошачий, в других городах — общий.
local L = dofile("C:/Claude/herbalist_game/game/tools/aseprite/lib.lua")
local hex = L.hex
local floor, sin, abs = math.floor, math.sin, math.abs
local W, H = 210, 176
local GY = H - 8

local function box(img, x, y, w, h, fn) for yy = y, y + h - 1 do for xx = x, x + w - 1 do L.put(img, xx, yy, fn(xx, yy)) end end end
local function planks(a, b, gap, w)
  return function(x, y)
    local k = floor(x / w)
    if x % w == 0 then return gap end
    local c = (k % 2 == 0) and a or b
    if L.hash(k, floor(y / 9), 3) < 0.15 then c = L.mul(c, 0.88) end
    if x % w == 1 then c = L.mul(c, 1.12) end
    return c
  end
end
local function tiles(a, b, edge)
  return function(x, y)
    local row = floor(y / 5)
    local cx = (x + (row % 2) * 4) % 8
    if y % 5 == 4 then return edge end
    if cx == 0 then return L.mul(a, 0.82) end
    return (y % 5 <= 1) and b or a
  end
end
local function bevel(img)
  local src = L.new(img.width, img.height); src:drawImage(img)
  for y = 0, img.height - 1 do for x = 0, img.width - 1 do
    if L.alpha(src:getPixel(x, y)) == 255 then
      local c = src:getPixel(x, y)
      if not L.opaque(src, x - 1, y) or not L.opaque(src, x, y - 1) then img:putPixel(x, y, L.mul(c, 1.15)) end
      if not L.opaque(src, x + 1, y) or not L.opaque(src, x, y + 1) then img:putPixel(x, y, L.mul(c, 0.8)) end
    end
  end end
end
local function paw(img, cx, cy, col, s)
  s = s or 1
  L.ellipse(img, cx, cy, 4 * s, 3.3 * s, col)
  for _, d in ipairs({{-5, -5}, {-2, -8}, {2, -8}, {5, -5}}) do L.ellipse(img, cx + d[1] * s, cy + d[2] * s, 1.6 * s, 1.8 * s, col) end
end
local function window(img, x, y, w, h, frame)
  L.rect(img, x - 2, y - 2, w + 4, h + 4, frame)
  for yy = 0, h - 1 do L.rect(img, x, y + yy, w, 1, L.mix(hex"#ffe6a0", hex"#f0b860", yy / h)) end
  L.rect(img, x + floor(w / 2), y, 1, h, frame); L.rect(img, x, y + floor(h / 2), w, 1, frame)
  L.rect(img, x - 3, y + h + 2, w + 6, 3, L.mul(frame, 1.2))
end

local function shelter(cat)
  local img = L.new(W, H)
  local wall = cat and planks(hex"#f2d6c6", hex"#ead0be", hex"#c09a88", 7) or planks(hex"#c89a62", hex"#b88a54", hex"#7a5430", 7)
  local roof = cat and tiles(hex"#e07a96", hex"#f49ab0", hex"#9c4560") or tiles(hex"#6a8a4a", hex"#86a85a", hex"#3e5a2a")
  -- дворик с низким забором
  for x = 6, W - 8, 10 do
    if x > 82 and x < 124 then goto skip end
    L.rect(img, x, GY - 22, 4, 22, hex"#d8b888"); L.rect(img, x, GY - 22, 1, 22, hex"#f0d8a8")
    L.poly(img, {{x, GY - 22}, {x + 2, GY - 26}, {x + 4, GY - 22}}, hex"#d8b888")
    ::skip::
  end
  for _, seg in ipairs({{4, 82}, {124, W - 4}}) do
    L.rect(img, seg[1], GY - 16, seg[2] - seg[1], 3, hex"#b8986a"); L.rect(img, seg[1], GY - 8, seg[2] - seg[1], 3, hex"#b8986a")
  end
  -- дорожка к двери
  L.rect(img, 92, GY - 16, 26, 16, hex"#c8b48a"); for k = 0, 3 do L.rect(img, 94 + k * 6, GY - 14 + (k % 2) * 6, 5, 4, hex"#a8946a") end
  -- дом
  box(img, 40, GY - 96, 130, 80, wall)
  L.poly(img, {{28, GY - 92}, {105, GY - 146}, {182, GY - 92}}, hex"#000000", roof)
  if cat then
    for _, ex in ipairs({62, 148}) do
      L.poly(img, {{ex - 12, GY - 104}, {ex - 8, GY - 142}, {ex + 8, GY - 112}}, hex"#e07a96")
      L.poly(img, {{ex - 7, GY - 108}, {ex - 6, GY - 132}, {ex + 2, GY - 114}}, hex"#ffc8d6")
    end
  else
    -- труба
    L.rect(img, 140, GY - 140, 12, 30, hex"#9a5a3a"); L.rect(img, 138, GY - 142, 16, 4, hex"#7a4428")
  end
  -- вывеска с лапкой
  L.rect(img, 86, GY - 126, 38, 22, hex"#6a4426"); L.rect(img, 88, GY - 124, 34, 18, hex"#f4e4c0")
  paw(img, 105, GY - 112, cat and hex"#d06080" or hex"#6a4426", 1)
  -- дверь
  L.rect(img, 92, GY - 52, 26, 36, hex"#7a4a2a"); L.rect(img, 94, GY - 50, 22, 34, hex"#9a6238")
  L.rect(img, 104, GY - 50, 1, 34, hex"#6a3a1e"); L.put(img, 110, GY - 34, hex"#f0d060")
  L.ellipse(img, 105, GY - 52, 13, 6, hex"#7a4a2a"); L.ellipse(img, 105, GY - 51, 11, 4, hex"#9a6238")
  window(img, 52, GY - 74, 26, 22, hex"#6a4426")
  window(img, 132, GY - 74, 26, 22, hex"#6a4426")
  -- миски и лежанки во дворе
  L.ellipse(img, 28, GY - 6, 9, 3, hex"#5a6aa8"); L.ellipse(img, 28, GY - 7, 6, 1.5, hex"#c89050")
  L.ellipse(img, 186, GY - 7, 14, 5, cat and hex"#e88aa8" or hex"#8a6a4a"); L.ellipse(img, 186, GY - 9, 10, 3, cat and hex"#ffd0dc" or hex"#c8a878")
  -- силуэты зверей в окнах
  if cat then
    L.ellipse(img, 65, GY - 58, 5, 4, hex"#3a2a2a"); L.poly(img, {{61, GY - 61}, {62, GY - 66}, {64, GY - 61}}, hex"#3a2a2a"); L.poly(img, {{66, GY - 61}, {68, GY - 66}, {69, GY - 61}}, hex"#3a2a2a")
  else
    L.ellipse(img, 145, GY - 58, 6, 4, hex"#5a3a2a"); L.ellipse(img, 142, GY - 64, 2, 4, hex"#5a3a2a"); L.ellipse(img, 147, GY - 64, 2, 4, hex"#5a3a2a")
  end
  bevel(img)
  L.outline(img, cat and hex"#5a3040" or hex"#2e1e12")
  return img
end

L.save(shelter(true), "shelter_cats", true)
L.save(shelter(false), "shelter_town", true)
