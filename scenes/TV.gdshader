shader_type spatial;
render_mode unshaded; // Removes 3D lighting so the screen looks like a glowing TV display

// Pass your SubViewport Texture into this uniform via the Inspector
uniform sampler2D viewport_tex : source_color, filter_linear_mipmap;

// TV Distortion & Jitter
uniform float wobble_speed : hint_range(0.5, 20.0) = 5.0;
uniform float wobble_strength : hint_range(0.0, 0.05) = 0.005; // Adjusted for normalized UV coordinates

// Chromatic Aberration
uniform float r_g_shift : hint_range(-0.02, 0.02) = 0.002;
uniform float b_g_shift : hint_range(-0.02, 0.02) = -0.003;

// TV Ghosting
uniform float ghost_strength : hint_range(0.0, 1.0) = 0.4;

void fragment() {
    // 1. CRT Wobble/Jitter
    vec2 uv = UV;
    uv.x += sin(uv.y * 10.0 + TIME * wobble_speed) * wobble_strength;
    
    // 2. Chromatic Aberration (Color channel splitting)
    float r = texture(viewport_tex, uv + vec2(r_g_shift, 0.0)).r;
    float g = texture(viewport_tex, uv).g;
    float b = texture(viewport_tex, uv + vec2(b_g_shift, 0.0)).b;
    vec4 col = vec4(r, g, b, texture(viewport_tex, uv).a);
    
    // 3. TV Ghosting (Echo effect)
    vec4 ghost = texture(viewport_tex, uv + vec2(-0.01, 0.0));
    col.rgb = mix(col.rgb, ghost.rgb, ghost_strength);
    
    // 4. Output to 3D Material
    ALBEDO = col.rgb;
    ALPHA = col.a;
}