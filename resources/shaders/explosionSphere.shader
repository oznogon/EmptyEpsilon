[vertex]
uniform mat4 u_model;
uniform mat4 u_view;
uniform mat4 u_projection;
uniform float u_scrollOffset;
uniform float u_time;
uniform float u_noiseScale;

attribute vec3 a_position;
attribute vec2 a_texcoords;
attribute vec3 a_normal;

varying vec2 fragtexcoords;
varying float noiseValue;

// 3D Simplex-style noise function
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 mod289(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 permute(vec4 x) { return mod289(((x*34.0)+1.0)*x); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

float snoise(vec3 v)
{
    const vec2 C = vec2(1.0/6.0, 1.0/3.0);
    const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);

    // First corner
    vec3 i  = floor(v + dot(v, C.yyy));
    vec3 x0 = v - i + dot(i, C.xxx);

    // Other corners
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min(g.xyz, l.zxy);
    vec3 i2 = max(g.xyz, l.zxy);

    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy;
    vec3 x3 = x0 - D.yyy;

    // Permutations
    i = mod289(i);
    vec4 p = permute(permute(permute(
        i.z + vec4(0.0, i1.z, i2.z, 1.0))
        + i.y + vec4(0.0, i1.y, i2.y, 1.0))
        + i.x + vec4(0.0, i1.x, i2.x, 1.0));

    // Gradients
    float n_ = 0.142857142857; // 1.0/7.0
    vec3 ns = n_ * D.wyz - D.xzx;

    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);

    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_);

    vec4 x = x_ *ns.x + ns.yyyy;
    vec4 y = y_ *ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);

    vec4 b0 = vec4(x.xy, y.xy);
    vec4 b1 = vec4(x.zw, y.zw);

    vec4 s0 = floor(b0)*2.0 + 1.0;
    vec4 s1 = floor(b1)*2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));

    vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
    vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww;

    vec3 p0 = vec3(a0.xy, h.x);
    vec3 p1 = vec3(a0.zw, h.y);
    vec3 p2 = vec3(a1.xy, h.z);
    vec3 p3 = vec3(a1.zw, h.w);

    // Normalize gradients
    vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    // Mix contributions
    vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    m = m * m;
    return 42.0 * dot(m*m, vec4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
}

// Multi-octave noise for more detailed displacement
float fbm(vec3 p)
{
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < 3; i++)
    {
        value += amplitude * snoise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }

    return value;
}

void main()
{
    fragtexcoords = a_texcoords;

    // Create animated noise by combining position and time
    vec3 noisePos = a_position * 2.0 + vec3(u_time * 0.3);

    // Calculate multi-octave noise for more detail
    float noise = fbm(noisePos);

    // Add slower-moving large-scale features
    noise += 0.3 * snoise(a_position * 0.5 + vec3(u_time * 0.15));

    // Store noise value for fragment shader (optional coloring)
    noiseValue = noise;

    // Displace vertex along normal direction
    // u_noiseScale controls the intensity of displacement
    vec3 displacedPosition = a_position + a_normal * noise * u_noiseScale;

    gl_Position = u_projection * u_view * u_model * vec4(displacedPosition, 1.0);
}

[fragment]
uniform vec4 u_color;
uniform sampler2D u_textureMap;
uniform float u_scrollOffset;

varying vec2 fragtexcoords;
varying float noiseValue;

void main()
{
    // Scroll texture coordinates horizontally (left to right)
    vec2 scrolledCoords = vec2(fragtexcoords.x + u_scrollOffset, fragtexcoords.y);

    // Use fract to wrap coordinates for continuous scrolling
    scrolledCoords.x = fract(scrolledCoords.x);

    // Sample texture
    vec4 texColor = texture2D(u_textureMap, scrolledCoords);

    // Apply color tint and alpha
    gl_FragColor = texColor * u_color;
    gl_FragColor.rgb *= u_color.a;

    // Optional: Slightly modulate brightness based on noise for extra detail
    // Vertices pushed outward are slightly brighter
    float brightnessMod = 1.0 + noiseValue * 0.15;
    gl_FragColor.rgb *= brightnessMod;
}
