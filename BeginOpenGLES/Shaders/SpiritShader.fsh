precision mediump float;

uniform sampler2D Texture;
varying vec2 TextureCoordsVarying;
uniform float Time;

const float duration = 1.0;
const float PI = 3.1415926;

const float maxScale = 0.2;

void main (void) {
    vec4 mask = texture2D(Texture, TextureCoordsVarying);
    float progress = mod(Time, duration) / duration;
    progress = abs(sin(PI * progress)); // 0 ~ 1

    float maxValue = 1.0 - progress * maxScale / 2.0;

    float minValue = progress * maxScale / 2.0;

    float range = maxValue - minValue;

    float x = TextureCoordsVarying.x * range + minValue;
    float y = TextureCoordsVarying.y * range + minValue;


    vec2 maskCoords = vec2(x, y);
    vec4 spiritMask = texture2D(Texture, maskCoords);
    gl_FragColor = mask + spiritMask * 0.2;
}
