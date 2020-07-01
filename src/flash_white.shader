shader_type canvas_item;

uniform bool active = false;
uniform float offset = 0.9;

void fragment() {
	vec4 originalColour = texture(TEXTURE, UV);
	
	if (active == true) {
		if (originalColour.a != 0.0) {
			originalColour.r = originalColour.r + offset;
			originalColour.g = originalColour.g + offset;
			originalColour.b = originalColour.b + offset;
		} 
	}
	
	COLOR = originalColour;

}