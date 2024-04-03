---@diagnostic disable: unused-local, deprecated
local love = require('loft')
local ImageData = require('loft._classes.ImageData')
local Canvas = require('loft._classes.Canvas')
local Image = require('loft._classes.Image')
love.graphics = {}
local dc_r,dc_g,dc_b,dc_a = 1,1,1,1
local bg_r,bg_g,bg_b,bg_a = 0,0,0,0
local scissor,blendmode,ccm,wireframe = nil,"alphamultiply",{true,true,true,true},false
local transform_ox,transform_oy,transform_sx,transform_sy,transform_r = 0,0,1,1,0
local line_mode,point_size,line_size = "smooth",1,.25
local font
local canvas
local screen
local shallow_clone = table.clone or function(a)
   local n = {}
   for i,v in next, a do n[i]=v end
   return n
end
local function deep_clone(a)
   local n = {}
   for i,v in next, a do
      if type(v)=="table" then
         n[i]=deep_clone(v)
      else
         n[i]=v
      end
   end
   return n
end
local function round(a)
   local rem = (a%1)
   if rem>=.5 then
      return a-rem+1
   end
   return a-rem
end
-- point box check
local function bounds(px,py,box,boy,sx,sy)
   if px>box+sx or px<box then
      return false
   end
   if py>boy+sy or py<boy then
      return false
   end
   return true
end
local function convert(format,r,g,b,a)
   r,g,b,a=r or 0,g or 0,b or 0,a or 0
   if format:sub(-1)=="8" then
      return r/255,g/255,b/255,a/255
   elseif format:sub(-2)=="16" or format:sub(-3)=="16f" then
      return r/65535,g/65535,b/65535,a/65535
  elseif format:sub(-2)=="32" or format:sub(-3)=="32f" then
      local max = 2^31
      return r/max,g/max,b/max,a/max
   end
   return r,g,b,a
end
local function unconvert(format,r,g,b,a)
   r,g,b,a=r or 0,g or 0,b or 0,a or 0
   if format:sub(-1)=="8" then
      return math.floor(r*255),math.floor(g*255),math.floor(b*255),math.floor(a*255)
   elseif format:sub(-2)=="16" then
      return math.floor(r*65535),math.floor(g*65535),math.floor(b*65535),math.floor(a*65535)
   elseif format:sub(-3)=="16f" then
      return r*65535,g*65535,b*65535,a*65535
   elseif format:sub(-2)=="32" then
      local max = 2^31
      return math.floor(r*max),math.floor(g*max),math.floor(b*max),math.floor(a*max)
   elseif format:sub(-3)=="32f" then
      local max = 2^31
      return r*max,g*max,b*max,a*max
   end
   return r,g,b,a
end
local function transform(canva)
   -- TODO: rotation
   -- NEVER_TODO_PROBABLY: shear
   local width,height = canva:getDimensions()
   local newcan = canva:_clone_nc({unconvert(canva:getFormat(),bg_r,bg_g,bg_b,bg_a)})
   local newpx = rawget(newcan,"_pxarray")
   local px = rawget(canva,"_pxarray")
   for x=1,width do
      for y=1,height do
         local nx,ny = math.floor(x*transform_sx+transform_ox),math.floor(y*transform_sy+transform_oy)
         if not (nx>width or ny>height) then
            newpx[x][y] = px[x][y]
         end
      end
   end
   return newcan
end
local function clampf(a,b,c)
   if a>c then return c end
   if a<b then return b end
   return math.floor(a)
end
local function blend(canva,canvb,bx,by)
   -- assumes that canva is bigger than canvb
   -- clips canvb with canva
   -- TODO: blending modes (currently just alphamultiply)
   local width,height = canva:getWidth(),canva:getHeight()
   local bwidth,bheight = canvb:getWidth(),canvb:getHeight()
   local cf = canva:getFormat()
   local format_max
   if cf:sub(-1)=="8" then
      format_max=255
   elseif cf:sub(-2)=="16" then
      format_max=65535
   elseif cf:sub(-2)=="32" then
      format_max=2^31
   end
   local canvr = canva:_clone_nc()
   local px,apx,bpx = rawget(canvr,"_pxarray"),rawget(canva,"_pxarray"),rawget(canvb,"_pxarray")
   for x=1,width do
      for y=1,height do
         if bounds(x,y,bx,by,bwidth-1,bheight-1) then
            -- print(x-bx+1,y-by+1,"(@",bwidth,bheight,")")
            -- blending!!!
            local src_2 = bpx[x-bx+1][y-by+1]
            if type(src_2)=="table" then
               local src={
                  src_2[1]/format_max,
                  src_2[2]/format_max,
                  src_2[3]/format_max,
                  src_2[4]/format_max
               }
               local dst
               do
                  local dst_1 = apx[x][y];
                  dst={
                     dst_1[1]/format_max,
                     dst_1[2]/format_max,
                     dst_1[3]/format_max,
                     dst_1[4]/format_max
                  }
               end
               local src_alpha = src[4]
               local iv_alpha = 1-src_alpha
               -- print(clr1a,clr1an,iv_clr1a)
               if format_max==nil then
                  px[x][y] = {
                     (dst[1] * iv_alpha + src[1] * src_alpha)*format_max;
                     (dst[2] * iv_alpha + src[2] * src_alpha)*format_max;
                     (dst[3] * iv_alpha + src[3] * src_alpha)*format_max;
                     (dst[4] * iv_alpha + src_alpha)*format_max;
                  }
               else
                  px[x][y] = {
                     clampf((dst[1] * iv_alpha + src[1] * src_alpha)*format_max,0,format_max);
                     clampf((dst[2] * iv_alpha + src[2] * src_alpha)*format_max,0,format_max);
                     clampf((dst[3] * iv_alpha + src[3] * src_alpha)*format_max,0,format_max);
                     clampf((dst[4] * iv_alpha + src_alpha)*format_max,0,format_max);
                  }
               end
               -- local cpx = px[x][y]
               -- print(("(%d,%d,%d,%d) + (%d,%d,%d,%d) = (%d,%d,%d,%d)"):format(
               --    clr2[1],clr2[2],clr2[3],clr2[4],
               --    clr1[1],clr1[2],clr1[3],clr1[4],
               --    cpx[1],cpx[2],cpx[3],cpx[4]))
            else
               px[x][y] = src_2
            end
         else
            px[x][y] = apx[x][y]
         end
      end
   end
   return canvr
