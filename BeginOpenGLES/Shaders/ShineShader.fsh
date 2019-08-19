precision mediump float;

uniform sampler2D Texture;
varying vec2 TextureCoordsVarying;
//uniform float Time;
varying float animationTime;
varying float animationProgress;

const float PI = 3.1415926;

void main (void) {
//    if (animationTime < 2.0) {
        vec4 mask = texture2D(Texture, TextureCoordsVarying);
        float progress = animationProgress;
        
        vec4 white = vec4(1, 1, 1, 1);
        progress = abs(sin(progress * PI));
        vec4 targetColor = mask * progress + white * (1.0-progress);
        gl_FragColor = targetColor;
//    } else {
//        gl_FragColor = vec4(0,0,0,0);
//    }
}

