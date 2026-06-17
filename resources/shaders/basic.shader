[vertex]
uniform vec4 u_color;
uniform mat4 u_model;
uniform mat4 u_view;
uniform mat4 u_projection;

attribute vec3 a_position;
attribute vec2 a_texcoords;

varying vec2 v_fragtexcoords;
varying float v_distance;

void main()
{
    v_fragtexcoords = a_texcoords;
    vec4 modelview_pos = u_view * u_model * vec4(a_position, 1.0);
    v_distance = length(modelview_pos.xyz);
    gl_Position = u_projection * modelview_pos;
}

[fragment]
uniform vec4 u_color;
uniform sampler2D u_textureMap;
uniform vec3 u_fogColor;
uniform float u_fogDistance;
uniform float u_time;

varying vec2 v_fragtexcoords;
varying float v_distance;

void main()
{
    gl_FragColor = texture2D(u_textureMap, v_fragtexcoords.st) * u_color;
    gl_FragColor.rgb *= u_color.a;

    if (u_fogDistance > 0.0)
    {
        float color_fog = clamp(1.0 - v_distance / u_fogDistance, 0.0, 1.0);
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
