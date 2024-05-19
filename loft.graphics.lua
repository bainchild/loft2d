---@diagnostic disable: unused-local, deprecated
local Canvas = require("loft._classes.Canvas")
local Font = require("loft._classes.Font")
local Image = require("loft._classes.Image")
local ImageData = require("loft._classes.ImageData")
local log = require("loft._logging"):clone("loft.graphics")
local love = require("loft")
love.graphics = {}
local dc_r, dc_g, dc_b, dc_a = 1, 1, 1, 1
local bg_r, bg_g, bg_b, bg_a = 0, 0, 0, 1
local unpack = unpack or table.unpack
local default_filter_mode = "nearest"
local scissor, blendmode, color_component_mask, wireframe = nil, "alphamultiply", { true, true, true, true }, false
local transform_ox, transform_oy, transform_sx, transform_sy, transform_rot = 0, 0, 1, 1, 0
local line_mode, point_size, line_size = "smooth", 1, 0.25
local graph_stack = {}
local cg_works = false
-- local cg_works = pcall(function()
--    collectgarbage("stop")
--    collectgarbage("restart")
-- end)
local font
local canvas
local screen
---@diagnostic disable-next-line: undefined-field
local shallow_clone = table.clone
   or function(a)
      local n = {}
      for i, v in next, a do
         n[i] = v
      end
      return n
   end
