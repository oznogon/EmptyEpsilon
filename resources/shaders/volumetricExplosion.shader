[vertex]
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform vec2 resolution;
uniform float billboardSize;

attribute vec3 position;
attribute vec2 texcoords;

varying vec2 fragCoord;

void main()
{
    // Convert normalized texcoords [0,1] to pixel coordinates
    fragCoord = texcoords * resolution;

    // Billboard-style vertex positioning (camera-facing quad)
    gl_Position = projection * ((view * model * vec4(position, 1.0)) + vec4((texcoords.x - 0.5) * billboardSize, (texcoords.y - 0.5) * billboardSize, 0.0, 0.0));
}

[fragment]
#define pi 3.14159265
#define R(p, a) p=cos(a)*p+sin(a)*vec2(p.y, -p.x)

uniform vec2 resolution;
uniform vec3 startColor;
uniform float time;
uniform float explosionAlpha;
uniform float qualityFactor;  // 0.0 (low) to 1.0 (high)
uniform sampler2D textureMap;

varying vec2 fragCoord;

// iq's noise
float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
    vec2 rg = texture2D( textureMap, (uv+ 0.5)/256.0 ).yx;
    return 1. - 0.82*mix( rg.x, rg.y, f.z );
}

float fbm( vec3 p )
{
   return noise(p*.06125)*.5 + noise(p*.125)*.25 + noise(p*.25)*.125 + noise(p*.4)*.2;
}

float Sphere( vec3 p, float r )
{
    return length(p)-r;
}

const float nudge = 4.;	// size of perpendicular vector
float normalizer = 1.0 / sqrt(1.0 + nudge*nudge);	// pythagorean theorem on that perpendicular to maintain scale
float SpiralNoiseC(vec3 p)
{
    float n = -mod(time * 0.2,-2.); // noise amount
    float iter = 2.0;
    int iterations = 6;
    for (int i = 0; i < iterations; i++)
    {
        // add sin and cos scaled inverse with the frequency
        n += -abs(sin(p.y*iter) + cos(p.x*iter)) / iter;	// abs for a ridged look
        // rotate by adding perpendicular and scaling down
        p.xy += vec2(p.y, -p.x) * nudge;
        p.xy *= normalizer;
        // rotate on other axis
        p.xz += vec2(p.z, -p.x) * nudge;
        p.xz *= normalizer;
        // increase the frequency
        iter *= 1.733733;
    }
    return n;
}

float VolumetricExplosion(vec3 p)
{
    float final = Sphere(p,4.);
    final += noise(p*12.5)*.2;
    final += SpiralNoiseC(p.zxy*0.4132+333.)*3.0; //1.25;

    return final;
}

float map(vec3 p)
{
    // Option 3: Simple time-based rotation
    R(p.xz, time*0.1);

    float VolExplosion = VolumetricExplosion(p/0.5)*0.5; // scale

    return VolExplosion;
}
//--------------------------------------------------------------

// assign color to the media
vec3 computeColor( float density, float radius )
{
    // color based on density alone, gives impression of occlusion within
    // the media
    vec3 result = mix( vec3(1.0,0.9,0.8), vec3(0.4,0.15,0.1), density );

    // color added to the media
    vec3 colCenter = 7.*vec3(0.8,1.0,1.0);
    vec3 colEdge = 1.5*vec3(0.48,0.53,0.5);
    result *= mix( colCenter, colEdge, min( (radius+.05)/.9, 1.15 ) );

    return result;
}

bool RaySphereIntersect(vec3 org, vec3 dir, out float near, out float far)
{
    float b = dot(dir, org);
    float c = dot(org, org) - 8.;
    float delta = b * b - c;
    if (delta < 0.0)
        return false;
    float deltasqrt = sqrt(delta);
    near = -b - deltasqrt;
    far = -b + deltasqrt;
    return far > 0.0;
}

void main()
{
    float key = 0.0;

    vec2 uv = fragCoord/resolution;

    // ro: ray origin
    // rd: direction of the ray
    vec3 rd = normalize(vec3((fragCoord.xy-0.5*resolution)/resolution.y, 1.));
    vec3 ro = vec3(0., 0., -6.+key*1.6);

    // ld, td: local, total density
    // w: weighting factor
    float ld=0., td=0., w=0.;

    // t: length of the ray
    // d: distance function
    float d=1., t=0.;

    const float h = 0.1;

    vec4 sum = vec4(0.0);

    float min_dist=0.0, max_dist=0.0;

    if(RaySphereIntersect(ro, rd, min_dist, max_dist))
    {

    t = min_dist*step(t,min_dist);

    // Dynamic quality adjustment based on screen-space size
    // High quality (far): More iterations, tighter thresholds
    // Low quality (close): Fewer iterations, looser thresholds
    float maxIterations = 16.0 + qualityFactor * 40.0;  // 16-56 iterations
    float densityThreshold = 0.95 - qualityFactor * 0.15;  // 0.95-0.80
    float alphaThreshold = 0.98 - qualityFactor * 0.08;    // 0.98-0.90

    // raymarch loop
    for (int i = 0; i < 56; i++)
    {
        // Dynamic exit based on quality
        if (float(i) >= maxIterations) break;

        vec3 pos = ro + t*rd;

        // Loop break conditions - adjusted by quality factor
        if(td>densityThreshold || d<0.12*t || t>10. || sum.a > alphaThreshold || t>max_dist) break;

        // evaluate distance function
        float d = map(pos);

        d = abs(d)+0.07;

        // change this string to control density
        d = max(d,0.03);

        // point light calculations
        vec3 ldst = vec3(0.0)-pos;
        float lDist = max(length(ldst), 0.001);

        // the color of light
        vec3 lightColor=vec3(1.0,0.5,0.25);

        sum.rgb+=(startColor/exp(lDist*lDist*lDist*.08)/30.); // bloom

        if (d<h)
        {
            // compute local density
            ld = h - d;

            // compute weighting factor
            w = (1. - td) * ld;

            // accumulate density
            td += w + 1./200.;

            vec4 col = vec4( computeColor(td,lDist), td );

            // emission
            sum += sum.a * vec4(sum.rgb, 0.0) * 0.2 / lDist;

            // uniform scale density
            col.a *= 0.2;
            // colour by alpha
            col.rgb *= col.a;
            // alpha blend in contribution
            sum = sum + col*(1.0 - sum.a);

        }

        td += 1./70.;

        // Dynamic step size: larger steps for lower quality (faster traversal)
        float stepMultiplier = 1.0 + (1.0 - qualityFactor) * 0.5;  // 1.0x-1.5x
        t += max(d*0.25*stepMultiplier, 0.01);
    }

    // simple scattering
    sum *= 1. / exp( ld * 0.2 ) * 0.9;

    sum = clamp( sum, 0.0, 1.0 );

    sum.xyz = sum.xyz*sum.xyz*(3.0-2.0*sum.xyz);

    }

    gl_FragColor = vec4(sum.xyz, explosionAlpha);
}
