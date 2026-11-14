-- Камни (4 размера), месторождения руд, значки камней/руд, кирка. Рисует Aseprite (v18).
local L = dofile("C:/Claude/herbalist_game/game/tools/aseprite/lib.lua")
local hex = L.hex
local floor, sqrt, sin, cos, max, min = math.floor, math.sqrt, math.sin, math.cos, math.max, math.min

local STONES = {
  cool = {out = hex"#25232e", tones = {hex"#3b3a4a", hex"#52516a", hex"#6f6d87", hex"#9390a9", hex"#bbb7cc"}},
  warm = {out = hex"#2c2622", tones = {hex"#4a4038", hex"#6a5d50", hex"#8a7b6a", hex"#aa9a86", hex"#cfc2ac"}},
  dark = {out = hex"#17151f", tones = {hex"#262535", hex"#383650", hex"#4d4a6c", hex"#68658c", hex"#8b88b0"}},
}
local MOSS = {hex"#3b5732", hex"#5a7d40", hex"#86a85a"}

local function blit(dst, src, ox, oy)
  for y = 0, src.height - 1 do
    for x = 0, src.width - 1 do
      local c = src:getPixel(x, y)
      if L.alpha(c) > 0 then L.put(dst, x + ox, y + oy, c) end
    end
  end
end

