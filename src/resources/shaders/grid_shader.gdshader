shader_type spatial;

uniform float line_width : hint_range(0.001, 0.5, 0.001) = 0.005;

// Controls how far the grid is visible
uniform float fade_start : hint_range(0, 100, 1) = 5.0;
uniform float fade_end : hint_range(0, 100, 1) = 20.0;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
    vec4 world_pos = MODEL_MATRIX * vec4(VERTEX, 1.0);
    world_position = world_pos.xyz;
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
    // 1. Calculate the basic grid (Hard lines, no AA)
    vec2 grid_xz = fract(world_position.xz);
    vec2 grid_xy = fract(world_position.xy);
    vec2 grid_yz = fract(world_position.yz);

    float line_xz = step(grid_xz.x, line_width) + (1.0 - step(grid_xz.x, 1.0 - line_width)) + 
                     step(grid_xz.y, line_width) + (1.0 - step(grid_xz.y, 1.0 - line_width));
    float line_xy = step(grid_xy.x, line_width) + (1.0 - step(grid_xy.x, 1.0 - line_width)) +
                     step(grid_xy.y, line_width) + (1.0 - step(grid_xy.y, 1.0 - line_width));
    float line_yz = step(grid_yz.x, line_width) + (1.0 - step(grid_yz.x, 1.0 - line_width)) +
                     step(grid_yz.y, line_width) + (1.0 - step(grid_yz.y, 1.0 - line_width));

    // 2. Calculate distance to camera
    // CAMERA_POSITION_WORLD is a built-in in Godot 4 fragment shaders<kcite ref="17"/>
    float dist = distance(CAMERA_POSITION_WORLD, world_position);

    // 3. Calculate fade factor (1.0 = visible, 0.0 = invisible)
    // smoothstep transitions smoothly from fade_start to fade_end
    float fade = 1.0 - smoothstep(fade_start, fade_end, dist);

    // 4. Determine visible grid based on normals
    float w_xz = abs(world_normal.y);
    float w_xy = abs(world_normal.z);
    float w_yz = abs(world_normal.x);

    float grid = max(line_xz * w_xz, max(line_xy * w_xy, line_yz * w_yz));

    // 5. Mix colors, applying the fade
    // As 'fade' drops to 0, the white lines mix into the black background
    ALBEDO = mix(vec3(0.0), vec3(1.0), step(0.5, grid) * fade);
}
