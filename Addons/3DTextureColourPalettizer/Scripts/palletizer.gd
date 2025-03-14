@tool 
class_name Palettizer extends ColorRect

# takes images rather than Texture2Ds, remember you have to change the import
# setting of the assets you want to load as palettes in the import tab
var _palette_source: Texture2D
var _palette: ImageTexture3D
@export var c_size:int = 16

@export var palette_source: Texture2D:
	get:
		return _palette_source
	set(value):
		print("setzend palette")
		if value != _palette_source:
			_palette_source = value
			regen_palette()
			
class LAB:
	var l: float
	var a: float
	var b: float
	
	func _init(l: float, a: float, b: float) -> void:
		self.l = l
		self.a = a
		self.b = b
	

# Utility function: convert degrees to radians.
static func deg2Rad(deg: float) -> float:
	return deg * (PI / 180.0)

# Utility function: convert radians to degrees.
static func rad2Deg(rad: float) -> float:
	return (180.0 / PI) * rad

# Compute the CIEDE2000 color difference between two LAB colors.
# The function assumes that the parametric factors k_L, k_C, k_H are set to 1.0.
static func ciede2000(lab1: LAB, lab2: LAB) -> float:
	var k_L = 1.0
	var k_C = 1.0
	var k_H = 1.0
	var deg360InRad = deg2Rad(360.0)
	var deg180InRad = deg2Rad(180.0)
	var pow25To7 = pow(25.0, 7.0)  # This is 25^7 = 6103515625
	
	# Step 1: Calculate C1, C2, and the adjustment factor G.
	var C1 = sqrt(pow(lab1.a, 2) + pow(lab1.b, 2))
	var C2 = sqrt(pow(lab2.a, 2) + pow(lab2.b, 2))
	var barC = (C1 + C2) / 2.0
	var G = 0.5 * (1.0 - sqrt(pow(barC, 7.0) / (pow(barC, 7.0) + pow25To7)))
	var a1Prime = (1.0 + G) * lab1.a
	var a2Prime = (1.0 + G) * lab2.a
	var CPrime1 = sqrt(pow(a1Prime, 2) + pow(lab1.b, 2))
	var CPrime2 = sqrt(pow(a2Prime, 2) + pow(lab2.b, 2))
	
	var hPrime1 = 0.0
	if lab1.b == 0.0 and a1Prime == 0.0:
		hPrime1 = 0.0
	else:
		hPrime1 = atan2(lab1.b, a1Prime)
		if hPrime1 < 0:
			hPrime1 += deg360InRad
	
	var hPrime2 = 0.0
	if lab2.b == 0.0 and a2Prime == 0.0:
		hPrime2 = 0.0
	else:
		hPrime2 = atan2(lab2.b, a2Prime)
		if hPrime2 < 0:
			hPrime2 += deg360InRad
	
	# Step 2: Compute delta values.
	var deltaLPrime = lab2.l - lab1.l
	var deltaCPrime = CPrime2 - CPrime1
	var deltahPrime = 0.0
	var CPrimeProduct = CPrime1 * CPrime2
	if CPrimeProduct == 0.0:
		deltahPrime = 0.0
	else:
		deltahPrime = hPrime2 - hPrime1
		if deltahPrime < -deg180InRad:
			deltahPrime += deg360InRad
		elif deltahPrime > deg180InRad:
			deltahPrime -= deg360InRad
	var deltaHPrime = 2.0 * sqrt(CPrimeProduct) * sin(deltahPrime / 2.0)
	
	# Step 3: Calculate the average values.
	var barLPrime = (lab1.l + lab2.l) / 2.0
	var barCPrime = (CPrime1 + CPrime2) / 2.0
	var hPrimeSum = hPrime1 + hPrime2
	var barhPrime = 0.0
	if CPrime1 * CPrime2 == 0.0:
		barhPrime = hPrimeSum
	else:
		if abs(hPrime1 - hPrime2) <= deg180InRad:
			barhPrime = hPrimeSum / 2.0
		else:
			if hPrimeSum < deg360InRad:
				barhPrime = (hPrimeSum + deg360InRad) / 2.0
			else:
				barhPrime = (hPrimeSum - deg360InRad) / 2.0
	
	# Step 4: Calculate T, deltaTheta, R_C, S_L, S_C, S_H, and R_T.
	var T = 1.0 - (0.17 * cos(barhPrime - deg2Rad(30.0))) \
			  + (0.24 * cos(2.0 * barhPrime)) \
			  + (0.32 * cos(3.0 * barhPrime + deg2Rad(6.0))) \
			  - (0.20 * cos(4.0 * barhPrime - deg2Rad(63.0)))
	var deltaTheta = deg2Rad(30.0) * exp(-pow((barhPrime - deg2Rad(275.0)) / deg2Rad(25.0), 2.0))
	var R_C = 2.0 * sqrt(pow(barCPrime, 7.0) / (pow(barCPrime, 7.0) + pow25To7))
	var S_L = 1.0 + ((0.015 * pow(barLPrime - 50.0, 2.0)) / sqrt(20.0 + pow(barLPrime - 50.0, 2.0)))
	var S_C = 1.0 + (0.045 * barCPrime)
	var S_H = 1.0 + (0.015 * barCPrime * T)
	var R_T = -sin(2.0 * deltaTheta) * R_C
	
	# Step 5: Combine the terms to get the final delta E value.
	var deltaE = sqrt(
		pow(deltaLPrime / (k_L * S_L), 2.0) +
		pow(deltaCPrime / (k_C * S_C), 2.0) +
		pow(deltaHPrime / (k_H * S_H), 2.0) +
		(R_T * (deltaCPrime / (k_C * S_C)) * (deltaHPrime / (k_H * S_H)))
	)
	
	return deltaE

