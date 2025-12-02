[vertex]
uniform mat4 u_model;
uniform mat4 u_view;
uniform mat4 u_projection;

attribute vec3 a_position;
attribute vec2 a_texcoords;

varying vec2 fragtexcoords;

void main()
{
    fragtexcoords = a_texcoords;
    gl_Position = u_projection * u_view * u_model * vec4(a_position, 1.0);
}

[fragment]
uniform vec4 u_color;
uniform sampler2D u_textureMap;
uniform float u_scrollOffset;

varying vec2 fragtexcoords;

void main()
{
    // Scroll texture coordinates horizontally (left to right)
    vec2 scrolledCoords = vec2(fragtexcoords.x + u_scrollOffset, fragtexcoords.y);

    // Use fract to wrap coordinates for continuous scrolling
    scrolledCoords.x = fract(scrolledCoords.x);

    gl_FragColor = texture2D(u_textureMap, scrolledCoords) * u_color;
    gl_FragColor.rgb *= u_color.a;
}
