-- Общая библиотека пиксель-арта для Aseprite (v18). Запуск: tools/aseprite/run.ps1
local L = {}
L.OUT = "C:/Claude/herbalist_game/game/art/"
L.SRC = "C:/Claude/herbalist_game/game/tools/aseprite/src/"
local rgba = app.pixelColor.rgba
local floor, sqrt, abs, sin, cos, max, min = math.floor, math.sqrt, math.abs, math.sin, math.cos, math.max, math.min

function L.hex(s, a)
  a = a or 255
  return rgba(tonumber(s:sub(2, 3), 16), tonumber(s:sub(4, 5), 16), tonumber(s:sub(6, 7), 16), a)
end

local function clamp(v) if v < 0 then return 0 elseif v > 255 then return 255 end return floor(v + 0.5) end
function L.mul(c, k)
  return rgba(clamp(app.pixelColor.rgbaR(c) * k), clamp(app.pixelColor.rgbaG(c) * k), clamp(app.pixelColor.rgbaB(c) * k), app.pixelColor.rgbaA(c))
end
function L.mix(a, b, t)
  local function m(x, y) return clamp(x + (y - x) * t) end
  local P = app.pixelColor
  return rgba(m(P.rgbaR(a), P.rgbaR(b)), m(P.rgbaG(a), P.rgbaG(b)), m(P.rgbaB(a), P.rgbaB(b)), m(P.rgbaA(a), P.rgbaA(b)))
end
function L.alpha(c) return app.pixelColor.rgbaA(c) end
function L.withA(c, a)
  local P = app.pixelColor
  return rgba(P.rgbaR(c), P.rgbaG(c), P.rgbaB(c), a)
end

function L.new(w, h) return Image(w, h, ColorMode.RGB) end

function L.put(img, x, y, c)
  if x >= 0 and y >= 0 and x < img.width and y < img.height then img:putPixel(x, y, c) end
end
function L.get(img, x, y)
  if x < 0 or y < 0 or x >= img.width or y >= img.height then return 0 end
  return img:getPixel(x, y)
end
function L.opaque(img, x, y) return L.alpha(L.get(img, x, y)) > 0 end

function L.rect(img, x, y, w, h, c)
  for yy = y, y + h - 1 do for xx = x, x + w - 1 do L.put(img, xx, yy, c) end end
end

function L.line(img, x0, y0, x1, y1, c)
  x0, y0, x1, y1 = floor(x0), floor(y0), floor(x1), floor(y1)
  local dx, dy = abs(x1 - x0), -abs(y1 - y0)
  local sx = x0 < x1 and 1 or -1
  local sy = y0 < y1 and 1 or -1
  local err = dx + dy
  while true do
    L.put(img, x0, y0, c)
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * err
    if e2 >= dy then err = err + dy; x0 = x0 + sx end
    if e2 <= dx then err = err + dx; y0 = y0 + sy end
  end
end

function L.ellipse(img, cx, cy, rx, ry, c, only_empty)
  for y = floor(cy - ry), math.ceil(cy + ry) do
    for x = floor(cx - rx), math.ceil(cx + rx) do
      local dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
      if dx * dx + dy * dy <= 1 then
        if not only_empty or not L.opaque(img, x, y) then L.put(img, x, y, c) end
      end
    end
  end
end

-- Заливка многоугольника (чётно-нечётное правило), pts = {{x,y},...}
function L.poly(img, pts, c, fn)
  local miny, maxy = 1e9, -1e9
  for _, p in ipairs(pts) do miny = min(miny, p[2]); maxy = max(maxy, p[2]) end
  for y = floor(miny), math.ceil(maxy) do
    local xs = {}
    local yc = y + 0.5
    for i = 1, #pts do
      local a, b = pts[i], pts[i % #pts + 1]
      if (a[2] <= yc and b[2] > yc) or (b[2] <= yc and a[2] > yc) then
        xs[#xs + 1] = a[1] + (yc - a[2]) / (b[2] - a[2]) * (b[1] - a[1])
      end
    end
    table.sort(xs)
    for i = 1, #xs - 1, 2 do
      for x = floor(xs[i] + 0.5), floor(xs[i + 1] - 0.5) do
        L.put(img, x, y, fn and fn(x, y) or c)
      end
    end
  end
end

-- Тёмный контур снаружи любой непрозрачной фигуры
function L.outline(img, c)
  local list = {}
  for y = 0, img.height - 1 do
    for x = 0, img.width - 1 do
      if not L.opaque(img, x, y) then
        if L.opaque(img, x - 1, y) or L.opaque(img, x + 1, y) or L.opaque(img, x, y - 1) or L.opaque(img, x, y + 1) then
          list[#list + 1] = {x, y}
        end
      end
    end
  end
  for _, p in ipairs(list) do img:putPixel(p[1], p[2], c) end
end

-- Контур только для пикселей, которые не прозрачны на img, но граничат с прозрачным: перекрашивает край внутри
function L.rim(img, c, keep_alpha)
  local list = {}
  for y = 0, img.height - 1 do
    for x = 0, img.width - 1 do
      if L.opaque(img, x, y) then
        if not (L.opaque(img, x - 1, y) and L.opaque(img, x + 1, y) and L.opaque(img, x, y - 1) and L.opaque(img, x, y + 1)) then
          list[#list + 1] = {x, y}
        end
      end
    end
  end
  for _, p in ipairs(list) do img:putPixel(p[1], p[2], c) end
end

function L.save(img, name, keep_src)
  local s = Sprite(img.width, img.height, ColorMode.RGB)
  s.cels[1].image:drawImage(img)
  if keep_src then s:saveAs(L.SRC .. name .. ".aseprite") end
  s:saveCopyAs(L.OUT .. name .. ".png")
  s:close()
end

-- Простой хэш-шум 0..1 по координатам
function L.hash(x, y, s)
  local n = (x * 374761393 + y * 668265263 + (s or 0) * 2246822519) % 4294967296
  n = ((n ~ (n >> 13)) * 1274126177) % 4294967296
  n = n ~ (n >> 16)
  return (n % 100000) / 100000.0
end

-- Мягкий шум по углу: сумма синусов
function L.angnoise(a, ph, amp)
  return amp * (0.5 * sin(3 * a + ph[1]) + 0.32 * sin(5 * a + ph[2]) + 0.18 * sin(8 * a + ph[3]))
end

return L
