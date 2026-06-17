[vertex]
uniform mat4 u_model;
uniform mat4 u_view;
uniform mat4 u_projection;
uniform float shellOffset;

attribute vec3 a_position;
attribute vec3 a_normal;
attribute vec2 a_texcoords;

varying vec3 v_fragnormal;
varying vec2 v_fragtexcoords;
varying vec3 v_fragposition;

void main()
{
    // Displace vertex along normal to create shell effect
    vec3 displacedPos = a_position + a_normal * shellOffset;

    vec4 worldpos = u_model * vec4(displacedPos, 1.0);
    v_fragnormal = normalize((u_model * vec4(a_normal, 0.0)).xyz);
    v_fragposition = worldpos.xyz;

    v_fragtexcoords = a_texcoords;

    gl_Position = u_projection * u_view * worldpos;
}

[fragment]
uniform vec4 u_color;
uniform sampler2D u_textureMap;
uniform vec3 u_camera_position;

varying vec3 v_fragnormal;
varying vec2 v_fragtexcoords;
varying vec3 v_fragposition;

void main()
{
    // Base texture for shield effect pattern
    vec4 baseTexture = texture2D(u_textureMap, v_fragtexcoords.st);

    // Consistent bright appearance regardless of viewing angle
    vec3 finalColor = baseTexture.rgb * u_color.rgb * 1.5;
    float finalAlpha = u_color.a * baseTexture.a;

    gl_FragColor = vec4(finalColor, finalAlpha);
}
