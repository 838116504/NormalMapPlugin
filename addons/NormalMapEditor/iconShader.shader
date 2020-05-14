shader_type canvas_item;

uniform vec4 forward:hint_color;
//uniform vec4 back:hint_color;

void fragment()
{
	COLOR = texture(TEXTURE, UV) * forward;
	//if (COLOR.rgba == vec4(1.0, 1.0, 1.0, 1.0))
	//{
	//	COLOR = back;
	//} else if (COLOR.rgba == vec4(0.0, 0.0, 0.0, 1.0))
	//	COLOR = forward;
}