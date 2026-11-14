-- Шахта под пещерой (v19): плитка пола, стенка, крепь, рельсы, лестница наверх, фонарь, ящик.
local L = dofile("C:/Claude/herbalist_game/game/tools/aseprite/lib.lua")
local hex = L.hex
local floor, sin, cos, abs = math.floor, math.sin, math.cos, math.abs

-- пол: бесшовная плитка 64×64 (тёмный камень, мелкая галька, трещинки)
local function mine_floor()
  local img = L.new(64, 64)
  local tones = {hex"#2a2632", hex"#322d3c", hex"#3a3446", hex"#433c50"}
  for y = 0, 63 do for x = 0, 63 do
    local n = L.hash(floor(x / 4) % 16, floor(y / 4) % 16, 21) * 0.6 + L.hash(x, y, 22) * 0.4
    img:putPixel(x, y, tones[floor(n * 3.99) + 1])
  end end
  -- галька
  for k = 1, 14 do
    local x, y = floor(L.hash(k, 1, 23) * 60), floor(L.hash(k, 2, 23) * 60)
    local r = 1 + floor(L.hash(k, 3, 23) * 2)
    for dy = -r, r do for dx = -r - 1, r + 1 do
      if dx * dx / ((r + 1) * (r + 1)) + dy * dy / (r * r) <= 1 then
        local c = (dy < 0 and dx < 0) and hex"#5a5468" or hex"#4a4458"
        img:putPixel((x + dx) % 64, (y + dy) % 64, c)
      end
    end end
    img:putPixel((x + r) % 64, (y + r) % 64, hex"#1e1b26")
  end
  -- трещины
  for k = 1, 3 do
    local x, y = floor(L.hash(k, 9, 24) * 64), floor(L.hash(k, 8, 24) * 64)
    for s = 1, 10 do
      img:putPixel(x % 64, y % 64, hex"#1a1822")
      x = x + 1; y = y + (L.hash(k, s, 25) > 0.5 and 1 or 0)
    end
  end
  return img
end

-- стенка (лицевая сторона скалы сверху у края прохода): 128×64, бесшовна по горизонтали
local function mine_wall()
  local img = L.new(128, 64)
  local tones = {hex"#1c1a24", hex"#2c2836", hex"#3c3648", hex"#4e475c", hex"#625a72"}
  -- крупные глыбы-грани
  for y = 0, 63 do for x = 0, 127 do
    local cx = floor(x / 20)
    local off = floor(L.hash(cx % 7, 1, 31) * 10)
    local cy = floor((y + off) / 18)
    local lv = L.hash(cx % 7, cy, 32)
    local fx = ((x % 20) / 20)
    local fy = (((y + off) % 18) / 18)
    local light = lv * 0.5 + (1 - fy) * 0.35 - fx * 0.15 + (y / 64) * -0.1
    local idx = floor(math.max(0, math.min(0.999, light)) * 4) + 1
    if (x % 20 == 0) or ((y + off) % 18 == 0) then idx = 1 end
    if y > 52 then idx = math.max(1, idx - 1) end
    img:putPixel(x, y, tones[idx])
  end end
  -- кристаллики и мох в щелях
  for k = 1, 6 do
    local x, y = floor(L.hash(k, 3, 33) * 124), 10 + floor(L.hash(k, 4, 33) * 40)
    local c = (k % 3 == 0) and hex"#7a66ff" or hex"#4a6a3a"
    img:putPixel(x, y, c); img:putPixel(x + 1, y, c); img:putPixel(x, y - 1, L.mul(c, 1.3))
  end
  -- тёмная кромка снизу (тень у основания)
  for x = 0, 127 do img:putPixel(x, 63, hex"#0e0d12"); img:putPixel(x, 62, hex"#16141c") end
  return img
end

