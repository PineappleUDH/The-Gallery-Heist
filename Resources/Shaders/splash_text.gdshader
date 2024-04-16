shader_type canvas_item;

void vertex()
{
	VERTEX.y += sin(TIME * 4.0 + VERTEX.x) * 2.0;
}
