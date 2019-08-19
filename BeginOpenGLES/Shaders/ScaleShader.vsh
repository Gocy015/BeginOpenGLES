
attribute vec4 Position;
attribute vec2 TextureCoords;
varying vec2 TextureCoordsVarying;

uniform float Time;

const float duration = 1.0;
const float PI = 3.1415926;

void main (void) {
    float progress = mod(Time, duration) / duration;
    progress = abs(sin(progress * PI)) * 0.2;
    gl_Position = vec4(Position.x * (1.0+progress), Position.y * (1.0+progress) ,Position.zw);
    
    TextureCoordsVarying = TextureCoords;
}
