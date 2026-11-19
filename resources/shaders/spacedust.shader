[vertex]
// Program inputs.
uniform mat4 u_projection;
uniform mat4 u_rotation;
uniform mat4 u_rotation_previous;
uniform vec3 u_camera_position;
uniform vec3 u_box_size;
uniform vec3 u_camera_delta;
uniform vec2 u_pixel_size;
uniform vec2 u_near_fade;
uniform vec2 u_far_fade;
uniform float u_min_streak;
uniform float u_max_streak;

// Per-vertex inputs
attribute vec3 a_position;
attribute float a_sign_value;

varying float v_distance;
varying float v_fade;

void main()
{
    // Wrap a static dust seed around the CPU-driven camera.
    vec3 half_box = u_box_size * 0.5;
    vec3 relative = mod(a_position - u_camera_position + half_box, u_box_size) - half_box;
    // Also wrap the previous position to prevent particles that cross the box
    // edge between frames from rendering the jump.
    vec3 relative_previous = mod(a_position - (u_camera_position - u_camera_delta) + half_box, u_box_size) - half_box;

    // Use untranslated view rotations.
    vec4 view_pos = u_rotation * vec4(relative, 1.0);
    vec4 view_pos_previous = u_rotation_previous * vec4(relative_previous, 1.0);
    vec4 clip = u_projection * view_pos;
    vec4 clip_previous = u_projection * view_pos_previous;

    // Convert the camera's movement to a screen-space streak.
    float screen_length = 0.0;
    vec2 screen_direction = normalize(vec2(
        sin(a_position.x * 12.9898 + a_position.z * 4.1414),
        cos(a_position.y * 78.233 + a_position.x * 3.717)
    ) + vec2(0.0001, 0.0001));

    // Project the previous sample only when the particle's in front of the
    // camera for both samples. Otherwise you get long lines to/from the
    // vanishing point.
    if (clip.w > 0.001 && clip_previous.w > 0.001)
    {
        vec2 screen_delta = (clip.xy / clip.w - clip_previous.xy / clip_previous.w) / u_pixel_size;
        screen_length = length(screen_delta);
        if (screen_length > 0.0001)
            screen_direction = screen_delta / screen_length;
    }

    // Cap streak length to min/max amounts.
    float streak_length = clamp(screen_length, u_min_streak, u_max_streak);
    vec2 offset = screen_direction * u_pixel_size * (streak_length * 0.5) * a_sign_value;
    clip.xy += offset * clip.w;

    v_distance = length(view_pos.xyz);
    v_fade = smoothstep(u_near_fade.x, u_near_fade.y, v_distance)
        * (1.0 - smoothstep(u_far_fade.x, u_far_fade.y, v_distance));

    gl_Position = clip;
}

[fragment]
// Shader constants
const vec4 color = vec4(0.7, 0.5, 0.35, 1.0);

uniform vec3 u_fogColor;
uniform float u_fogDistance;

varying float v_distance;
varying float v_fade;

void main()
{
    gl_FragColor = color;

    if (u_fogDistance > 0.0)
    {
        float color_fog = clamp(1.0 - v_distance / u_fogDistance, 0.0, 1.0);
        gl_FragColor.rgb = mix(u_fogColor, gl_FragColor.rgb, color_fog);
    }

    // Fade the streak if necessary, typically near/far from camera.
    gl_FragColor.a *= v_fade;
}
