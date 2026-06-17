[vertex]

// Constants

// Program inputs
uniform mat4 u_projection;
uniform mat4 u_view;

// Per-vertex inputs
attribute vec3 a_center;
attribute vec2 a_texcoords;
attribute vec3 a_color;
attribute float a_size;

// Per-vertex outputs
varying vec3 v_color;
varying vec2 v_texcoords;
varying float v_distance;

void main()
{
    vec4 viewspace_center = u_view * vec4(a_center, 1.0);
    v_distance = length(viewspace_center.xyz);
    vec4 viewspace_halfextents = vec4(a_texcoords.x - .5, a_texcoords.y - .5, 0., 0.) * a_size;

    // Outputs to fragment shader
    gl_Position = u_projection * (viewspace_center + viewspace_halfextents);
    v_texcoords = a_texcoords;
    v_color = a_color;
}

[fragment]

// Program inputs
uniform sampler2D u_textureMap;
uniform vec3 u_fogColor;
uniform float u_fogDistance;
uniform float u_time;

// Per-fragment inputs
varying vec3 v_color;
varying vec2 v_texcoords;
varying float v_distance;

void main()
{
    vec4 tex = texture2D(u_textureMap, v_texcoords.st);
    float alpha = tex.a * max(v_color.r, max(v_color.g, v_color.b));
    gl_FragColor = vec4(tex.rgb * v_color, alpha);

    if (u_fogDistance > 0.0)
    {
        float color_fog = clamp(1.0 - v_distance / u_fogDistance, 0.0, 1.0);
        if (v_distance > 2000.0)
        {
            float dither_range = max(u_fogDistance - 2000.0, 200.0);
            float dither_factor = clamp(1.0 - (v_distance - 2000.0) / dither_range, 0.0, 1.0);
            float dither = fract(sin(dot(gl_FragCoord.xy + u_time * 100.0, vec2(12.9898, 78.233))) * 43758.5453);
            if (dither > dither_factor)
                discard;
        }
    }
}
