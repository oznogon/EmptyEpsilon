[vertex]
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform float shellOffset;
uniform float impactAngle;
uniform float impactTime;

attribute vec3 position;
attribute vec3 normal;
attribute vec2 texcoords;

varying vec3 fragnormal;
varying vec2 fragtexcoords;
varying vec3 fragposition;

void main()
{
    // Displace vertex along normal to create shell effect
    vec3 displacedPos = position + normal * shellOffset;

    vec4 worldpos = model * vec4(displacedPos, 1.0);
    fragnormal = normalize((model * vec4(normal, 0.0)).xyz);
    fragposition = worldpos.xyz;

    // Animate texture coordinates based on impact angle
    // Convert impact angle to radians and create scroll direction
    float angleRad = radians(impactAngle);
    vec2 scrollDir = vec2(cos(angleRad), sin(angleRad));

    // Scroll texture in opposite direction of impact
    float scrollSpeed = 2.0;
    vec2 scrollOffset = -scrollDir * impactTime * scrollSpeed;
    fragtexcoords = texcoords + scrollOffset;

    gl_Position = projection * view * worldpos;
}

[fragment]
uniform vec4 color;
uniform sampler2D textureMap;
uniform vec3 cameraPosition;

varying vec3 fragnormal;
varying vec2 fragtexcoords;
varying vec3 fragposition;

void main()
{
    // Base texture for shield effect pattern
    vec4 baseTexture = texture2D(textureMap, fragtexcoords.st);

    // Calculate view direction for rim lighting
    vec3 viewDir = normalize(cameraPosition - fragposition);

    // Rim lighting effect - brighten edges
    float rimFactor = 1.0 - max(0.0, dot(fragnormal, viewDir));
    float rimIntensity = pow(rimFactor, 2.0);

    // Combine texture, color, and rim effect with intensified color
    vec3 finalColor = (baseTexture.rgb * color.rgb + rimIntensity * color.rgb) * 1.5;
    // Include texture alpha so black areas in texture are transparent
    float finalAlpha = color.a * baseTexture.a * (0.3 + rimIntensity * 0.7);

    gl_FragColor = vec4(finalColor, finalAlpha);
}
