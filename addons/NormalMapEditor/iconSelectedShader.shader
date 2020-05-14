shader_type canvas_item;

uniform vec4 select:hint_color;

void fragment()
{
	COLOR = texture(TEXTURE, UV) * select;
}