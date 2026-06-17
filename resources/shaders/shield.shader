[vertex]
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform float shellOffset;

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

    fragtexcoords = texcoords;

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

    // Consistent bright appearance regardless of viewing angle
    vec3 finalColor = baseTexture.rgb * color.rgb * 1.5;
    float finalAlpha = color.a * baseTexture.a;

    gl_FragColor = vec4(finalColor, finalAlpha);
}
