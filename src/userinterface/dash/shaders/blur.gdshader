shader_type canvas_item;
render_mode blend_mix;

uniform vec3 color : source_color = vec3(1.0);
uniform float blur_amount : hint_range(0.1, 8.0) = 4.0;
uniform float roughness : hint_range(0.0, 1.0, 0.01) = 0.2;
uniform float roughness_affect : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

float overlay(float base, float blend) {
    float limit = step(0.5, base);
    return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}

void fragment() {
    vec2 screen_uv = SCREEN_UV;
    float blur = mix(blur_amount, overlay(blur_amount, 1.0 - roughness), roughness_affect);

    vec3 glass = textureLod(SCREEN_TEXTURE, screen_uv, blur).rgb;

    float coat_amount = pow(1.0, 1.0);
    vec3 final_color = color * mix(vec3(1.0), glass, coat_amount);

    COLOR = vec4(final_color, 1.0);
}
