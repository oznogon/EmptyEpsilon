[vertex]
uniform mat4 u_view;
uniform mat4 u_projection;
uniform mat4 u_model;
uniform vec4 u_color;

attribute vec3 a_position;
attribute vec2 a_texcoords;
attribute vec3 a_normal; // Reused to pass particle direction

varying vec2 v_texcoords;

void main()
{
    v_texcoords = a_texcoords;

    // Transform center point to view space
    vec4 viewPos = u_view * u_model * vec4(a_position, 1.0);

    // Calculate billboard offset
    vec2 offset = (a_texcoords - 0.5) * u_color.a;

    // If we have a direction vector (length > 0), orient the billboard
    if (length(a_normal) > 0.01) {
        // Transform direction to view space (as a direction, not a point)
        vec3 viewDir = normalize((u_view * u_model * vec4(a_normal, 0.0)).xyz);

        // Calculate rotation angle from direction (atan2 gives angle of vector in XY plane)
        // Add π/2 to align the vertical texture with the direction vector
        float angle = atan(viewDir.y, viewDir.x) + 1.5707963;

        // Rotate the offset
        float cosA = cos(angle);
        float sinA = sin(angle);
        vec2 rotatedOffset = vec2(
            offset.x * cosA - offset.y * sinA,
            offset.x * sinA + offset.y * cosA
        );
        offset = rotatedOffset;
    }

    gl_Position = u_projection * (viewPos + vec4(offset, 0.0, 0.0));
}

[fragment]
uniform vec4 u_color;
uniform sampler2D u_textureMap;

varying vec4 v_color;
varying vec2 v_texcoords;

void main()
{
    gl_FragColor = texture2D(u_textureMap, v_texcoords.st) * vec4(u_color.rgb, 1.0);
}
