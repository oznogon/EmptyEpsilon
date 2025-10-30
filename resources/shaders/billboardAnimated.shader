[vertex]
uniform vec4 color;
uniform mat4 view;
uniform mat4 projection;
uniform mat4 model;
uniform vec4 u_spriteSheetParams; // x=columns, y=rows, z=currentFrame, w=unused

attribute vec3 position;
attribute vec2 texcoords;

varying vec2 fragtexcoords;
varying vec4 fragcolor;

void main()
{
    // Calculate sprite sheet texture coordinates
    float columns = u_spriteSheetParams.x;
    float rows = u_spriteSheetParams.y;
    float frame = u_spriteSheetParams.z;

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
        offsetX + texcoords.x * frameWidth,
        offsetY + texcoords.y * frameHeight
    );

    // Billboard transformation: apply position in world space, then offset in view space
    gl_Position = projection * ((view * model * vec4(position, 1.0)) + vec4((texcoords.x - 0.5) * color.a, (texcoords.y - 0.5) * color.a, 0.0, 0.0));
    fragcolor = vec4(color.rgb, 1.0);
}

[fragment]
uniform sampler2D textureMap;

varying vec4 fragcolor;
varying vec2 fragtexcoords;

void main()
{
    gl_FragColor = texture2D(textureMap, fragtexcoords.st) * fragcolor;
}
