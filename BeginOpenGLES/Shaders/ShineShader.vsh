
attribute vec4 Position;
attribute vec2 TextureCoords;
varying vec2 TextureCoordsVarying;
uniform float Time;
varying float animationProgress;
varying float animationTime;

const float duration = 1.0;

void main (void) {
    
//    if (Time >= 2.0) {
//        gl_Position = vec4(Position.x * 0.5, Position.yzw);
//    } else {
        gl_Position = Position;
//    }
    animationTime = Time;
    animationProgress = mod(Time, duration) / duration;
    TextureCoordsVarying = TextureCoords;
}
