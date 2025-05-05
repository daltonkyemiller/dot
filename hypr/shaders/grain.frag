
precision mediump float;
varying vec2 v_texcoord;

uniform sampler2D tex;

void main() {
    vec2 tc = vec2(v_texcoord.x, v_texcoord.y);

    vec4 color = texture2D(tex, tc);


    // Add noise
    float noise = (fract(sin(dot(tc.xy, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 0.1;

    color.rgb += noise;



    // Apply retro orange color transformation
    // vec3 retroColor = vec3(
    //     color.r * 1.2,  // Boost the red channel
    //     color.g * 1.0,  // Keep the green channel as is
    //     color.b * 0.8   // Reduce the blue channel
    // );
    // color.rgb = retroColor;

    // Cutoff
    if (tc.y > 1.0 || tc.x < 0.0 || tc.x > 1.0 || tc.y < 0.0)
        color = vec4(0.0);

    // Apply
    gl_FragColor = color;
}
