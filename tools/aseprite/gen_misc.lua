-- Потерявшиеся кошки (перекраска cat.png), значки задания и письма. Рисует Aseprite (v18).
local L = dofile("C:/Claude/herbalist_game/game/tools/aseprite/lib.lua")
local hex = L.hex
local P = app.pixelColor
local floor, min, max = math.floor, math.min, math.max

local RAMPS = {
  ginger = {hex"#4a2410", hex"#a8581e", hex"#e08a38", hex"#f8c880"},
  white = {hex"#5a5e72", hex"#aeb2c4", hex"#e6e8f2", hex"#ffffff"},
  gray = {hex"#23262e", hex"#4e545f", hex"#8a909c", hex"#c4c9d4"},
  calico = {hex"#3a2a22", hex"#8a5a34", hex"#d9a05a", hex"#f6e6c8"},
}

local function recolor(src, ramp, calico)
  local out = L.new(src.width, src.height)
  for y = 0, src.height - 1 do
    for x = 0, src.width - 1 do
      local c = src:getPixel(x, y)
      local a = P.rgbaA(c)
      if a > 0 then
        local r, g, b = P.rgbaR(c), P.rgbaG(c), P.rgbaB(c)
        local mx, mn = max(r, g, b), min(r, g, b)
        local sat = (mx > 0) and (mx - mn) / mx or 0
        if (g > b + 20) or (r > b + 25) then
          out:putPixel(x, y, c) -- глаза и язык остаются
        else
          local lum = (r * 0.3 + g * 0.59 + b * 0.11)
          local t = min(1, (lum / 120) ^ 0.75)
          local rp = ramp
          if calico and L.hash(floor((x % 36) / 5), floor(y / 5), 4) > 0.55 then rp = RAMPS.white end
          local idx = t < 0.2 and 1 or (t < 0.5 and 2 or (t < 0.82 and 3 or 4))
          out:putPixel(x, y, L.withA(rp[idx], a))
        end
      end
    end
  end
  return out
end

local function scroll_icon()
  local img = L.new(24, 24)
  L.rect(img, 6, 4, 12, 16, hex"#e8d9b0")
  L.rect(img, 6, 4, 12, 1, hex"#fff2cc")
  L.rect(img, 17, 5, 1, 15, hex"#b89c68")
  for yy = 8, 17, 3 do L.rect(img, 8, yy, 8, 1, hex"#8a6a3a") end
  L.rect(img, 8, 6, 5, 1, hex"#8a6a3a")
  -- свитки сверху и снизу
  L.rect(img, 4, 2, 16, 3, hex"#c9a45a"); L.rect(img, 4, 2, 16, 1, hex"#ecd088")
  L.rect(img, 4, 19, 16, 3, hex"#c9a45a"); L.rect(img, 4, 21, 16, 1, hex"#8a6a30")
  L.ellipse(img, 4, 3.5, 1.5, 2, hex"#8a6a30"); L.ellipse(img, 20, 3.5, 1.5, 2, hex"#8a6a30")
  L.ellipse(img, 4, 20.5, 1.5, 2, hex"#8a6a30"); L.ellipse(img, 20, 20.5, 1.5, 2, hex"#8a6a30")
  -- красная печать
  L.ellipse(img, 15, 17, 2.5, 2.5, hex"#c03a30"); L.put(img, 14, 16, hex"#ff8a7a")
  L.outline(img, hex"#3a2a14")
  return img
end

local function letter_icon()
  local img = L.new(24, 24)
  L.rect(img, 3, 6, 18, 13, hex"#f1e6c8")
  L.rect(img, 3, 6, 18, 1, hex"#fff8e0")
  -- уголки конверта
  for k = 0, 8 do L.put(img, 4 + k, 7 + k, hex"#c8b484"); L.put(img, 19 - k, 7 + k, hex"#c8b484") end
  for k = 0, 8 do L.put(img, 4 + k, 18 - k, hex"#d9c898"); L.put(img, 19 - k, 18 - k, hex"#d9c898") end
  L.ellipse(img, 12, 13, 2.6, 2.6, hex"#3a68b8"); L.put(img, 11, 12, hex"#8ab4f0")
  L.outline(img, hex"#3a2a14")
  return img
end

local cat = Image{fromFile = L.OUT .. "cat.png"}
L.save(recolor(cat, RAMPS.ginger), "cat_lost_ginger", true)
L.save(recolor(cat, RAMPS.white), "cat_lost_white", true)
L.save(recolor(cat, RAMPS.gray), "cat_lost_gray", true)
L.save(recolor(cat, RAMPS.calico, true), "cat_lost_calico", true)
L.save(scroll_icon(), "icon_scroll", true)
L.save(letter_icon(), "icon_letter", true)
