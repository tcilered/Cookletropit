shader_type spatial;

// TV Distortion & Jitter
uniform float wobble_speed : hint_range(0.5, 20.0) = 5.0;
uniform float wobble_strength : hint_range(0.0, 10.0) = 2.0;

// Chromatic Aberration
uniform float r_g_shift : hint_range(-10.0, 10.0) = 1.0;
uniform float b_g_shift : hint_range(-10.0, 10.0) = -1.5;

// TV Ghosting
uniform float ghost_strength : hint_range(0.0, 1.0) = 0.4;

void fragment() {
    // 1. CRT Wobble/Jitter
    vec2 uv = UV;
    uv.x += sin(uv.y * 10.0 + TIME * wobble_speed) * wobble_strength * TEXTURE_PIXEL_SIZE.x;
    
    // 2. Chromatic Aberration (Color channel splitting)
    float r = texture(TEXTURE, uv + vec2(r_g_shift, 0.0) * TEXTURE_PIXEL_SIZE).r;
    float g = texture(TEXTURE, uv).g;
    float b = texture(TEXTURE, uv + vec2(b_g_shift, 0.0) * TEXTURE_PIXEL_SIZE).b;
    vec4 col = vec4(r, g, b, texture(TEXTURE, uv).a);
    
    // 3. TV Ghosting (Echo effect)
    vec4 ghost = texture(TEXTURE, uv + vec2(-4.0 * TEXTURE_PIXEL_SIZE.x, 0.0));
    col.rgb = mix(col.rgb, ghost.rgb, ghost_strength);
    
    // 4. Output
    COLOR = col;
}