end
local function copy(canva,canvb,noc)
   local ax,ay = canva:getDimensions()
   if ax~=canvb:getWidth() or ay~=canvb:getHeight() then return nil end
   local aform,bform = canva:getFormat(),canvb:getFormat()
   if aform==bform then
      local opx = rawget(canvb,"_pxarray")
      if noc then
         rawset(canva,"_pxarray",opx)
         canvb:release()
      else
         rawset(canva,"_pxarray",deep_clone(opx))
      end
   else
      local apx,bpx = rawget(canva,"_pxarray"),rawget(canvb,"_pxarray")
      for x=1,ax do
         for y=1,ay do
            local pv = bpx[x][y]
            if type(pv)=="table" then
               apx[x][y] = {unconvert(aform,convert(bform,(unpack or table.unpack)(pv)))}
            else
               apx[x][y] = unconvert(aform,convert(bform,pv))
            end
         end
      end
   end
   return canva
end
love.graphics._transform = transform
love.graphics._blend = blend
function love.graphics.newImage(file,settings)
   if type(file)=="table" and rawget(file,"_isAobject") and file:typeOf("Data") then
      if file:typeOf("ImageData") then
         return Image:_new("2d",file,settings)
      else
         file=file:getString()
      end
   elseif type(file)=="string" then
      file=assert(love.filesystem.read(file))
   end
   return Image:_new("2d",ImageData:_decode(file),settings)
end
function love.graphics.setFont(fon) font=fon end
-- filename, size, hinting, dpiscale: truetype
-- filename, imagefilename: BMFont + image
-- size, hinting, dpiscale: inbuilt
function love.graphics.newFont(size,hinting,dpiscale)

end
function love.graphics.isActive()
   return love.graphics.isCreated() and (canvas or screen)
end
function love.graphics.isCreated()
   return love.window and love.window.isOpen and love.window.isOpen()
end
function love.graphics.reset()
   assert(love.graphics.isActive(),"not active...")
   dc_r,dc_g,dc_b,dc_a = 1,1,1,1
   bg_r,bg_g,bg_b,bg_a = 0,0,0,0
   scissor,blendmode,ccm,wireframe = nil,"alphamultiply",{true,true,true,true},false
   transform_ox,transform_oy,transform_sx,transform_sy,transform_r = 0,0,1,1,0
   line_mode,point_size,line_size = "smooth",1,.25
end
function love.graphics.origin()
   assert(love.graphics.isActive(),"not active...")
   transform_ox,transform_oy,transform_sx,transform_sy,transform_r = 0,0,1,1,0
end
function love.graphics.rotate(n)
   assert(love.graphics.isActive(),"not active...")
   transform_r=n
end
function love.graphics.translate(x,y)
   assert(love.graphics.isActive(),"not active...")
   transform_ox,transform_oy=transform_ox+x,transform_oy+y
end
function love.graphics.scale(sx,sy)
   assert(love.graphics.isActive(),"not active...")
   -- I think?
   if sy==nil then sy=sx end
   transform_ox,transform_oy=transform_ox*sx,transform_oy*sy
   transform_sx,transform_sy=transform_sx*sx,transform_sy*sy
end
function love.graphics.clear(r,g,b,a,stencil,depth)
   assert(love.graphics.isActive(),"not active...")
   if r==nil then r,g,b,a = 0,0,0,0 end -- haha get side effected!!!!
   if a==nil then a=1 end
   local canva = canvas or screen
   local px,form = rawget(canva,"_pxarray"),rawget(canva,"_pxformat")
   for x=1,canva:getWidth() do
      for y=1,canva:getHeight() do
         if type(px[x][y])=="table" then
            px[x][y] = {unconvert(form,r,g,b,a)}
         else
            px[x][y] = unconvert(form,r,g,b,a)
         end
      end
   end
