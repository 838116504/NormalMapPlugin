shader_type canvas_item;

uniform vec3 normal;

void fragment()
{
	COLOR.rgb = (normalize(normal.xyz) + 1.0) / 2.0;
	//COLOR.rgb = vec3(1.0, 1.0, 1.0);
	COLOR.a = 1.0;
}