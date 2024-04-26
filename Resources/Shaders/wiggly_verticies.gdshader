shader_type canvas_item;

uniform float speed = 4.0;
uniform float scale = 2.0;

void vertex()
{
	VERTEX.y += sin(TIME * speed + VERTEX.x) * scale;
}
