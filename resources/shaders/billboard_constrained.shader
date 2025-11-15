[vertex]
uniform vec4 color;
uniform mat4 view;
uniform mat4 projection;
uniform mat4 model;
uniform vec3 constrained_axis;

attribute vec3 position;
attribute vec2 texcoords;

varying vec2 fragtexcoords;
varying vec4 fragcolor;

void main()
{
    fragtexcoords = texcoords;

    // Extract world position from model matrix
    vec3 world_pos = vec3(model[3][0], model[3][1], model[3][2]);

    // Transform the constrained axis by the model's rotation
    // This gives us the object's constrained direction in world space
    mat3 rotation = mat3(model);
    vec3 forward = normalize(rotation * constrained_axis);

    // Get camera direction from view matrix
    // In EmptyEpsilon's coordinate system, camera looks down -Z in view space
    vec3 camera_forward = -vec3(view[0][2], view[1][2], view[2][2]);

    // Project camera direction onto plane perpendicular to constrained axis
    vec3 to_camera = -camera_forward;
    vec3 projected_to_camera = to_camera - forward * dot(to_camera, forward);

    // Handle edge case: camera looking directly along the constrained axis
    float proj_length = length(projected_to_camera);
    if (proj_length < 0.001) {
        // Fall back to world up
        projected_to_camera = vec3(0.0, 0.0, 1.0) - forward * dot(vec3(0.0, 0.0, 1.0), forward);
        proj_length = length(projected_to_camera);
        if (proj_length < 0.001) {
            // If still degenerate, use world right
            projected_to_camera = vec3(1.0, 0.0, 0.0);
            proj_length = 1.0;
        }
    }
    projected_to_camera = projected_to_camera / proj_length;

    // Build orthonormal basis for the billboard quad
    vec3 constrained_right = projected_to_camera;
    vec3 constrained_up = normalize(cross(forward, constrained_right));

    // Build quad vertices using constrained basis vectors
    vec3 vertex_offset = constrained_right * (texcoords.x - 0.5) * color.a
                       + constrained_up * (texcoords.y - 0.5) * color.a;

    vec4 world_vertex = vec4(world_pos + vertex_offset, 1.0);
    gl_Position = projection * view * world_vertex;
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
