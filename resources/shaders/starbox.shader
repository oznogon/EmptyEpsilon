[vertex]

// Program inputs
uniform mat4 u_projection;
uniform mat4 u_view;
uniform float u_scale;

// Per-vertex inputs
attribute vec3 a_position;

// Per-vertex outputs
varying vec3 v_texcoords;

void main()
{
    // For texcoords, undo flipping the Z axis and rotation around X axis
    // from code.
    v_texcoords = vec3(a_position.x, a_position.z, -a_position.y);

    // We get rid of the translation component, so the box gets always centered around the camera.
    gl_Position = u_projection * mat4(mat3(u_view)) * vec4(u_scale * a_position, 1.);
}

[fragment]

// Program inputs
uniform samplerCube u_global_starbox;
uniform samplerCube u_local_starbox;
uniform float u_starbox_lerp;

// Per-fragment inputs.
varying vec3 v_texcoords;

vec3 fixSeam(vec3 dir)
{
    vec3 ad = abs(dir);
    float ma = max(max(ad.x, ad.y), ad.z);
    float sc = 0.0;
    if (ad.x != ma) sc = max(sc, ad.x);
    if (ad.y != ma) sc = max(sc, ad.y);
    if (ad.z != ma) sc = max(sc, ad.z);
    if (sc > ma * 0.992)
    {
        float bias = ma * 0.006;
        if (ad.x == ma)
            dir.x += sign(dir.x) * bias;
        else if (ad.y == ma)
            dir.y += sign(dir.y) * bias;
        else
            dir.z += sign(dir.z) * bias;
    }
    return dir;
}

void main()
{
    vec3 tc_global = fixSeam(v_texcoords);
    vec3 tc_local = fixSeam(v_texcoords);
    vec4 global_color = textureCube(u_global_starbox, tc_global);
    vec4 local_color = textureCube(u_local_starbox, tc_local);

    gl_FragColor = mix(global_color, local_color, u_starbox_lerp);
}
