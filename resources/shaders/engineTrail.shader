[vertex]

// Program inputs
uniform mat4 projection;
uniform mat4 view;

// Per-vertex inputs
attribute vec3 position;
attribute vec3 color;
attribute vec2 texcoord;

// Per-vertex outputs
varying vec3 fragcolor;
varying vec2 fragtexcoord;

void main()
{
    gl_Position = projection * view * vec4(position, 1.0);
    fragcolor = color;
    fragtexcoord = texcoord;
}

[fragment]

// Per-fragment inputs
varying vec3 fragcolor;
varying vec2 fragtexcoord;

// Texture sampler
uniform sampler2D texture;

void main()
{
    vec4 texel = texture2D(texture, fragtexcoord);
    gl_FragColor = vec4(fragcolor, 1.0) * texel;
}
