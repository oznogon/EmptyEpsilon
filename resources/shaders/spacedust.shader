[vertex]
// Program inputs.
uniform mat4 u_projection;
uniform mat4 u_view;
uniform vec2 u_velocity;

// Per-vertex inputs
attribute vec3 a_position;
attribute float a_sign_value;

varying float v_distance;

void main()
{    
    vec4 view_pos = u_view * vec4(a_position.xy + a_sign_value * u_velocity, a_position.z, 1.);
    v_distance = length(view_pos.xyz);
    gl_Position = u_projection * view_pos;
}

[fragment]
// Shader constants
const vec4 color = vec4(0.7, 0.5, 0.35, 0.07);

uniform vec3 u_fogColor;
uniform float u_fogDistance;
uniform float u_time;

varying float v_distance;

void main()
{
    gl_FragColor = color;

    if (u_fogDistance > 0.0)
    {
        float color_fog = clamp(1.0 - v_distance / u_fogDistance, 0.0, 1.0);
        gl_FragColor.rgb = mix(u_fogColor, gl_FragColor.rgb, color_fog);
        if (v_distance > 1000.0)
        {
            float dither_range = max(u_fogDistance - 1000.0, 200.0);
            float dither_factor = clamp(1.0 - (v_distance - 1000.0) / dither_range, 0.0, 1.0);
            float dither = fract(sin(dot(gl_FragCoord.xy + u_time * 100.0, vec2(12.9898, 78.233))) * 43758.5453);
            if (dither > dither_factor)
                discard;
        }
    }
}
