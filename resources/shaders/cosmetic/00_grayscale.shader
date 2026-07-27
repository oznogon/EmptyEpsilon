// Port of https://www.shadertoy.com/view/4tlyDN by aureliendrouet
// This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License. 

[vertex]
attribute vec2 a_position;
attribute vec2 a_texcoords;

varying vec2 v_texcoords;

void main()
{
    v_texcoords = a_texcoords;
    gl_Position = vec4(a_position, 0.0, 1.0);
}

[fragment]
uniform sampler2D u_texture;
uniform vec2 u_screenSize;

varying vec2 v_texcoords;

void main()
{
    vec4 sample = texture2D(u_texture, v_texcoords);
    float gray = 0.2126 * sample.r + 0.7152 * sample.g + 0.0722 * sample.b;
    // gray
    gl_FragColor = vec4(gray, gray, gray, 1.0);
    // green
    // gl_FragColor = vec4(0.0, gray, 0.0, 1.0);
}
