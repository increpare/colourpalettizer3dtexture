shader_type canvas_item;

uniform vec2 size = vec2(32.0, 28.0);
// If you intend to read from mipmaps with `textureLod()` LOD values greater than `0.0`,
// use `filter_nearest_mipmap` instead. This shader doesn't require it.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest, source_color;
uniform sampler3D colorblend : repeat_disable, filter_nearest;
uniform sampler2D randomoffset : repeat_enable;
uniform float randomfrequency=10.0;
uniform float randomamount=0.1;

void fragment() {
	vec3 col = texture(screen_texture, SCREEN_UV, 0.0).xyz;
	vec3 jitter = (texture(randomoffset,randomfrequency*SCREEN_UV).xyz*2.0-vec3(1.0,1.0,1.0))*randomamount;
    COLOR = texture(colorblend,col+jitter);
}