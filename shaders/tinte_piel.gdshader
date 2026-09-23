shader_type canvas_item;

uniform vec4 color_tinte : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = vec4(tex.rgb * color_tinte.rgb, tex.a * color_tinte.a);
}