end
love.graphics.discard = love.graphics.clear
function love.graphics.present()
   assert(love.graphics.isActive(),"not active...")
   if love._provider and love._provider.display and love._provider.display.update then
      love._provider.display.update(screen:newImageData())
   end
end
function love.graphics.getWidth()
   assert(love.graphics.isActive(),"not active...")
   local canva = canvas or screen
   return canva:getWidth()
end
function love.graphics.getHeight()
   assert(love.graphics.isActive(),"not active...")
   local canva = canvas or screen
   return canva:getHeight()
end
function love.graphics.getDimensions()
   assert(love.graphics.isActive(),"not active...")
   local canva = canvas or screen
   return canva:getDimensions()
end
function love.graphics.getBackgroundColor()
   return bg_r,bg_g,bg_b,bg_a
end
function love.graphics.getColor()
   return dc_r,dc_g,dc_b,dc_a
end
function love.graphics.setBackgroundColor(r,g,b,a)
   bg_r,bg_g,bg_b,bg_a = r,g,b,a
end
function love.graphics.setColor(r,g,b,a)
   dc_r,dc_g,dc_b,dc_a = r,g,b,a
end
function love.graphics.setCanvas(canva)
   canvas=canva or screen
end
function love.graphics.setLineSize(size)
   line_size=size
end
function love.graphics.setPointSize(size)
   point_size=size
end
-- no shears here!!!
-- NOTE: ignoring scale for now, and rotation
-- cause the blender will not like that
function love.graphics.draw(drawable,x,y,r,sx,sy,ox,oy)
   assert(love.graphics.isActive(),"not active...")
   local target = (canvas or screen)
   local w,h,px = drawable:_getpxarray("rgba8")
   copy(target,blend(target,Canvas:_new(w,h,1,"rgba8",px),x,y),true)
end
function love.graphics.line(x1,y1,x2,y2)
   -- TODO: overloads
   x1,y1,x2,y2=x1+1,y1+1,x2+1,y2+1
   if line_size==0 then return end
   local orgc = (canvas or screen)
   local ow,oh = orgc:getDimensions()
   -- TODO: bounds check
   -- this is wrong
   -- if not bounds(x1,y1,1,1,ow,oh) and not bounds(x2,y2,1,1,ow,oh) then
   --    print("early exit due to ptp bound check")
   --    return
   -- end
   local canv = orgc:_clone_nc()
   local pix = rawget(canv,"_pxarray")
   -- hope it's format isn't a single channel!
   local conv_color = {unconvert(canv:getFormat(),dc_r,dc_g,dc_b,dc_a)}
   local dx,dy = x2-x1,y2-y1
   for i=0,1,1/(ow+oh) do
      local px,py = x1+dx*i,y1+dy*i
      local rpx,rpy = round(px),round(py)
      -- print(rpx,rpy)
      if bounds(rpx,rpy,1,1,ow-1,oh-1) then
         pix[rpx][rpy] = conv_color
      end
      local benx,beny = px-line_size,py-line_size
      local endx,endy = px+line_size,py+line_size
      local center_x = benx+(endx-benx)/2
      local center_y = beny+(endy-beny)/2
      for x=benx,endx do
         for y=beny,endy do
            -- print("submarine",(x-center_x)^2+(y-center_y)^2,(x-center_x)^2+(y-center_y)^2<=line_size)
            if (x-center_x)^2+(y-center_y)^2<=line_size then
               local rx,ry = round(x),round(y)
               if bounds(rx,ry,1,1,ow-1,oh-1) then
                  pix[rx][ry] = conv_color
               end
            end
         end
      end
   end
   copy((canvas or screen),blend((canvas or screen),transform(canv),1,1),true)
end
function love.graphics.points(x,y)
   x,y=x+1,y+1
   if point_size==0 then return end
   local orgc = (canvas or screen)
   local ow,oh = orgc:getDimensions()
   -- TODO: bounds check
   local canv = orgc:_clone_nc()
   local pix = rawget(canv,"_pxarray")
   -- hope it's format isn't a single channel!
   local conv_color = {unconvert(canv:getFormat(),dc_r,dc_g,dc_b,dc_a)}
   local benx,beny = x-point_size/2,y-point_size/2
   local endx,endy = x+point_size/2,y+point_size/2
   -- local center_x = benx+(endx-benx)/2
   -- local center_y = beny+(endy-beny)/2
   for px=benx,endx do
      for py=beny,endy do
         -- if (px-center_x)^2+(py-center_y)^2<=point_size then
            local rx,ry = round(px),round(py)
         --    if bounds(rx,ry,1,1,ow-1,oh-1) then
               pix[rx][ry] = conv_color
         --    end
         -- end
      end
   end
   copy((canvas or screen),blend((canvas or screen),transform(canv),1,1),true)
end
--
function love.graphics._setScreen(scree)
   screen=scree
end
function love.graphics._getScreen()
   return screen
end
function love.graphics._newScreen(x,y,dpi)
   screen=Canvas:_new(x,y,dpi)
end
return love.graphics
