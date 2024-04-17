shader_type canvas_item;

uniform sampler2D noise : repeat_enable;

void fragment()
{
	float noise_ = texture(noise, UV + vec2(0, TIME * 0.2)).r;
	
	float offset = sin((noise_ + TIME) * 1.0) * 0.03;
	vec4 r = texture(TEXTURE, UV + vec2(0, offset));
	vec4 g = texture(TEXTURE, UV + vec2(-offset, 0));
	vec4 b = texture(TEXTURE, UV + vec2(offset, 0));
	COLOR = vec4(r.r, g.g, b.b, r.a + g.a + b.a);
}
