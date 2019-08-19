//
//  CYEffectViewController.m
//  BeginOpenGLES
//
//  Created by Gocy on 2019/8/17.
//  Copyright © 2019 Gocy. All rights reserved.
//

#import "CYEffectViewController.h"
#import "CYOpenGLTools.h"

typedef struct {
    float Position[3];
    float TextureCoords[2];
} EffectVertex;

static const int kVerticesCount = 4;

@interface CYEffectViewController (){}

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, assign) EffectVertex *vertices;
@property (nonatomic, assign) GLuint textureID;

@property (nonatomic, assign) GLuint currentProgram;
@property (nonatomic, assign) CGSize drawSize;
@property (nonatomic, assign) GLuint currentVertexBuffer;


@property (nonatomic, assign) GLuint renderBufferID;
@property (nonatomic, assign) GLuint frameBufferID;

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CGFloat firstDisplayTimestamp;

@property (nonatomic, strong) NSString *currentShaderName;

@end

@implementation CYEffectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupContext];
    
    [self drawWithShader:@"SpiritShader"];
    
    [self startTimer];
}

- (void)setupContext
{
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
    
    self.vertices = malloc(sizeof(EffectVertex) * kVerticesCount);
    self.vertices[0] = (EffectVertex){{-1, -1, 0},{0, 0}};
    self.vertices[1] = (EffectVertex){{-1, 1, 0},{0, 1}};
    self.vertices[2] = (EffectVertex){{1, -1, 0},{1, 0}};
    self.vertices[3] = (EffectVertex){{1, 1, 0},{1, 1}};
    
    self.textureID = [CYOpenGLTools textureFromImage:[UIImage imageNamed:@"sample"]];
    
    GLuint t1 = [CYOpenGLTools textureFromImage:[UIImage imageNamed:@"sample"]];
//    GLuint t2 = 0;//[CYOpenGLTools textureFromImage:[UIImage imageNamed:@"batman"]];
//
//    NSLog(@"%i %i %i",self.textureID, t1, t2);
    CAEAGLLayer *layer = [CAEAGLLayer new];
    layer.frame = CGRectMake(0, 100, self.view.bounds.size.width, self.view.bounds.size.width);
    layer.contentsScale = UIScreen.mainScreen.scale;
    layer.backgroundColor = UIColor.clearColor.CGColor;
    self.drawSize = CGSizeMake(layer.bounds.size.width * UIScreen.mainScreen.scale, layer.bounds.size.height * UIScreen.mainScreen.scale);
    [CYOpenGLTools bindRenderLayer:layer toContext:self.context withRenderBuffer:&_renderBufferID frameBuffer:&_frameBufferID];
    
    [self.view.layer addSublayer:layer];
    
}

- (void)drawWithShader:(NSString *)shaderName
{
    GLuint program = [CYOpenGLTools programWithShader:shaderName];
    
    self.currentProgram = program;
    [self _prebindUnchangeValues];
    [self _drawUsingCurrentProgram];
}

- (void)_prebindUnchangeValues
{
    if (self.currentProgram == 0) {
        return ;
    }
    
    if (_currentVertexBuffer != 0) {
        glDeleteBuffers(1, &_currentVertexBuffer);
        _currentVertexBuffer = 0;
    }
    
    glUseProgram(self.currentProgram);
    glViewport(0, 0, self.drawSize.width, self.drawSize.height);
    
    GLuint positionSlot = glGetAttribLocation(self.currentProgram, "Position");
    GLuint textureSlot = glGetUniformLocation(self.currentProgram, "Texture");
    GLuint textureCoordSlot = glGetAttribLocation(self.currentProgram, "TextureCoords");
    
    glGenBuffers(1, &_currentVertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _currentVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(EffectVertex) * kVerticesCount, self.vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(EffectVertex), (const GLvoid *)offsetof(EffectVertex, Position));
    
    glEnableVertexAttribArray(textureCoordSlot);
    glVertexAttribPointer(textureCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(EffectVertex), (const GLvoid *)offsetof(EffectVertex, TextureCoords));
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureID);
    glUniform1i(textureSlot, 0);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferID);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBufferID);
    
}

- (void)_drawUsingCurrentProgram
{
    if (self.currentProgram != 0) {
        
        GLuint timeSlot = glGetUniformLocation(self.currentProgram, "Time");
        
        CGFloat timeElapsed = self.displayLink.timestamp - self.firstDisplayTimestamp;
        glUniform1f(timeSlot, timeElapsed);
        
        glClearColor(1, 1, 1, 1);
        glClear(GL_COLOR_BUFFER_BIT);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, kVerticesCount);
        [self.context presentRenderbuffer:GL_RENDERBUFFER];
    }
    
//    glBindRenderbuffer(GL_RENDERBUFFER, 0);
//    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

- (GLint)drawableWidth {
    GLint backingWidth;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    
    return backingWidth;
}


#pragma mark - Timer

- (void)redraw
{
    if (self.firstDisplayTimestamp == 0) {
        self.firstDisplayTimestamp = self.displayLink.timestamp;
    }
    
    [self _drawUsingCurrentProgram];
}

- (void)startTimer
{
    if (self.displayLink) {
        [self.displayLink invalidate];
        [self.displayLink removeFromRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
        self.displayLink = nil;
    }
    
    self.firstDisplayTimestamp = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(redraw)];
    self.displayLink.preferredFramesPerSecond = 60;
    [self.displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}

@end
