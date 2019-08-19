//
//  CYRawTextureViewController.m
//  BeginOpenGLES
//
//  Created by Gocy on 2019/8/16.
//  Copyright © 2019 Gocy. All rights reserved.
//

#import "CYRawTextureViewController.h"
#import <OpenGLES/ES2/gl.h>

@interface CYRawTextureViewController (){}

@property (nonatomic, strong) EAGLContext *context;

@end


typedef struct {
    float positionCoords[3];
    float textureCoords[2];
} SceneVertex;

const SceneVertex SceneVertices[] = {
    {{-1, 1, 0}, {0, 1}},
    {{-1, -1, 0}, {0, 0}},
    {{1, 1, 0}, {1, 1}},
    {{1, -1, 0}, {1, 0}},
};


@implementation CYRawTextureViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.whiteColor;
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext: self.context];
    
    CGSize screenSize = UIScreen.mainScreen.bounds.size;
    CAEAGLLayer *renderLayer = [CAEAGLLayer new];
    renderLayer.frame = CGRectMake(0, 100, screenSize.width, screenSize.width/0.8);
    renderLayer.contentsScale = UIScreen.mainScreen.scale;
    
    [self.view.layer addSublayer:renderLayer];
    [self bindRenderLayer:renderLayer];
    
    UIImage *image = [UIImage imageNamed:@"batman"];
    
    GLuint textureID = [self textureFromImage:image];
    
    CGSize maxSize = CGSizeMake([self drawableWidth], [self drawableHeight]);
    CGSize drawSize = image.size;
    CGFloat widthRatio = image.size.width / maxSize.width;
    CGFloat heightRatio = image.size.height / maxSize.height;
    
    CGFloat ratio = MAX(widthRatio, heightRatio);
    if (ratio > 1) {
        drawSize = CGSizeMake(floor(drawSize.width / ratio), floor(drawSize.height / ratio));
    }
    CGRect drawRect = CGRectMake(((maxSize.width-drawSize.width)/2), ((maxSize.height-drawSize.height)/2), drawSize.width, drawSize.height);
    NSLog(@"%@", NSStringFromCGRect(drawRect));
    
    glViewport(((maxSize.width-drawSize.width)/2), ((maxSize.height-drawSize.height)/2), drawSize.width, drawSize.height);
    
    GLuint program = [self programWithShader:@"CommonShader"];
    
    glUseProgram(program);
    
    GLuint positionSlot = glGetAttribLocation(program, "Position");
    GLuint textureSlot = glGetUniformLocation(program, "Texture");
    GLuint textureCoordsSlot = glGetAttribLocation(program, "TextureCoords");
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glUniform1i(textureSlot, 0);
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(SceneVertices), SceneVertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(SceneVertex), (const GLvoid *)offsetof(SceneVertex, positionCoords));
    
    glEnableVertexAttribArray(textureCoordsSlot);
    glVertexAttribPointer(textureCoordsSlot, 2, GL_FLOAT, GL_FALSE, sizeof(SceneVertex), (const GLvoid *)offsetof(SceneVertex, textureCoords));
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, sizeof(SceneVertices) / sizeof(SceneVertices[0]));
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
    
    glDeleteBuffers(1, &vertexBuffer);
    vertexBuffer = 0;
    
}


#pragma mark - Helpers

- (void)bindRenderLayer:(CALayer <EAGLDrawable> *)layer
{
    GLuint renderBuffer;
    GLuint frameBuffer;
    
    glGenRenderbuffers(1, &renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffer);

}

- (GLuint)textureFromImage:(UIImage *)image
{
    CGImageRef imageRef = image.CGImage;
    
    GLuint width = (GLuint)CGImageGetWidth(imageRef);
    GLuint height = (GLuint)CGImageGetHeight(imageRef);
    
    CGRect rect = CGRectMake(0, 0, width, height);
    
    // draw image
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc(width * height * 4);
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1, -1);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, imageRef);
    
    // get texture
    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    // mapping, texture -> pixel
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    // cleaning
    glBindBuffer(GL_TEXTURE_2D, 0);
    
    CGContextRelease(context);
    free(imageData);
    
    return textureID;
}

- (GLuint)compileShaderWithName:(NSString *)name type:(GLenum)type
{
    NSString *shaderPath = [NSBundle.mainBundle pathForResource:name ofType:type == GL_VERTEX_SHADER ? @"vsh" : @"fsh"];
    NSError *error;
    
    NSString *shaderCode = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"Unable to load shader: %@", error);
        exit(1);
    }
    
    GLuint shader = glCreateShader(type);
    
    const char *shaderSource = [shaderCode UTF8String];
    int sourceLength = (int)[shaderCode length];
    glShaderSource(shader, 1, &shaderSource, &sourceLength);
    
    glCompileShader(shader);
    
    GLint compileResult;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileResult);
    
    if (compileResult == GL_FALSE) {
        GLchar msg[256];
        glGetShaderInfoLog(shader, sizeof(msg), 0, &msg[0]);
        NSString *errorMsg = [NSString stringWithUTF8String:msg];
        NSLog(@"Compile failed: %@", errorMsg);
        exit(1);
    }
    
    return shader;
}

// 获取渲染缓存宽度
- (GLint)drawableWidth {
    GLint backingWidth;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    
    return backingWidth;
}

// 获取渲染缓存高度
- (GLint)drawableHeight {
    GLint backingHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    return backingHeight;
}


- (GLuint)programWithShader:(NSString *)shaderName
{
    GLuint vertexShader = [self compileShaderWithName:shaderName type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShaderWithName:shaderName type:GL_FRAGMENT_SHADER];
    
    GLuint program = glCreateProgram();
    
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    
    glLinkProgram(program);
    
    GLint linkResult;
    glGetProgramiv(program, GL_LINK_STATUS, &linkResult);
    
    if (linkResult == GL_FALSE) {
        GLchar msg[256];
        glGetProgramInfoLog(program, sizeof(msg), 0, &msg[0]);
        NSString *errorMsg = [NSString stringWithUTF8String:msg];
        NSLog(@"Link failed: %@", errorMsg);
        exit(1);
    }
    return program;
}

@end