-- Один камень в картинку: рисует глыбу w×h с контуром, тенью на земле, гранями, трещинами и мхом
local function rock_into(dst, ox, oy, w, h, seed, pal, moss)
  math.randomseed(seed)
  local cx, cy = w / 2, h * 0.60
  local rx, ryt, ryb = w * 0.49, h * 0.60, h * 0.40
  local t = L.new(w + 2, h + 4)
  L.ellipse(t, w / 2 + 1, h + 1.2, w * 0.46, 2.2, L.hex("#000000", 70))
  -- угловатый контур: многоугольник со срезанным плоским низом
  local nv = max(7, min(12, floor(w / 5)))
  local pts = {}
  for i = 0, nv - 1 do
    local a = (i + (math.random() - 0.5) * 0.5) / nv * 6.2832
    local rr = 0.84 + math.random() * 0.3
    local py = sin(a) * rr
    pts[#pts + 1] = {cx + cos(a) * rr * rx, cy + py * (py < 0 and ryt or ryb)}
  end
  local mimg = L.new(w, h)
  L.poly(mimg, pts, hex"#ffffff")
  -- грани: у каждой своё положение «плоскости» и свой свет
  local K = max(3, min(12, floor(w / 4)))
  local fc = {}
  for i = 1, K do
    local fx, fy = cx + (math.random() - 0.5) * rx * 1.5, cy + (math.random() - 0.5) * (ryt + ryb) * 0.75
    local nx, ny, nz = math.random() * 2 - 1, math.random() * 2 - 1, 0.3 + math.random() * 0.7
    local lv = 0.5 - (nx * 0.5 + ny * 0.7) * 0.5 + nz * 0.18 + (fy < cy and 0.12 or -0.04)
    fc[i] = {fx, fy, lv}
  end
  local inside, fid = {}, {}
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      if L.opaque(mimg, x, y) then
        local bi, bd = 1, 1e9
        for i = 1, K do
          local d = (x - fc[i][1]) ^ 2 + (y - fc[i][2]) ^ 2 * 1.3
          if d < bd then bd = d; bi = i end
        end
        local dome = 0.52 - ((x - cx) / rx * 0.45 + (y - cy) / (y < cy and ryt or ryb) * 0.65) * 0.32
        local lv = dome + (fc[bi][3] - 0.5) * 0.5 + (L.hash(x, y, seed) - 0.5) * 0.06
        local idx = lv < 0.30 and 1 or (lv < 0.44 and 2 or (lv < 0.60 and 3 or (lv < 0.76 and 4 or 5)))
        inside[y * w + x] = idx
        fid[y * w + x] = bi
      end
    end
  end
  local function has(x, y) return x >= 0 and y >= 0 and x < w and y < h and inside[y * w + x] ~= nil end
  -- линии стыка граней: на тёмной стороне стыка пиксель темнее
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local i0 = inside[y * w + x]
      if i0 then
        for _, d in ipairs({{-1, 0}, {0, -1}}) do
          local xx, yy = x + d[1], y + d[2]
          if has(xx, yy) and fid[yy * w + xx] ~= fid[y * w + x] and inside[yy * w + xx] > i0 then
            inside[y * w + x] = max(1, i0 - 1)
          end
        end
      end
    end
  end
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local idx = inside[y * w + x]
      if idx then
        -- светлая кромка сверху-слева, тёмная снизу-справа
        if not has(x - 1, y) or not has(x, y - 1) then idx = min(5, idx + 1) end
        if not has(x + 1, y) or not has(x, y + 1) then idx = max(1, idx - 1) end
        local col = pal.tones[idx]
        if moss and y < h * 0.46 and L.hash(floor(x / 2), floor(y / 2), seed + 7) > 0.60 + (y / h) * 0.3 then
          col = MOSS[idx >= 4 and 3 or (idx >= 2 and 2 or 1)]
        end
        t:putPixel(x + 1, y + 1, col)
      end
    end
  end
  -- трещины
  for k = 1, (w > 20 and 2 or 0) do
    local x = floor(w * (0.25 + math.random() * 0.5))
    local y = floor(h * (0.2 + math.random() * 0.2))
    for s = 1, floor(h * 0.3) do
      if has(x, y) then t:putPixel(x + 1, y + 1, pal.tones[1]) end
      y = y + 1
      x = x + (math.random(3) - 2)
    end
  end
  L.outline(t, pal.out)
  blit(dst, t, ox, oy)
end

local function stone_img(kind, variant, warm)
  local pal = warm and STONES.warm or STONES.cool
  local sizes = {s = {10, 8}, m = {20, 15}, l = {34, 26}}
  if kind == "h" then
    local img = L.new(120, 100)
    local sd = 900 + variant * 31 + (warm and 400 or 0)
    rock_into(img, 16, 3, 88, 74, sd, pal, variant % 2 == 0)
    rock_into(img, 0, 50, 46, 36, sd + 1, pal, false)
    rock_into(img, 68, 48, 50, 40, sd + 2, pal, variant == 1)
    return img
  end
  local sz = sizes[kind]
  local img = L.new(sz[1] + 2, sz[2] + 4)
  rock_into(img, 0, 0, sz[1], sz[2], (kind == "s" and 100 or (kind == "m" and 200 or 300)) + variant * 17 + (warm and 500 or 0), pal, kind ~= "s" and variant == 1)
  return img
end

-- ---------------------------------------------------------------- руды
local ORES = {
  mana = {kind = "crystal", out = "#1a1240", tones = {"#3a2f8c", "#6552d9", "#9887ff", "#dcd5ff"}, glow = "#7a66ff"},
  frost = {kind = "crystal", out = "#0e2a3c", tones = {"#2a6f94", "#4fb2d8", "#9ae6ff", "#eafcff"}, glow = "#6fd8ff"},
  ember = {kind = "crystal", out = "#3a0e0a", tones = {"#8f2316", "#e04a1e", "#ff8a3a", "#ffe08a"}, glow = "#ff7a2a"},
  verdant = {kind = "crystal", out = "#0c2e1a", tones = {"#1f7a3c", "#37b85a", "#86f08a", "#e6ffd0"}, glow = "#5ae37a"},
  void = {kind = "crystal", out = "#0c0814", tones = {"#2a1840", "#4b2a78", "#a03ad0", "#ff8aef"}, glow = "#a03ad0"},
  moonsilver = {kind = "vein", out = "#222a3a", tones = {"#5d6b86", "#98a8c4", "#d4deee", "#ffffff"}, glow = "#c8d8ff"},
  sunstone = {kind = "vein", out = "#3a2406", tones = {"#9a6212", "#dc9a1c", "#ffd65a", "#fff6b8"}, glow = "#ffd04a"},
  star = {kind = "star", out = "#10182e", tones = {"#2c3d78", "#5d7ae0", "#aac4ff", "#ffffff"}, glow = "#cfe0ff"},
}
local ORE_ORDER = {"mana", "frost", "ember", "verdant", "void", "moonsilver", "sunstone", "star"}

local function crystal_into(dst, bx, by, wid, hei, lean, o)
  local c = L.new(dst.width, dst.height)
  local P = {hex(o.tones[1]), hex(o.tones[2]), hex(o.tones[3]), hex(o.tones[4])}
  for tt = 0, hei - 1 do
    local f = tt / hei
    local half = wid / 2 * (f < 0.66 and (1 - f * 0.18) or (1 - ((f - 0.66) / 0.34) ^ 1.15 * 0.92))
    local cxx = bx + lean * f * hei
    local y = by - tt
    for x = floor(cxx - half - 1), math.ceil(cxx + half + 1) do
      if math.abs(x + 0.5 - cxx) <= max(half, 0.45) then
        local rel = (x + 0.5 - cxx) / max(half, 0.5)
        local col = rel < -0.4 and P[3] or (rel < 0.2 and P[2] or P[1])
        if f > 0.7 and rel < 0.1 then col = P[3] end
        if tt == hei - 1 or (f > 0.86 and rel < -0.2) then col = P[4] end
        c:putPixel(x, y, col)
      end
    end
  end
  -- бликовая полоска по левой грани
  for tt = 3, floor(hei * 0.7) do
    local x = floor(bx + lean * (tt / hei) * hei - wid * 0.22 * (1 - (tt / hei) ^ 1.8))
    if L.opaque(c, x, by - tt) and tt % 3 ~= 2 then c:putPixel(x, by - tt, P[4]) end
  end
  L.outline(c, hex(o.out))
  blit(dst, c, 0, 0)
end

local function glow_at(img, cx, cy, r, col)
  for y = floor(cy - r), math.ceil(cy + r) do
    for x = floor(cx - r), math.ceil(cx + r) do
      local d = sqrt((x + 0.5 - cx) ^ 2 + (y + 0.5 - cy) ^ 2)
      if d <= r and not L.opaque(img, x, y) then
        L.put(img, x, y, L.withA(col, floor(70 * (1 - d / r) ^ 1.5)))
      end
    end
  end
end

local function sparkle(img, x, y, col)
  L.put(img, x, y, hex("#ffffff"))
  for _, d in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do L.put(img, x + d[1], y + d[2], L.withA(col, 220)) end
end

local function nugget(img, x, y, w, h, tones)
  L.ellipse(img, x, y, w / 2, h / 2, hex(tones[2]))
  L.ellipse(img, x + 0.6, y + 0.6, w / 2 - 0.4, h / 2 - 0.3, hex(tones[1]), false)
  L.ellipse(img, x - 0.4, y - 0.4, w / 2 - 0.9, h / 2 - 0.7, hex(tones[2]))
  L.put(img, floor(x - w * 0.2), floor(y - h * 0.25), hex(tones[4]))
  L.put(img, floor(x - w * 0.2) + 1, floor(y - h * 0.25), hex(tones[3]))
end

local function ore_img(id, variant)
  local o = ORES[id]
  local W, H = 56, 52
  local img = L.new(W, H)
  rock_into(img, 2, 8, 50, 38, 700 + variant * 13 + #id, STONES.dark, false)
  math.randomseed(1000 + variant * 7 + #id * 3)
  local g = hex(o.glow)
  if o.kind == "crystal" then
    local spots = {{16, 34, 7, 16, -0.25}, {27, 30, 9, 24, 0.0}, {38, 35, 7, 15, 0.22}, {22, 40, 5, 10, -0.1}, {33, 41, 5, 11, 0.12}}
    for _, s in ipairs(spots) do
      local jit = (math.random() - 0.5) * 3
      glow_at(img, s[1] + 2, s[2] - s[4] / 2, s[4] * 0.7, g)
    end
    for _, s in ipairs(spots) do
      local jit = floor((math.random() - 0.5) * 3 + 0.5)
      crystal_into(img, s[1] + 2 + jit, s[2] + 7, s[3] + (variant == 1 and 1 or 0), s[4] + floor((math.random() - 0.5) * 5), s[5] * (variant == 1 and -1 or 1), o)
    end
    sparkle(img, 28, 14 + variant * 2, g)
  elseif o.kind == "vein" then
    local tn = o.tones
    for i = 1, 3 do
      local x0, y0 = 10 + math.random() * 16, 18 + math.random() * 18
      local x1, y1 = x0 + 12 + math.random() * 12, y0 + (math.random() - 0.5) * 10
      L.line(img, x0, y0 + 1, x1, y1 + 1, hex(tn[1]))
      L.line(img, x0, y0, x1, y1, hex(tn[2]))
      L.line(img, x0, y0 - 1, x1, y1 - 1, hex(tn[3]))
    end
    for i = 1, 9 do
      local x, y = 9 + math.random() * 38, 17 + math.random() * 22
      nugget(img, floor(x), floor(y), 5 + math.random() * 4, 4 + math.random() * 3, tn)
    end
    sparkle(img, 22, 20, g)
    sparkle(img, 36, 30, g)
  else
    local c = L.new(W, H)
    for _, s in ipairs({{20, 36, 5, 9, -0.2}, {34, 38, 5, 8, 0.2}, {27, 33, 6, 12, 0}}) do
      glow_at(img, s[1] + 2, s[2] - 3, 8, g)
      crystal_into(img, s[1] + 2, s[2] + 6, s[3], s[4], s[5], o)
    end
    for _, p in ipairs({{14, 22}, {40, 26}, {26, 18}, {34, 40}, {18, 38}, {44, 36}}) do
      sparkle(img, p[1] + (variant == 1 and 2 or 0), p[2], g)
    end
  end
  return img
end

local function ore_icon(id)
  local o = ORES[id]
  local img = L.new(24, 24)
  math.randomseed(77 + #id)
  local g = hex(o.glow)
  if o.kind == "crystal" then
    glow_at(img, 12, 13, 10, g)
    crystal_into(img, 7, 21, 6, 11, -0.25, o)
    crystal_into(img, 16, 21, 5, 10, 0.25, o)
    crystal_into(img, 12, 22, 7, 17, 0, o)
  elseif o.kind == "vein" then
    L.ellipse(img, 12, 16, 9, 6, hex("#3d3c52"))
    L.ellipse(img, 11, 15, 8, 5, hex("#55536e"))
    nugget(img, 9, 13, 7, 6, o.tones)
    nugget(img, 15, 16, 8, 6, o.tones)
    nugget(img, 12, 10, 5, 4, o.tones)
    L.outline(img, hex(o.out))
    sparkle(img, 19, 8, g)
  else
    glow_at(img, 12, 12, 10, g)
    crystal_into(img, 12, 21, 7, 15, 0, o)
    sparkle(img, 5, 6, g)
    sparkle(img, 19, 9, g)
  end
  return img
end

-- ---------------------------------------------------------------- кирка
local function pickaxe_img(w)
  local img = L.new(24, 24)
  local wood = {hex"#4a2c14", hex"#7a4a22", hex"#a8703a"}
  local iron = {hex"#4a5066", hex"#7d879e", hex"#b6c0d6", hex"#e6eefc"}
  -- рукоять
  local ax, ay, bx, by = 3, 22, 16, 8
  L.line(img, ax - 1, ay, bx - 1, by, wood[3])
  L.line(img, ax, ay, bx, by, wood[2])
  L.line(img, ax + 1, ay, bx + 1, by, wood[1])
  L.line(img, ax, ay - 1, bx, by - 1, wood[2])
  -- голова: изогнутое лезвие
  local P0, Q, P2 = {5, 6}, {20, 1}, {21, 18}
  local pts = {}
  for i = 0, 80 do
    local t = i / 80
    local x = (1 - t) ^ 2 * P0[1] + 2 * (1 - t) * t * Q[1] + t * t * P2[1]
    local y = (1 - t) ^ 2 * P0[2] + 2 * (1 - t) * t * Q[2] + t * t * P2[2]
    pts[#pts + 1] = {x, y, t}
  end
  local head = L.new(24, 24)
  for _, p in ipairs(pts) do
    local r = 0.5 + 1.7 * sin(math.pi * p[3]) ^ 0.7
    L.ellipse(head, p[1], p[2], r, r, iron[2])
  end
  -- свет сверху-слева, тень снизу-справа
  local lit = L.new(24, 24)
  for y = 0, 23 do for x = 0, 23 do
    if L.opaque(head, x, y) then
      local c = iron[2]
      if not L.opaque(head, x - 1, y - 1) or not L.opaque(head, x, y - 1) then c = iron[3] end
      if not L.opaque(head, x + 1, y + 1) or not L.opaque(head, x, y + 1) then c = iron[1] end
      if not L.opaque(head, x - 1, y - 1) and not L.opaque(head, x, y - 1) and not L.opaque(head, x - 1, y) then c = iron[4] end
      lit:putPixel(x, y, c)
    end
  end end
  blit(img, lit, 0, 0)
  -- скоба на рукояти под головой
  L.line(img, 14, 10, 17, 10, iron[1])
  L.line(img, 14, 11, 17, 11, iron[2])
  L.outline(img, hex"#241b2c")
  return img
end

-- ---------------------------------------------------------------- запуск
local only = app.params["only"] or "all"
local function want(k) return only == "all" or only == k end

if want("rocks") then
  for v = 0, 2 do
    for _, k in ipairs({"s", "m", "l", "h"}) do
      L.save(stone_img(k, v, false), "rock18_" .. k .. "_" .. v, true)
    end
  end
  for v = 0, 1 do
    for _, k in ipairs({"s", "m", "l", "h"}) do
      L.save(stone_img(k, v, true), "rock18_" .. k .. "_w" .. v, true)
    end
  end
end

if want("ores") then
  for _, id in ipairs(ORE_ORDER) do
    for v = 0, 1 do L.save(ore_img(id, v), "ore18_" .. id .. "_" .. v, true) end
    L.save(ore_icon(id), "icon_ore_" .. id, true)
  end
end

if want("icons") then
  for _, k in ipairs({"s", "m", "l"}) do
    local big = stone_img(k, 0, false)
    local ic = L.new(24, 24)
    local ox, oy = floor((24 - big.width) / 2), 24 - big.height - 1 + (k == "l" and 1 or 0)
    if k == "l" then
      -- большой камень ужимаем под значок
      local sm = L.new(24, 20)
      math.randomseed(5)
      rock_into(sm, 0, 0, 22, 16, 321, STONES.cool, false)
      ic = L.new(24, 24)
      blit(ic, sm, 0, 3)
    else
      blit(ic, big, ox, oy)
    end
    L.save(ic, "icon_stone_" .. k, true)
  end
  L.save(pickaxe_img(), "gear_pickaxe", true)
end
