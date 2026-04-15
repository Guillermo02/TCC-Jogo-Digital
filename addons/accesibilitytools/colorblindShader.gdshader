shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

uniform int mode = 0;

void fragment() {
    vec4 color = texture(screen_texture, SCREEN_UV);

    if (mode == 1) {
        color.rgb = vec3(
            0.567 * color.r + 0.433 * color.g,
            0.558 * color.r + 0.442 * color.g,
            color.b
        );
    }

    if (mode == 2) {
        color.rgb = vec3(
            0.625 * color.r + 0.375 * color.g,
            0.7 * color.r + 0.3 * color.g,
            color.b
        );
    }

    if (mode == 3) {
        color.rgb = vec3(
            color.r,
            0.95 * color.g + 0.05 * color.b,
            0.433 * color.g + 0.567 * color.b
        );
    }

    COLOR = color;
}