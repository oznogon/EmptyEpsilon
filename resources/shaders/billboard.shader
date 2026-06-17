[vertex]
uniform mat4 u_view;
uniform mat4 u_projection;
uniform mat4 u_model;
uniform vec4 u_color;

attribute vec3 a_position;
attribute vec2 a_texcoords;

varying vec2 v_texcoords;
varying float v_distance;

void main()
{
    v_texcoords = a_texcoords;
    vec4 modelview_pos = u_view * u_model * vec4(a_position, 1.0);
    v_distance = length(modelview_pos.xyz);
    gl_Position = u_projection * (modelview_pos + vec4((a_texcoords.x - 0.5) * u_color.a, (a_texcoords.y - 0.5) * u_color.a, 0.0, 0.0));
}

[fragment]
uniform vec4 u_color;
uniform sampler2D u_textureMap;
uniform vec3 u_fogColor;
uniform float u_fogDistance;
uniform float u_time;

varying vec4 v_color;
varying vec2 v_texcoords;
varying float v_distance;

void main()
{
    vec4 tex = texture2D(u_textureMap, v_texcoords.st);
    if (tex.a < 0.02)
        discard;
    float near_fade = clamp(v_distance / 400.0, 0.0, 1.0);
    float alpha = tex.a * u_color.g * near_fade;
    gl_FragColor = vec4(tex.rgb * u_color.r * (tex.a * near_fade), alpha);

    if (u_fogDistance > 0.0)
    {
        float color_fog = clamp(1.0 - v_distance / u_fogDistance, 0.0, 1.0);
        if (v_distance > 1000.0)
        {
            float alpha_range = max(u_fogDistance - 1000.0, 200.0);
            float alpha_factor = clamp(1.0 - (v_distance - 1000.0) / alpha_range, 0.0, 1.0);
            gl_FragColor.a *= alpha_factor;
        }
    }
}