-- крепь: две стойки и перекладина
local function beam()
  local img = L.new(64, 80)
  local wood = {hex"#3a2414", hex"#5e3c20", hex"#86582e", hex"#a8723e"}
  for _, px in ipairs({6, 52}) do
    L.rect(img, px, 12, 7, 66, wood[2]); L.rect(img, px, 12, 2, 66, wood[3]); L.rect(img, px + 6, 12, 1, 66, wood[1])
    for y = 18, 74, 11 do L.put(img, px + 3, y, wood[1]) end
  end
  L.rect(img, 2, 6, 60, 9, wood[2]); L.rect(img, 2, 6, 60, 2, wood[4]); L.rect(img, 2, 14, 60, 1, wood[1])
  for x = 8, 56, 12 do L.put(img, x, 10, wood[1]) end
  -- скобы
  for _, px in ipairs({9, 55}) do L.rect(img, px - 2, 13, 5, 3, hex"#5a5e6a"); L.put(img, px, 14, hex"#9aa0b0") end
  L.outline(img, hex"#140c06")
  return img
end

-- рельсы: бесшовный кусок 64×16
local function rail()
  local img = L.new(64, 16)
  for x = 0, 63, 16 do
    L.rect(img, x + 2, 2, 10, 12, hex"#4a301c"); L.rect(img, x + 2, 2, 10, 1, hex"#6e4826"); L.rect(img, x + 2, 13, 10, 1, hex"#2a1a0e")
  end
  for _, ry in ipairs({4, 10}) do
    L.rect(img, 0, ry, 64, 2, hex"#7a8090"); L.rect(img, 0, ry, 64, 1, hex"#b8c0d0"); L.rect(img, 0, ry + 2, 64, 1, hex"#3a3e48")
  end
  return img
end

local function ladder()
  local img = L.new(30, 92)
  -- столб света сверху
  for y = 0, 91 do
    local a = math.floor(90 * (1 - y / 92))
    for x = 0, 29 do
      local d = abs(x - 15) / 15
      if d < 1 then L.put(img, x, y, L.withA(hex"#fff0c0", math.floor(a * (1 - d)))) end
    end
  end
  local wood = {hex"#3a2414", hex"#6e4826", hex"#a06a36"}
  for _, px in ipairs({5, 22}) do L.rect(img, px, 0, 3, 92, wood[2]); L.rect(img, px, 0, 1, 92, wood[3]) end
  for y = 6, 88, 10 do L.rect(img, 5, y, 20, 3, wood[2]); L.rect(img, 5, y, 20, 1, wood[3]); L.rect(img, 5, y + 2, 20, 1, wood[1]) end
  return img
end

local function lamp()
  local img = L.new(16, 40)
  L.rect(img, 7, 10, 2, 30, hex"#5e3c20"); L.rect(img, 7, 10, 1, 30, hex"#86582e")
  L.rect(img, 3, 2, 10, 2, hex"#3a3e48")
  L.rect(img, 4, 4, 8, 9, hex"#ffd070"); L.rect(img, 5, 5, 6, 7, hex"#fff4c0")
  L.rect(img, 3, 4, 1, 9, hex"#3a3e48"); L.rect(img, 12, 4, 1, 9, hex"#3a3e48"); L.rect(img, 3, 13, 10, 2, hex"#3a3e48")
  L.outline(img, hex"#14100c")
  return img
end

local function crate()
  local img = L.new(30, 26)
  L.rect(img, 1, 3, 28, 22, hex"#86582e")
  for x = 1, 28, 7 do L.rect(img, x, 3, 1, 22, hex"#5e3c20") end
  L.rect(img, 1, 3, 28, 2, hex"#a8723e"); L.rect(img, 1, 23, 28, 2, hex"#5e3c20")
  L.line(img, 2, 5, 27, 22, hex"#6e4826"); L.line(img, 2, 6, 27, 23, hex"#5e3c20")
  L.outline(img, hex"#140c06")
  return img
end

L.save(mine_floor(), "mine_floor", true)
L.save(mine_wall(), "mine_wall", true)
L.save(beam(), "mine_beam", true)
L.save(rail(), "mine_rail", true)
L.save(ladder(), "mine_ladder", true)
L.save(lamp(), "mine_lamp", true)
L.save(crate(), "mine_crate", true)
