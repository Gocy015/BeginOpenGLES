//
//  CYTextureViewController.m
//  BeginOpenGLES
//
//  Created by Gocy on 2019/8/16.
//  Copyright © 2019 Gocy. All rights reserved.
//

#import "CYTextureViewController.h"

@interface CYTextureViewController (){}

@property (nonatomic, strong) GLKBaseEffect *baseEffect;
@property (nonatomic, strong) EAGLContext *context;

@property (nonatomic, assign) GLuint vertexBuffer;
//@property (nonatomic, assign) GLuint textureBuffer;

@end

typedef struct {
    GLKVector3 positionCoords;
    GLKVector2 textureCoords;
} ImageVertex;

const ImageVertex ImageVertices[] = {
    {{1, -1, -4.0f,},{1.0f,0.0f}}, //右下
    {{1, 1,  -4.0f},{1.0f,1.0f}}, //右上
    {{-1, 1, -4.0f},{0.0f,1.0f}}, //左上
    
    {{1, -1, -4.0f},{1.0f,0.0f}}, //右下
    {{-1, 1, -4.0f},{0.0f,1.0f}}, //左上
    {{-1, -1, -4.0f},{0.0f,0.0f}}, //左下
};

@implementation CYTextureViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    GLKView *glView = (GLKView *)self.view;
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    glView.context = self.context;
    [EAGLContext setCurrentContext:self.context];
    self.baseEffect = [GLKBaseEffect new];
    self.baseEffect.useConstantColor = GL_TRUE;
    self.baseEffect.constantColor = GLKVector4Make(1, 1, 1, 1);
    
    [self fillVertexArray];
}

- (void)dealloc
{
    if ([EAGLContext currentContext] == _context) {
        [EAGLContext setCurrentContext:nil];
    }
    if (_vertexBuffer != 0) {
        glDeleteBuffers(1, &_vertexBuffer);
        _vertexBuffer = 0;
    }
}

- (void)fillVertexArray
{
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(ImageVertices), ImageVertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(ImageVertex), (const GLvoid *)offsetof(ImageVertex, positionCoords));
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(ImageVertex), (const GLvoid *)offsetof(ImageVertex, textureCoords));
    
    UIImage *image = [UIImage imageNamed:@"batman"];
    CGImageRef imageRef = image.CGImage;
    
    NSError *textureError = nil;
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:imageRef
                                                               options:@{
                                                                         GLKTextureLoaderOriginBottomLeft: @1
                                                                         }
                                                                 error:&textureError];
    self.baseEffect.texture2d0.name = textureInfo.name;
    self.baseEffect.texture2d0.target = textureInfo.target;
    
    CGSize screenSize = UIScreen.mainScreen.bounds.size;
    float aspect = screenSize.width/screenSize.height;
    float imageAspect = image.size.width/image.size.height;
    if (imageAspect > 1) {
        imageAspect = 1 / imageAspect;
    }
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(80), aspect*imageAspect, 0, 10);
    self.baseEffect.transform.projectionMatrix = projectionMatrix;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [self.baseEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 6);
}

@end
