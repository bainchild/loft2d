local ta = {
	"thread",
	"timer",
	"event",
	"keyboard",
	"joystick",
	"mouse",
	"touch",
	"sound",
	-- "system",
	"sensor",
	"audio",
	"image",
	"video",
	"font",
	-- "window",
	"graphics",
	"math",
	"physics"
}
for _,v in next, ta do
	os.execute("rm loft."..v..".lua && mkdir loft."..v)
end
