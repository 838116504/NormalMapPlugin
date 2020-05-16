shader_type canvas_item;

uniform bool isHover = false;

void fragment()
{
	COLOR = texture(TEXTURE, UV);
	if (isHover)
		COLOR.rgb += 0.1;
}