# Helper: f(t) function used in the LAB conversion.
func f(t: float) -> float:
	if t > 0.008856:
		return pow(t, 1.0 / 3.0)
	else:
		return (7.787 * t) + (16.0 / 116.0)
	
# Helper: Convert sRGB channel to linear RGB.
func srgb_to_linear(channel: float) -> float:
	if channel <= 0.04045:
		return channel / 12.92
	else:
		return pow((channel + 0.055) / 1.055, 2.4)
		
func color_to_lab(color: Color) -> LAB:
	
	# Convert each sRGB channel to linear space.
	var r_linear = srgb_to_linear(color.r)
	var g_linear = srgb_to_linear(color.g)
	var b_linear = srgb_to_linear(color.b)
	
	# Convert linear RGB to XYZ using the standard sRGB conversion matrix (D65).
	var X = (0.4124564 * r_linear) + (0.3575761 * g_linear) + (0.1804375 * b_linear)
	var Y = (0.2126729 * r_linear) + (0.7151522 * g_linear) + (0.0721750 * b_linear)
	var Z = (0.0193339 * r_linear) + (0.1191920 * g_linear) + (0.9503041 * b_linear)
	
	# Normalize XYZ values with reference white (D65)
	var X_n = 0.95047
	var Y_n = 1.00000
	var Z_n = 1.08883
	
	
	var fX = f(X / X_n)
	var fY = f(Y / Y_n)
	var fZ = f(Z / Z_n)
	
	# Compute LAB components.
	var L = (116.0 * fY) - 16.0
	var a = 500.0 * (fX - fY)
	var b = 200.0 * (fY - fZ)
	
	return LAB.new(L, a, b)

func CIE76_sq(c1:LAB,c2:LAB)->float:
	var dl:float=c2.l-c1.l
	var da:float=c2.a-c1.a
	var db:float=c2.b-c1.b
	return dl*dl+da*da+db*db
	
func color_distance(c1:Color,c2:Color)->float:
	var lab1:LAB=color_to_lab(c1)
	var lab2:LAB=color_to_lab(c2)
	return CIE76_sq(lab1,lab2)
	
func nearest_color(a:Color,palette:PackedColorArray)->Color:
	var nearest_dist:float=10000000
	var nearest_col:Color=Color.MAGENTA
	for c in palette:
		var dist:float = color_distance(a,c)
		if dist<nearest_dist:
			nearest_dist=dist
			nearest_col=c
	return nearest_col
		
var cached:Dictionary={}

func regen_palette():
	if _palette_source==null:
		print("palette source is null")
		return
		
	var sm:ShaderMaterial = self.material
	
	if cached.has(_palette_source):
		sm.set_shader_parameter("colorblend",cached[_palette_source])
		return
	
	var _palette_source_im:Image = _palette_source.get_image()

	var palette:PackedColorArray=[]
	for x:int in _palette_source_im.get_width():
		for y:int in _palette_source_im.get_height():
			var pixel = _palette_source_im.get_pixel(x,y)
			if palette.find(pixel)==-1:
				palette.push_back(pixel)
	
	print("regenning palette")
	var images:Array[Image]=[]
	for b:int in range(c_size):
		var img:Image = Image.create(c_size,c_size,false,Image.FORMAT_RGB8)
		
		for g:int in range(c_size):
			for r:int in range(c_size):
				var reference_col:Color=Color(float(r)/c_size,float(g)/c_size,float(b)/c_size)
				var nearest_pal_color:Color=nearest_color(reference_col,palette)
				img.set_pixel(r,g,nearest_pal_color)
		
		images.push_back(img)
	
	_palette = ImageTexture3D.new()
	print("creating 3d")
	_palette.create(Image.FORMAT_RGB8,c_size,c_size,c_size,false,images)
	sm.set_shader_parameter("colorblend",_palette)
	cached[_palette_source]=_palette
	