-- local perf_clk = love._provider.thread.time
-- local perf_stack = {}
-- local perf_name,perf_time = nil,0
local function perf_start(name)
   -- local perf_t = perf_time
   -- if perf_name~=nil then
   --    perf_stack[#perf_stack+1] = {perf_name,perf_t}
   -- end
   -- perf_name,perf_time = name,perf_clk()
end
local function perf_end()
   -- local nd = perf_clk()
   -- local tim = nd-perf_time
   -- log.dbg("_"..perf_name,tim)
   -- if #perf_stack>0 then
   --    perf_name,perf_time = unpack(table.remove(perf_stack,#perf_stack))
   -- else
   --    perf_name,perf_time = nil,0
   -- end
   -- return tim
end
local function deep_clone(a)
   local n = {}
   for i, v in next, a do
      if type(v) == "table" then
         n[i] = deep_clone(v)
      else
         n[i] = v
      end
   end
   return n
end
local floor = math.floor
local function round(a)
   local rem = (a % 1)
   if rem >= 0.5 then
      return a - rem + 1
   end
   return a - rem
end
local function clampf(a, b, c)
   if a > c then
      return c
   end
   if a < b then
      return b
   end
   return round(a)
end
local function clampc(a, b, c)
   if a > c then
      return c
   end
   if a < b then
      return b
   end
   return floor(a+.5)
end
local function clamp(a, b, c)
   if a > c then
      return c
   end
   if a < b then
      return b
   end
   return a
end
-- point box check
local function bounds(px, py, box, boy, sx, sy)
   if px > box + sx or px < box then
      return false
   end
   if py > boy + sy or py < boy then
      return false
   end
   return true
end
local function pxv_unit(format, r, g, b, a)
   r, g, b, a = r or 0, g or 0, b or 0, a or 0
   if format:sub(-1) == "8" then
      return clamp(r / 255, 0, 1), clamp(g / 255, 0, 1), clamp(b / 255, 0, 1), clamp(a / 255, 0, 1)
   elseif format:sub(-2) == "16" then
      return clamp(r / 65535, 0, 1), clamp(g / 65535, 0, 1), clamp(b / 65535, 0, 1), clamp(a / 65535, 0, 1)
   elseif format:sub(-3) == "16f" then
      return r / 65535, g / 65535, b / 65535, a / 65535
   elseif format:sub(-2) == "32" then
      local max = 2 ^ 31
      return clamp(r / max, 0, 1), clamp(g / max, 0, 1), clamp(b / max, 0, 1), clamp(a / max, 0, 1)
   elseif format:sub(-3) == "32f" then
      local max = 2 ^ 31
      return r / max, g / max, b / max, a / max
   end
   return r, g, b, a
end
local function pxv_notunit(format, r, g, b, a)
   r, g, b, a = r or 0, g or 0, b or 0, a or 0
   if format:sub(-1) == "8" then
      return clampf(r * 255, 1, 255), clampf(g * 255, 1, 255), clampf(b * 255, 1, 255), clampf(a * 255, 1, 255)
   elseif format:sub(-2) == "16" then
      return clampf(r * 65535, 1, 65535),
         clampf(g * 65535, 1, 65535),
         clampf(b * 65535, 1, 65535),
         clampf(a * 65535, 1, 65535)
   elseif format:sub(-3) == "16f" then
      return r * 65535, g * 65535, b * 65535, a * 65535
   elseif format:sub(-2) == "32" then
      local max = 2 ^ 31
      return clampf(r * max, 1, max), clampf(g * max, 1, max), clampf(b * max, 1, max), clampf(a * max, 1, max)
   elseif format:sub(-3) == "32f" then
      local max = 2 ^ 31
      return r * max, g * max, b * max, a * max
   end
   return r, g, b, a
end
local function rotate(angle, x, y, ox, oy)
   local sin, cos = math.sin(angle), math.cos(angle)
   local relx, rely = (x - ox), (y - oy)
   return (relx * cos) - (rely * sin) + ox, (relx * sin) + (rely * cos) + oy
end
local function rotate_origin(angle, x, y)
   local sin, cos = math.sin(angle), math.cos(angle)
   return x * cos - y * sin, x * sin + y * cos
end
local function addpx(...)
   local sumr, sumg, sumb, sumw = 0, 0, 0, 0
   for _, px in next, { ... } do
      sumr = sumr + px[1]
      sumg = sumg + px[2]
      sumb = sumb + px[3]
      sumw = sumw + px[4]
   end
   return { sumr, sumg, sumb, sumw }
end
local function mulpx(a, b)
   if type(b) == "table" then
      return {
         a[1] * b[1],
         a[2] * b[2],
         a[3] * b[3],
         a[4] * b[4],
      }
   else
      return {
         a[1] * b,
         a[2] * b,
         a[3] * b,
         a[4] * b,
      }
   end
end
local function scale(canva, xs, ys, mode)
   -- print(">",xs,ys)
   perf_start("scale")
   if mode == nil then
      mode = default_filter_mode
   end
   if xs == 1 and ys == 1 then
      return canva
   end
   local width, height = canva:getDimensions()
   local format = canva:getFormat()
   local newcan = Canvas:_new(round(width * xs), round(height * ys), 1, format)
   local width2, height2 = newcan:getDimensions()
   local newpx = rawget(newcan, "_pxarray")
   local px = rawget(canva, "_pxarray")
   log.dbg(
      "scale",
      "scale mode: %s, scaling by %f x %f (new size %d x %d)",
      mode,
      xs,
      ys,
      round(width * xs),
      round(height * ys)
   )
   if mode == "nearest" then
      for x = 1, width2 do
         for y = 1, height2 do
            -- this is nearest neighbor I think

            local rxxs, rxxy = floor((x - 1) * xs) + 1, floor((y - 1) * ys) + 1
            if px[rxxs] ~= nil and px[rxxs][rxxy] ~= nil then
               newpx[x][y] = px[rxxs][rxxy]
            end
         end
      end
   elseif mode == "linear" then
      -- based upon https://en.wikipedia.org/wiki/Bilinear_interpolation#Weighted_mean
      -- TODO: implement it (currently bugged):
      -- p1,p2,p3,p4 are the surrounding pixels to the one currently being scaled
      -- then you just interpolate between them
      -- it's simpler when you convert it to unit square, so do that as well
      -- p2---p4
      -- |     |
      -- p1---p3
      local x1, y1, x2, y2, x3, y3, x4, y4 = 1, height, 1, 1, width, height, width, 1
      local p1, p2, p3, p4 =
         { pxv_unit(format, unpack(px[x1][y1])) },
         { pxv_unit(format, unpack(px[x2][y2])) },
         { pxv_unit(format, unpack(px[x3][y3])) },
         { pxv_unit(format, unpack(px[x4][y4])) }
      local dival = ((x2 - x1) * (y2 - y1))
      if dival == 0 then
         dival = 1
      end
      for x = 1, width2 do
         for y = 1, height2 do
            local wc1, wc2, wc3, wc4 =
               (x2 - x) * (y2 - y) / dival,
               (x2 - x) * (y - y1) / dival,
               (x - x1) * (y2 - y) / dival,
               (x - x1) * (y - y1) / dival
            -- io.stderr:write(wc1..", "..wc2..", "..wc3..", "..wc4.."\n")
            -- local rxxs, rxxy = floor(x / xs), floor(y / ys)
            -- local nearest = (px[rxxs] and {pxv_unit(format,unpack(px[rxxs][rxxy]))}) or {1,1,1,1}
            newpx[x][y] =
               { pxv_notunit(format, unpack(addpx(mulpx(p1, wc1), mulpx(p2, wc2), mulpx(p3, wc3), mulpx(p4, wc4)))) }
            -- { pxv_notunit(format, unpack(mulpx(nearest,addpx(mulpx(p1, wc1), mulpx(p2, wc2), mulpx(p3, wc3), mulpx(p4, wc4))))) }
         end
      end
   end
   perf_end()
   return newcan
end
local function transform(canva, bonus_rot, rox, roy)
   -- NEVER_TODO_PROBABLY: shear
   perf_start("transform")
   local width, height = canva:getDimensions()
   local newcan = Canvas:_new(width, height, 1, canva:getFormat(), nil, { pxv_notunit(canva:getFormat(), 0, 0, 0, 0) })
   local newpx = rawget(newcan, "_pxarray")
   local px = rawget(canva, "_pxarray")
   for x = 1, width do
      for y = 1, height do
         local nx, ny = (x + transform_ox) * transform_sx, (y + transform_oy) * transform_sy
         -- print("B4 ROTATION",nx,ny)
         if rox == nil and roy == nil then
            nx, ny = rotate_origin(transform_rot + (bonus_rot or 0), nx, ny)
         else
            nx, ny = rotate(transform_rot + (bonus_rot or 0), nx, ny, rox or 0, roy or 0)
         end
         nx, ny = round(nx), round(ny)
         -- TODO: this may be related to scaling up/down
         -- print("A4 ROTATION",nx,ny,"(",width,height,")")
         if not (nx > width or ny > height or nx < 1 or ny < 1) then
            -- newpx[x][y] = px[nx][ny]
            newpx[nx][ny] = px[x][y]
         end
      end
   end
   perf_end()
   return newcan
end
local function translate(canva, x, y)
   local width, height = canva:getDimensions()
   local newcan = canva:_clone_nc({ pxv_notunit(canva:getFormat(), 0, 0, 0, 0) })
   local newpx = rawget(newcan, "_pxarray")
   local px = rawget(canva, "_pxarray")
   for x2 = 1, width do
      for y2 = 1, height do
         local nx, ny = round(x2 + x), round(y2 + y)
         if not (nx > width or ny > height or nx < 1 or ny < 1) then
            newpx[x][y] = px[x][y]
         end
      end
   end
   return newcan
end
local function place(canva, new_width, new_height, nx, ny)
   local ow, oh = canva:getDimensions()
   local px = rawget(canva, "_pxarray")
   local newcan =
      Canvas:_new(new_width, new_height, 1, canva:getFormat(), nil, { pxv_notunit(canva:getFormat(), 0, 0, 0, 0) })
   local newpx = rawget(newcan, "_pxarray")
   if nx > new_width or ny > new_height or nx + new_width < 1 or ny + new_height < 1 then
      -- skipping!!!!!@@@
      return newcan
   end
   for x = 1, new_width do
      for y = 1, new_height do
         if x >= nx and y >= ny and x < nx + ow and y < ny + oh then
            -- print(x,y,nx,ny,"=",x-nx+1,y-ny+1)
            if not (newpx[x] == nil or px[x - nx + 1] == nil) then
               newpx[x][y] = px[x - nx + 1][y - ny + 1]
            end
         end
      end
   end
   return newcan
end
-- TODO: blending mode switching
-- note:
-- blendam = blend with "alphamultiply"
-- blendpm = blend with "premultiplied"
---@diagnostic disable: unused-function
local blendam_alphamultiply = function(src_1, src_2, src_3, src_4, dst_1, dst_2, dst_3, dst_4)
   local iv_alpha = 1 - src_4
   return (dst_1 * iv_alpha + src_1 * src_4),
      (dst_2 * iv_alpha + src_2 * src_4),
      (dst_3 * iv_alpha + src_3 * src_4),
      (dst_4 * iv_alpha + src_4)
end
local blendam_replace = function(src_1, src_2, src_3, src_4, dst_1, dst_2, dst_3, dst_4)
   if src_4 > dst_4 then
      return src_1, src_2, src_3, src_4
   else
      return dst_1, dst_2, dst_3, dst_4
   end
end
local blendam = blendam_alphamultiply
---@diagnostic enable: unused-function
local function blend(canva, canvb, bx, by, copy)
   -- assumes that canva is bigger than or equal to canvb
   -- clips canvb with canva
   -- TODO: this function's taking a while (from loft.graphics.print)
   -- log.dbg("blend","dimensions: %dx%d, format: %s",canva:getWidth(),canva:getHeight(),canva:getFormat())
   perf_start("blend")
   local width, height = canva:getWidth(), canva:getHeight()
   local bwidth, bheight = canvb:getWidth(), canvb:getHeight()
   local cf = canva:getFormat()
   local format_max
   if cf:sub(-1) == "8" then
      format_max = 255
   elseif cf:sub(-2) == "16" then
      format_max = 65535
   elseif cf:sub(-2) == "32" then
      format_max = 2 ^ 31
   end
   local canvr
   if copy then
      canvr = canva
   else
      canvr = canva:_clone_nc({ pxv_notunit(cf, 0, 0, 0, 0) })
   end
   local px, apx, bpx = rawget(canvr, "_pxarray"), rawget(canva, "_pxarray"), rawget(canvb, "_pxarray")
   for x = 1, width do
      for y = 1, height do
         if (bwidth == width and bheight == height) or bounds(x, y, bx, by, bwidth - 1, bheight - 1) then
            -- blending!!!
            local src = bpx[x - bx + 1][y - by + 1]
            if type(src) == "table" then
               local dst = apx[x][y]
               if format_max == nil then
                  px[x][y] = { blendam(src[1], src[2], src[3], src[4], dst[1], dst[2], dst[3], dst[4]) }
               else
                  local res_1, res_2, res_3, res_4 = blendam(
                     src[1] / format_max,
                     src[2] / format_max,
                     src[3] / format_max,
                     src[4] / format_max,

                     dst[1] / format_max,
                     dst[2] / format_max,
                     dst[3] / format_max,
                     dst[4] / format_max
                  )
                  px[x][y] = {
                     clampf(res_1 * format_max, 0, format_max),
                     clampf(res_2 * format_max, 0, format_max),
                     clampf(res_3 * format_max, 0, format_max),
                     clampf(res_4 * format_max, 0, format_max),
                  }
               end
               -- local cpx = px[x][y]
               -- print(("(%d,%d,%d,%d) + (%d,%d,%d,%d) = (%d,%d,%d,%d)"):format(
               --    clr2[1],clr2[2],clr2[3],clr2[4],
               --    clr1[1],clr1[2],clr1[3],clr1[4],
               --    cpx[1],cpx[2],cpx[3],cpx[4]))
            else
               px[x][y] = src
            end
         else
            px[x][y] = apx[x][y]
         end
      end
   end
   perf_end()
   return canvr
end
local function tint(canva, color)
   perf_start("tint")
   local cf = canva:getFormat()
   local res, w, h = canva:_clone_nc({ pxv_notunit(cf, 0, 0, 0, 0) }), canva:getDimensions()
   local rpx, px = rawget(res, "_pxarray"), rawget(canva, "_pxarray")
   local format_max
   if cf:sub(-1) == "8" then
      format_max = 255
   elseif cf:sub(-2) == "16" then
      format_max = 65535
   elseif cf:sub(-2) == "32" then
      format_max = 2 ^ 31
   end
   if type(color) == "number" then
      for x = 1, w do
         for y = 1, h do
            local v = px[x][y] * color
            if format_max then
               rpx[x][y] = clampf(v, 0, format_max)
            else
               rpx[x][y] = v
            end
         end
      end
   else
      for x = 1, w do
         for y = 1, h do
            local v = px[x][y]
            local al = v[4] / format_max
            local bl = {
               (v[1] / format_max) * (color[1] / format_max),
               (v[2] / format_max) * (color[2] / format_max),
               (v[3] / format_max) * (color[3] / format_max),
               al,
            }
            if format_max then
               rpx[x][y] = {
                  clampf(bl[1] * format_max, 0, format_max),
                  clampf(bl[2] * format_max, 0, format_max),
                  clampf(bl[3] * format_max, 0, format_max),
                  clampf(bl[4] * format_max, 0, format_max),
               }
            else
               rpx[x][y] = {
                  bl[1],
                  bl[2],
                  bl[3],
                  bl[4],
               }
            end
         end
      end
   end
   perf_end()
   return res
end
local function copy(canva, canvb, noc)
   local ax, ay = canva:getDimensions()
   if ax ~= canvb:getWidth() or ay ~= canvb:getHeight() then
      return nil
   end
   local aform, bform = canva:getFormat(), canvb:getFormat()
   if aform == bform then
      local opx = rawget(canvb, "_pxarray")
      if noc then
         rawset(canva, "_pxarray", opx)
      else
         rawset(canva, "_pxarray", deep_clone(opx))
      end
   else
      local apx, bpx = rawget(canva, "_pxarray"), rawget(canvb, "_pxarray")
      for x = 1, ax do
         for y = 1, ay do
            local pv = bpx[x][y]
            if type(pv) == "table" then
               apx[x][y] = { pxv_notunit(aform, pxv_unit(bform, (unpack or table.unpack)(pv))) }
            else
               apx[x][y] = pxv_notunit(aform, pxv_unit(bform, pv))
            end
         end
      end
   end
   if noc then
      canvb:release()
   end
   return canva
end
love.graphics._scale = scale
love.graphics._place = place
love.graphics._copy = copy
love.graphics._transform = transform
love.graphics._blend = blend
love.graphics._tint = tint
function love.graphics.newImage(file, settings)
   if type(file) == "table" and rawget(file, "_isAobject") and file:typeOf("Data") then
      if file:typeOf("ImageData") then
         return Image:_new("2d", file, settings)
      else
         file = file:getString()
      end
   elseif type(file) == "string" then
      file = assert(love.filesystem.read(file))
   end
   return Image:_new("2d", ImageData:_decode(file), settings)
end
function love.graphics.setDefaultFilter(mode)
   default_filter_mode = mode
end
function love.graphics.setFont(fon)
   font = fon
end
function love.graphics.getFont()
   return font
end
-- filename, size, hinting, dpiscale: truetype
-- filename, imagefilename: BMFont + image
-- size, hinting, dpiscale: inbuilt
local default_font = require("loft._font.Default")
function love.graphics.newFont(size, hinting, dpiscale)
   if type(size) == "number" or size == nil then
      return Font:_newBMTable(default_font, size, hinting, dpiscale)
   end
   error("uhhhh")
end
font = love.graphics.newFont(16)
function love.graphics.isActive()
   return love.graphics.isCreated() and (canvas or screen)
end
function love.graphics.isCreated()
   return love.window and love.window.isOpen and love.window.isOpen()
end
function love.graphics.setScissor() end
function love.graphics.reset()
   assert(love.graphics.isActive(), "not active...")
   dc_r, dc_g, dc_b, dc_a = 1, 1, 1, 1
   bg_r, bg_g, bg_b, bg_a = 0, 0, 0, 0
   scissor, blendmode, color_component_mask, wireframe = nil, "alphamultiply", { true, true, true, true }, false
   transform_ox, transform_oy, transform_sx, transform_sy, transform_rot = 0, 0, 1, 1, 0
   line_mode, point_size, line_size = "smooth", 1, 0.25
end
function love.graphics.origin()
   assert(love.graphics.isActive(), "not active...")
   transform_ox, transform_oy, transform_sx, transform_sy, transform_rot = 0, 0, 1, 1, 0
end
function love.graphics.rotate(n)
   assert(love.graphics.isActive(), "not active...")
   transform_rot = transform_rot + n
end
function love.graphics.translate(x, y)
   assert(love.graphics.isActive(), "not active...")
   transform_ox, transform_oy = transform_ox + x, transform_oy + y
end
function love.graphics.scale(sx, sy)
   assert(love.graphics.isActive(), "not active...")
   -- I think?
   if sy == nil then
      sy = sx
   end
   transform_ox, transform_oy = transform_ox * sx, transform_oy * sy
   transform_sx, transform_sy = transform_sx * sx, transform_sy * sy
end
function love.graphics.push()
   graph_stack[#graph_stack+1] = {
      dc_r, dc_g, dc_b, dc_a,
      bg_r, bg_g, bg_b, bg_a,
      default_filter_mode,
      scissor, blendmode, color_component_mask, wireframe,
      transform_ox, transform_oy, transform_sx, transform_sy, transform_rot,
      line_mode, point_size, line_size
   }
end
function love.graphics.pop()
   if #graph_stack == 0 then
      love.graphics.reset()
   else
      dc_r, dc_g, dc_b, dc_a,
      bg_r, bg_g, bg_b, bg_a,
      default_filter_mode,
      scissor, blendmode, color_component_mask, wireframe,
      transform_ox, transform_oy, transform_sx, transform_sy, transform_rot,
      line_mode, point_size, line_size = unpack(table.remove(graph_stack,#graph_stack))
   end
end
function love.graphics.clear(r, g, b, a, stencil, depth)
   assert(love.graphics.isActive(), "not active...")
   if r == nil then
      r, g, b, a = 0, 0, 0, 1
   end -- haha get side effected!!!!
   if a == nil then
      a = 1
   end
   local canva = canvas or screen
   local px, form = rawget(canva, "_pxarray"), rawget(canva, "_pxformat")
   for x = 1, canva:getWidth() do
      for y = 1, canva:getHeight() do
         if type(px[x][y]) == "table" then
            px[x][y] = { pxv_notunit(form, r, g, b, a) }
         else
            px[x][y] = pxv_notunit(form, r, g, b, a)
         end
      end
   end
end
love.graphics.discard = love.graphics.clear
local screenshot_queued = false
local screenshot_arg
function love.graphics.present()
   assert(love.graphics.isActive(), "not active...")
   local img
   if love._provider and love._provider.display and love._provider.display.update then
      img = screen:newImageData()
      love._provider.display.update(img)
   end
   if screenshot_queued then
      screenshot_queued = false
      local param = screenshot_arg
      screenshot_arg = nil
      img = img or screen:newImageData()
      if type(param) == "string" then
         if love.filesystem.write then
            assert(love.filesystem.write(param, img:_guess_encode(param)))
         end
      elseif type(param) == "function" then
         param(img)
      elseif type(param) == "table" and rawget(param, "_isAobject") and param:typeOf("Channel") then
         param:push(img)
      end
   end
end
function love.graphics.captureScreenshot(a)
   assert(love.graphics.isActive(), "not active...")
   screenshot_queued = true
   screenshot_arg = a
end
function love.graphics.getWidth()
   assert(love.graphics.isActive(), "not active...")
   local canva = canvas or screen
   return canva:getWidth()
end
function love.graphics.getHeight()
   assert(love.graphics.isActive(), "not active...")
   local canva = canvas or screen
   return canva:getHeight()
end
function love.graphics.getDimensions()
   assert(love.graphics.isActive(), "not active...")
   local canva = canvas or screen
   return canva:getDimensions()
end
function love.graphics.getBackgroundColor()
   return bg_r, bg_g, bg_b, bg_a
end
function love.graphics.getColor()
   return dc_r, dc_g, dc_b, dc_a
end
function love.graphics.setBackgroundColor(r, g, b, a)
   bg_r, bg_g, bg_b, bg_a = r, g, b, a or 1
end
function love.graphics.setColor(r, g, b, a)
   if type(r) == "table" then
      r, g, b, a = unpack(r)
   end
   dc_r, dc_g, dc_b, dc_a = r, g, b, a or 1
end
function love.graphics.setCanvas(canva)
   canvas = canva or screen
end
function love.graphics.setLineWidth(size)
   line_size = size
end
function love.graphics.setLineStyle()
   -- style it??
end
function love.graphics.setPointSize(size)
   point_size = size
end
function love.graphics.print(text, font2, x, y, r, sx, sy, ox, oy)
   if not (type(font2) == "table" and rawget(font2, "_isAobject")) then
      -- font overload
      x, y, r, sx, sy, ox, oy = font2, x, y, r, sx, sy, ox
      font2 = nil
   end
   -- TODO: performance. something other than blend (copy opt.) and place is causing significant slowage
   -- maybe collectgarbage has overhead unrelated to the cost of collecting the garbage?
   -- cause I don't think .08+.06 >= .2
   assert(love.graphics.isActive(), "not active...")
   perf_start("print")
   if cg_works then
      collectgarbage("stop")
   end
   local target = (canvas or screen)
   local format = target:getFormat()
   local allt = target:_clone_nc({ pxv_notunit(format, 0, 0, 0, 0) })
   local aw, ah = allt:getWidth(), allt:getHeight()
   local filter = (font2 or font):getFilter()
   local sf = (font2 or font):_getScalingFactor()
   local sf2 = 1 / sf
   -- if true then
   --    local was_canvas = canvas ~= nil
   --    local base = (font2 or font):getBaseline()
   --    local lineheight = (font2 or font):getLineHeight()
   --    canvas = allt
   --    local color = { love.graphics.getColor() }
   --    love.graphics.setColor(1, 0, 0, 1)
   --    for i=1,50 do
   --       local xpos = (lineheight*(i-1)-base)*sf
   --       love.graphics.line(1, xpos, aw, xpos)
   --    end
   --    love.graphics.setColor(color)
   --    if was_canvas then
   --       canvas = target
   --    else
   --       canvas = nil
   --    end
   -- end
   local scout
   if cg_works then
      scout = collectgarbage("count")
   end
   log.dbg("print", "scaling factor: %f (%f)", sf, sf2)
   for i, v in next, (font2 or font):_arrange(text) do
      perf_start("plbody")
      local img = v.glyph:_getImage()
      local w, h, px = img:_getpxarray("rgba8")
      local newc = place(
         scale(Canvas:_new(w, h, 1, "rgba8", px), sf2, sf2, filter),
         aw,
         ah,
         round(v.x * sf) + 1,
         round(v.y * sf) + 1
      )
      local blendered = blend(allt, newc, 1, 1, true)
      if cg_works and i % 10 == 0 then
         if collectgarbage("count") / scout > 6 then
            collectgarbage()
         else
            repeat
               collectgarbage("step")
            until collectgarbage("count") / scout < 4
         end
         collectgarbage("stop")
      end
      -- copy(allt, blendered, true)
      perf_end()
   end
   if cg_works then
      collectgarbage("restart")
   end
   -- copy(
   --    target,
   blend(
      target,
      transform(
         place(
            (sx and (sy or sx ~= 1) and scale(allt, sx, sy or sx) or allt),
            target:getWidth(),
            target:getHeight(),
            round(x + 1),
            round(y + 1)
         ),
         r,
         ox,
         oy
      ),
      1,
      1,
      -- )
      true
   )

   perf_end()
end
function love.graphics.printf(text, font2, x, y, limit, align, r, sx, sy, ox, oy)
   if not (type(font2) == "table" and rawget(font2, "_isAobject")) then
      x, y, limit, align, r, sx, sy, ox, oy = font2, x, y, limit, align, r, sx, sy, ox
      font2 = nil
   end
   -- TODO: same problem as with love.graphics.print
   assert(love.graphics.isActive(), "not active...")
   perf_start("printf")
   if cg_works then
      collectgarbage("stop")
   end
   local target = (canvas or screen)
   local format = target:getFormat()
   local allt = target:_clone_nc({ pxv_notunit(format, 0, 0, 0, 0) })
   local aw, ah = allt:getWidth(), allt:getHeight()
   local scout = collectgarbage("count")
   local filter = (font2 or font):getFilter()
   local sf = 1 / (font2 or font):_getScalingFactor()
   log.dbg("printf", "scaling factor: %f", sf)
   for i, v in next, (font2 or font):_arrange(text, limit, align) do
      perf_start("pflbody")
      local img = v.glyph:_getImage()
      local w, h, px = img:_getpxarray("rgba8")
      local newc = place(
         scale(Canvas:_new(w, h, 1, "rgba8", px), sf, sf, filter),
         aw,
         ah,
         round(v.x / sf) + 1,
         round(v.y / sf) + 1
      )
      local blendered = blend(allt, newc, 1, 1, true)
      if cg_works and i % 10 == 0 then
         if collectgarbage("count") / scout > 6 then
            collectgarbage()
         else
            repeat
               collectgarbage("step")
            until collectgarbage("count") / scout < 4
         end
         collectgarbage("stop")
      end
      -- copy(allt, blendered, true)
      perf_end()
   end
   if cg_works then
      collectgarbage("restart")
   end
   blend(
      target,
      transform(
         place(
            (sx and scale(allt, sx, sy or sx) or allt),
            target:getWidth(),
            target:getHeight(),
            round(x + 1),
            round(y + 1)
         ),
         r,
         ox,
         oy
      ),
      1,
      1,
      -- )
      true
   )
   perf_end()
end
-- no shears here!!!
function love.graphics.draw(drawable, x, y, r, sx, sy, ox, oy)
   assert(love.graphics.isActive(), "not active...")
   local target = (canvas or screen)
   local w, h, px = drawable:_getpxarray("rgba8")
   local tined = tint(Canvas:_new(w, h, 1, "rgba8", px), { pxv_notunit("rgba8", dc_r, dc_g, dc_b, dc_a) })
   -- place(target,target:getWidth(),target:getHeight(),x+1,y+1)
   copy(
      target,
      blend(
         target,
         transform(place(tined, target:getWidth(), target:getHeight(), round(x + 1), round(y + 1)), r, ox, oy),
         1,
         1
      ),
      true
   )
end
function love.graphics.circle(mode, px, py, radius, _segments)
   px,py=px+1,py+1
   local target = (canvas or screen)
   local width,height = target:getDimensions()
   local tlx, tly = px-radius,py-radius
   local canv = target:_clone_nc({ pxv_notunit(target:getFormat(), 0, 0, 0, 0) })
   local pix = rawget(canv, "_pxarray")
   local conv_color = { pxv_notunit(canv:getFormat(), dc_r, dc_g, dc_b, dc_a) }
   -- local bboxx,bboxy = px-radius, py-radius
   local radiussq = radius^2
   local diameter = radius*2
   if mode=="fill" then
      for x=0,diameter do
         for y=0,diameter do
            local nx,ny = round(tlx+x),round(tlx+y)
            if (x-radius)^2+(y-radius)^2<=radiussq and bounds(nx,ny,1,1,width,height) then
               pix[nx][ny] = conv_color
            end
         end
      end
      -- for x=clampf(bboxx,1,width),clampc(px+radius,1,width) do
      --    for y=clampf(bboxy,1,height),clampc(py+radius,1,height) do
      --       if bounds(x,y,bboxx,bboxy,diameter,diameter) and x^2+y^2<=radius then
      --          pix[x][y] = conv_color
      --       end
      --    end
      -- end
   elseif mode=="line" then
      -- for x=clampf(bboxx,1,width),clampc(px+radius,1,width) do
      --    for y=clampf(bboxy,1,height),clampc(py+radius,1,height) do
      --       local dist = x^2+y^2
      --       if bounds(x,y,bboxx,bboxy,diameter,diameter) and dist<=radius+.4 and dist>=radius-.4 then
      --          pix[x][y] = conv_color
      --       end
      --    end
      -- end
   end
   copy(target, blend(target, transform(canv), 1, 1), true)
end
function love.graphics.line(x1, y1, x2, y2)
   -- TODO: overloads
   x1, y1, x2, y2 = x1 + 1, y1 + 1, x2 + 1, y2 + 1
   if line_size == 0 then
      return
   end
   local orgc = (canvas or screen)
   local ow, oh = orgc:getDimensions()
   -- TODO: bounds check
   -- this is wrong
   -- if not bounds(x1,y1,1,1,ow,oh) and not bounds(x2,y2,1,1,ow,oh) then
   --    print("early exit due to ptp bound check")
   --    return
   -- end
   local canv = orgc:_clone_nc({ pxv_notunit(orgc:getFormat(), 0, 0, 0, 0) })
   local pix = rawget(canv, "_pxarray")
   -- hope it's format isn't a single channel!
   local conv_color = { pxv_notunit(canv:getFormat(), dc_r, dc_g, dc_b, dc_a) }
   local dx, dy = x2 - x1, y2 - y1
   for i = 0, 1, 1 / (ow + oh) do
      local px, py = x1 + dx * i, y1 + dy * i
      local rpx, rpy = round(px), round(py)
      -- print(rpx,rpy)
      if bounds(rpx, rpy, 1, 1, ow - 1, oh - 1) then
         pix[rpx][rpy] = conv_color
      end
      local benx, beny = px - line_size, py - line_size
      local endx, endy = px + line_size, py + line_size
      local center_x = benx + (endx - benx) / 2
      local center_y = beny + (endy - beny) / 2
      for x = benx, endx do
         for y = beny, endy do
            -- print("submarine",(x-center_x)^2+(y-center_y)^2,(x-center_x)^2+(y-center_y)^2<=line_size)
            if (x - center_x) ^ 2 + (y - center_y) ^ 2 <= line_size then
               local rx, ry = round(x), round(y)
               if bounds(rx, ry, 1, 1, ow - 1, oh - 1) then
                  pix[rx][ry] = conv_color
               end
            end
         end
      end
   end
   copy(orgc, blend(orgc, transform(canv), 1, 1), true)
end
function love.graphics.points(x, y, ...)
   x, y = x + 1, y + 1
   if point_size == 0 then
      return
   end
   local orgc = (canvas or screen)
   local ow, oh = orgc:getDimensions()
   -- TODO: bounds check
   local canv = orgc:_clone_nc({ pxv_notunit(orgc:getFormat(), 0, 0, 0, 0) })
   local pix = rawget(canv, "_pxarray")
   -- hope it's format isn't a single channel!
   local conv_color = { pxv_notunit(canv:getFormat(), dc_r, dc_g, dc_b, dc_a) }
   local benx, beny = x - point_size / 2, y - point_size / 2
   local endx, endy = x + point_size / 2, y + point_size / 2
   -- local center_x = benx+(endx-benx)/2
   -- local center_y = beny+(endy-beny)/2
   for px = benx, endx do
      for py = beny, endy do
         -- if (px-center_x)^2+(py-center_y)^2<=point_size then
         local rx, ry = round(px), round(py)
         if bounds(rx, ry, 1, 1, ow - 1, oh - 1) then
            pix[rx][ry] = conv_color
         end
         -- end
      end
   end
   copy(orgc, blend(orgc, transform(canv), 1, 1), true)
   if #{ ... } > 0 then
      local ta = { ... }
      for i = 1, #ta, 2 do
         love.graphics.points(ta[i], ta[i + 1])
      end
   end
end
function love.graphics.rectangle(mode, x, y, w, h)
   if mode == "fill" then
      w, h = w - 1, h - 1
      x, y = x + 1, y + 1
      local orgc = (canvas or screen)
      local ow, oh = orgc:getDimensions()
      local canv = orgc:_clone_nc({ pxv_notunit(orgc:getFormat(), 0, 0, 0, 0) })
      local pix = rawget(canv, "_pxarray")
      local conv_color = { pxv_notunit(canv:getFormat(), 1, 1, 1, 1) }
      for px = x, x + w do
         for py = y, y + h do
            local rpx, rpy = round(px), round(py)
            if bounds(rpx, rpy, 1, 1, ow - 1, oh - 1) then
               pix[rpx][rpy] = conv_color
            end
         end
      end
      copy(
         orgc,
         blend(orgc, tint(transform(canv), { pxv_notunit(canv:getFormat(), dc_r, dc_g, dc_b, dc_a) }), 1, 1),
         true
      )
   elseif mode == "line" then
      x, y = x - 1, y - 1
      love.graphics.line(x, y, x + w, y)
      love.graphics.line(x + w, y, x + w, y + h)
      love.graphics.line(x + w, y + h, x, y + h)
      love.graphics.line(x, y + h, x, y)
   end
end
--
function love.graphics._updateWindowMode(mode,dpi)
   local w,h = screen:getDimensions()
   if mode.width~=w or mode.height~=h then
      love.graphics._newScreen(mode.width,mode.height,dpi or 1)
   end
end
function love.graphics._setScreen(scree)
   screen = scree
end
function love.graphics._getScreen()
   return screen
end
function love.graphics._newScreen(x, y, dpi)
   screen = Canvas:_new(x, y, dpi)
end
return love.graphics
