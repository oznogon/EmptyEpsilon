[vertex]

// Program inputs
uniform mat4 projection;
uniform mat4 view;

// Per-vertex inputs
attribute vec3 position;
attribute vec3 color;

// Per-vertex outputs
varying vec3 fragcolor;

void main()
{
    gl_Position = projection * view * vec4(position, 1.0);
    fragcolor = color;
}

[fragment]

// Per-fragment inputs
varying vec3 fragcolor;

void main()
{
    gl_FragColor = vec4(fragcolor, 1.0);
}
