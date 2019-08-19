//
//  CYGLKViewController.m
//  BeginOpenGLES
//
//  Created by Gocy on 2019/8/15.
//  Copyright © 2019 Gocy. All rights reserved.
//

#import "CYGLKViewController.h"

typedef struct {
    float Position[3];
    float Color[4];
} Vertex;

const Vertex Vertices[] = {
    {{1,-1,0}, {1,0,0,1}},
    {{1,1,0}, {0,1,0,1}},
    {{-1,1,0}, {0,0,1,1}},
    {{-1,-1,0}, {1,1,1,1}},
};

const GLubyte Indices[] = {
    0,1,2,
    2,3,0
};

@interface CYGLKViewController ()<GLKViewDelegate>

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) GLKBaseEffect *effect;

@property (nonatomic, assign) BOOL increasing;
@property (nonatomic, assign) float curRed;
@property (nonatomic, assign) double rotation;


@property (nonatomic, assign) GLuint vertexBuffer;
@property (nonatomic, assign) GLuint indexBuffer;


@end

@implementation CYGLKViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    GLKView *glView = (GLKView *)self.view;
    glView.context = self.context;
    glView.delegate = self;
    
    [glView display];
    _curRed = 0;
    _increasing = YES;
    self.preferredFramesPerSecond = 60;
    
    [self setupGL];
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    self.effect = [GLKBaseEffect new];
    glGenBuffers(1, &_vertexBuffer); //size? why 1
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer); // it's like alias, GL_ARRAY_BUFFER now refers to _vertexBuffer
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
//    glGenBuffers(1, &_indexBuffer);
//    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
//    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
    CGRect refRect = [UIScreen.mainScreen bounds];
    float aspect = fabs(refRect.size.width / refRect.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(30), aspect, 4, 10);
    self.effect.transform.projectionMatrix = projectionMatrix;
    
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    self.effect = nil;
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
}

- (void)dealloc
{
    [self tearDownGL];
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.paused = !self.paused;
    NSLog(@"timeSinceLastUpdate: %f", self.timeSinceLastUpdate);
    NSLog(@"timeSinceLastDraw: %f", self.timeSinceLastDraw);
    NSLog(@"timeSinceFirstResume: %f", self.timeSinceFirstResume);
    NSLog(@"timeSinceLastResume: %f", self.timeSinceLastResume);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
//    glClearColor(_curRed, 0, 0, 1);
//    glClear(GL_COLOR_BUFFER_BIT);
    
    [self.effect prepareToDraw];
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
//    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *)offsetof(Vertex, Color));
    
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, (const GLvoid *)Indices);
}

// this is more or less a private func
- (void)update
{
//    if (_increasing) {
//        _curRed += 0.01;
//    } else {
//        _curRed -= 0.01;
//    }
//
//    if (_curRed >= 1) {
//        _curRed = 1;
//        _increasing = NO;
//    }
//
//    if (_curRed <= 0) {
//        _curRed = 0;
//        _increasing = YES;
//    }
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0, 0, -8);
    _rotation += 90 * self.timeSinceLastUpdate;
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(_rotation), 0, 1, 0);
    
    self.effect.transform.modelviewMatrix = modelViewMatrix;
}


@end
