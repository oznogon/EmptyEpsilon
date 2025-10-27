[vertex]
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

attribute vec3 position;
attribute vec2 texcoords;

varying vec2 fragtexcoords;

void main()
{
    fragtexcoords = texcoords;
    gl_Position = projection * view * model * vec4(position, 1.0);
}

[fragment]
uniform vec4 color;
uniform sampler2D textureMap;
uniform float scrollOffset;

varying vec2 fragtexcoords;

void main()
{
    // Scroll texture coordinates horizontally (left to right)
    vec2 scrolledCoords = vec2(fragtexcoords.x + scrollOffset, fragtexcoords.y);

    // Use fract to wrap coordinates for continuous scrolling
    scrolledCoords.x = fract(scrolledCoords.x);

    gl_FragColor = texture2D(textureMap, scrolledCoords) * color;
    gl_FragColor.rgb *= color.a;
}
