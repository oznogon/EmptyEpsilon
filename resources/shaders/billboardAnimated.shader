[vertex]
uniform vec4 u_color;
uniform mat4 u_view;
uniform mat4 u_projection;
uniform mat4 u_model;
uniform vec4 u_spriteSheetParams; // x=columns, y=rows, z=currentFrame, w=unused

attribute vec3 a_position;
attribute vec2 a_texcoords;

varying vec2 fragtexcoords;
varying vec4 fragcolor;
varying float animProgress;

void main()
{
    // Calculate sprite sheet texture coordinates
    float columns = u_spriteSheetParams.x;
    float rows = u_spriteSheetParams.y;
    float frame = u_spriteSheetParams.z;

    // Calculate animation progress (0.0 to 1.0)
    float totalFrames = columns * rows;
    animProgress = frame / (totalFrames - 1.0);

    // Calculate the column and row for this frame
    float column = mod(frame, columns);
    float row = floor(frame / columns);

    // Calculate the size of one frame in UV space
    float frameWidth = 1.0 / columns;
    float frameHeight = 1.0 / rows;

    // Calculate the offset for this frame
    float offsetX = column * frameWidth;
    float offsetY = row * frameHeight;

    // Scale and offset the texture coordinates to select the correct frame
    fragtexcoords = vec2(
        offsetX + a_texcoords.x * frameWidth,
        offsetY + a_texcoords.y * frameHeight
    );

    // Billboard transformation: apply position in world space, then offset in view space
    gl_Position = u_projection * ((u_view * u_model * vec4(a_position, 1.0)) + vec4((a_texcoords.x - 0.5) * u_color.a, (a_texcoords.y - 0.5) * u_color.a, 0.0, 0.0));
    fragcolor = vec4(u_color.rgb, 1.0);
}

[fragment]
uniform sampler2D u_textureMap;

varying vec4 fragcolor;
varying vec2 fragtexcoords;
varying float animProgress;

void main()
{
    vec4 texColor = texture2D(u_textureMap, fragtexcoords.st);

    // Fade out in the second half of the animation
    float fadeStart = 0.5;
    float fadeAmount = 1.0;
    if (animProgress > fadeStart) {
        // Map progress from [0.5, 1.0] to [1.0, 0.0]
        fadeAmount = 1.0 - ((animProgress - fadeStart) / (1.0 - fadeStart));
    }

    gl_FragColor = texColor * fragcolor * vec4(1.0, 1.0, 1.0, fadeAmount);
}
