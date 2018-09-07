//
//  OpenGLFrameView.m
//  OpenGLFrameView
//
//  Created by chenchao on 2013-1-1.
//  Copyright (c) 2012 chenchao . All rights reserved.



#define PT_DELAY 1.5

#import "OpenGLFrameView.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>


#pragma mark - shaders

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

NSString *const vertexShaderString = SHADER_STRING
(
    attribute vec4 position;
    attribute vec2 texcoord;
    uniform mat4 modelViewProjectionMatrix;
    varying vec2 v_texcoord;
 
    void main()
    {
        gl_Position = modelViewProjectionMatrix * position;
        v_texcoord = texcoord.xy;
    }
 
 );

NSString *const rgbFragmentShaderString = SHADER_STRING
(
    varying highp vec2 v_texcoord;
    uniform sampler2D s_texture;
 
    void main()
    {
        gl_FragColor = texture2D(s_texture, v_texcoord);
    }
 
 );

NSString *const yuvFragmentShaderString = SHADER_STRING
(
    varying highp vec2 v_texcoord;
    uniform sampler2D s_texture_y;
    uniform sampler2D s_texture_u;
    uniform sampler2D s_texture_v;
 
    void main()
    {
        highp float y = texture2D(s_texture_y, v_texcoord).r;
        highp float u = texture2D(s_texture_u, v_texcoord).r - 0.5;
        highp float v = texture2D(s_texture_v, v_texcoord).r - 0.5;
     
        highp float r = y + 1.402 * v;
        highp float g = y - 0.344 * u - 0.714 * v;
        highp float b = y + 1.772 * u;
     
        gl_FragColor = vec4(r,g,b,1.0);
    }
 
 );

static BOOL validateProgram(GLuint prog)
{
	GLint status;
	
    glValidateProgram(prog);
    
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == GL_FALSE) {
		printf("Validate program failed %d\n", prog);
        return NO;
    }
	
	return YES;
}

static GLuint compileShader(GLenum type, NSString *shaderString)
{
	GLint status;
	const GLchar *sources = (GLchar *)shaderString.UTF8String;
	
    GLuint shader = glCreateShader(type);
    if (shader == 0 || shader == GL_INVALID_ENUM)
    {
        printf("Create shader failed%d\n", type);
        return 0;
    }
    
    glShaderSource(shader, 1, &sources, NULL);
    glCompileShader(shader);
	

    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE)
    {
        glDeleteShader(shader);
		printf("Compile shader failed\n");
        return 0;
    }
    
	return shader;
}

static void mat4f_LoadOrtho(float left, float right, float bottom, float top, float near, float far, float* mout)
{
	float r_l = right - left;
	float t_b = top - bottom;
	float f_n = far - near;
	float tx = - (right + left) / (right - left);
	float ty = - (top + bottom) / (top - bottom);
	float tz = - (far + near) / (far - near);
    
	mout[0] = 2.0f / r_l;
	mout[1] = 0.0f;
	mout[2] = 0.0f;
	mout[3] = 0.0f;
	
	mout[4] = 0.0f;
	mout[5] = 2.0f / t_b;
	mout[6] = 0.0f;
	mout[7] = 0.0f;
	
	mout[8] = 0.0f;
	mout[9] = 0.0f;
	mout[10] = -2.0f / f_n;
	mout[11] = 0.0f;
	
	mout[12] = tx;
	mout[13] = ty;
	mout[14] = tz;
	mout[15] = 1.0f;
}


#pragma mark - frame renderers



@implementation OpenGLGLRenderer_YUV

- (BOOL) isValid
{
    return (_textures[0] != 0);
}

- (NSString *) fragmentShader
{
    return yuvFragmentShaderString;
}

- (void) resolveUniforms: (GLuint) program
{
    _uniformSamplers[0] = glGetUniformLocation(program, "s_texture_y");
    _uniformSamplers[1] = glGetUniformLocation(program, "s_texture_u");
    _uniformSamplers[2] = glGetUniformLocation(program, "s_texture_v");
}

- (void) setFrame: (H264YUV_Frame *)frame
{
    H264YUV_Frame *yuvFrame = (H264YUV_Frame *)frame;
    
    
    assert(yuvFrame->luma.length == yuvFrame->width * yuvFrame->height);
    assert(yuvFrame->chromaB.length == (yuvFrame->width * yuvFrame->height) / 4);
    assert(yuvFrame->chromaR.length == (yuvFrame->width * yuvFrame->height) / 4);
    
    
    const NSUInteger frameWidth = yuvFrame->width;
    const NSUInteger frameHeight = yuvFrame->height;
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    if (0 == _textures[0])
    {
        glGenTextures(3, _textures);
    }
    
    const UInt8 *pixels[3] = {(UInt8 *)yuvFrame->luma.dataBuffer, (UInt8 *)yuvFrame->chromaB.dataBuffer, (UInt8 *)yuvFrame->chromaR.dataBuffer};
    
    const NSUInteger widths[3]  = { frameWidth, frameWidth / 2, frameWidth / 2 };
    const NSUInteger heights[3] = { frameHeight, frameHeight / 2, frameHeight / 2 };
    
    for (int i = 0; i < 3; ++i)
    {
        
        glBindTexture(GL_TEXTURE_2D, _textures[i]);
        
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_LUMINANCE,
                     widths[i],
                     heights[i],
                     0,
                     GL_LUMINANCE,
                     GL_UNSIGNED_BYTE,
                     pixels[i]);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }

}

- (BOOL) prepareRender
{
    if (_textures[0] == 0)
        return NO;
    
    for (int i = 0; i < 3; ++i) {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, _textures[i]);
        glUniform1i(_uniformSamplers[i], i);
    }
    
    return YES;
}

- (void)dealloc
{
    //printf("----------------Release openGL ES Rennder--------------------->>>>>>\n");
    if (_textures[0]){
        glDeleteTextures(3, _textures);
    }
    
    //[super dealloc];
}


@end



#pragma mark - gl view

enum {
	ATTRIBUTE_VERTEX,
   	ATTRIBUTE_TEXCOORD,
};

@implementation OpenGLFrameView
@synthesize openGLESViewPTZDelegate;

+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

- (id) initWithFrame:(CGRect)frame
{

    if (self= [super initWithFrame:frame])
    {
        
        _renderer = [[OpenGLGLRenderer_YUV alloc] init];
        

        
        self.contentScaleFactor = [[UIScreen mainScreen] scale];
        CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:YES], kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                        nil];
        
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        if (!_context ||
            ![EAGLContext setCurrentContext:_context])
        {
            
            printf("Setup EAGLContext failed \n");
            self = nil;
            return nil;
        }
        
        glGenFramebuffers(1, &_framebuffer);
        glGenRenderbuffers(1, &_renderbuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
        [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderbuffer);
        
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (status != GL_FRAMEBUFFER_COMPLETE)
        {
            
            printf(" Make complete framebuffer object failed %x\n", status);
            self = nil;
            return nil;
        }
        
        GLenum glError = glGetError();
        if (GL_NO_ERROR != glError)
        {
            
            printf("failed to setup GL %x\n", glError);
            self = nil;
            return nil;
        }
        
        if (![self loadShaders])
        {
            
            self = nil;
            return nil;
        }
        
        _vertices[0] = -1.0f;
        _vertices[1] = -1.0f;
        _vertices[2] =  1.0f;
        _vertices[3] = -1.0f;
        _vertices[4] = -1.0f;
        _vertices[5] =  1.0f;
        _vertices[6] =  1.0f;
        _vertices[7] =  1.0f;
        
        printf("setup OpenGL ES success\n");
    }

    return self;
}

- (void)dealloc
{
    //printf("----------------Release openGL ES --------------------->>>>>>\n");
    if(_renderer!=nil)
    {
       // [_renderer release];
        _renderer= nil;
    }
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    
    if (_renderbuffer) {
        glDeleteRenderbuffers(1, &_renderbuffer);
        _renderbuffer = 0;
    }
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
	
	if ([EAGLContext currentContext] == _context) {
		[EAGLContext setCurrentContext:nil];
       // [_context release];
        _context = nil;
	}
    
    //[super dealloc];
}


- (void)layoutSubviews
{   [super layoutSubviews];
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
	
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
	if (status != GL_FRAMEBUFFER_COMPLETE)
    {
		
       printf("Make complete framebuffer object failed %x\n", status);
        
	} else
    {
        
       printf("Setup GL framebuffer success %d:%d\n", _backingWidth, _backingHeight);
    }
    
    [self updateVertices];
    [self render: nil];
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
    [super setContentMode:contentMode];
    [self updateVertices];
    if (_renderer.isValid){
        [self render:nil];
    }
}

- (BOOL)loadShaders
{
    BOOL result = NO;
    GLuint vertShader = 0, fragShader = 0;
    
	_program = glCreateProgram();
	
    vertShader = compileShader(GL_VERTEX_SHADER, vertexShaderString);
	if (!vertShader)
        goto exit;
    
	fragShader = compileShader(GL_FRAGMENT_SHADER,  _renderer.fragmentShader);
    if (!fragShader)
        goto exit;
    
	glAttachShader(_program, vertShader);
	glAttachShader(_program, fragShader);
	glBindAttribLocation(_program, ATTRIBUTE_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIBUTE_TEXCOORD, "texcoord");
	
	glLinkProgram(_program);
    
    GLint status;
    glGetProgramiv(_program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
		printf("Link program failed %d\n", _program);
        goto exit;
    }
    
    result = validateProgram(_program);
    
    _uniformMatrix = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    [_renderer resolveUniforms:_program];
	
exit:
    
    if (vertShader){
        glDeleteShader(vertShader);
    }
    if (fragShader){
        glDeleteShader(fragShader);
    }
    
    if (result) {
        
        printf("Setup GL programm ok\n");
        
    } else {
        
        glDeleteProgram(_program);
        _program = 0;
    }
    
    return result;
}


- (void)updateVertices
{
    const BOOL fit      = (self.contentMode == UIViewContentModeScaleAspectFit);
    const float width   = 640;
    const float height  = 360;
    const float dH      = (float)_backingHeight / height;
    const float dW      = (float)_backingWidth	  / width;
    const float dd      = fit ? MIN(dH, dW) : MAX(dH, dW);
    const float h       = (height * dd / (float)_backingHeight);
    const float w       = (width  * dd / (float)_backingWidth );
    
    _vertices[0] = - w;
    _vertices[1] = - h;
    _vertices[2] =   w;
    _vertices[3] = - h;
    _vertices[4] = - w;
    _vertices[5] =   h;
    _vertices[6] =   w;
    _vertices[7] =   h;
}

- (void)render: (H264YUV_Frame *)frame
{
    
    static const GLfloat texCoords[] =
    {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
	
    [EAGLContext setCurrentContext:_context];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glViewport(0, 0, _backingWidth, _backingHeight);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
	glUseProgram(_program);
    
    if (frame)
    {
        [_renderer setFrame:frame];
    }
    
    if ([_renderer prepareRender])
    {
        
        GLfloat modelviewProj[16];
        mat4f_LoadOrtho(-1.0f, 1.0f, -1.0f, 1.0f, -1.0f, 1.0f, modelviewProj);
        glUniformMatrix4fv(_uniformMatrix, 1, GL_FALSE, modelviewProj);
        
        glVertexAttribPointer(ATTRIBUTE_VERTEX, 2, GL_FLOAT, 0, 0, _vertices);
        glEnableVertexAttribArray(ATTRIBUTE_VERTEX);
        glVertexAttribPointer(ATTRIBUTE_TEXCOORD, 2, GL_FLOAT, 0, 0, texCoords);
        glEnableVertexAttribArray(ATTRIBUTE_TEXCOORD);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}




- (UIImage*)snapshotPicture
{

    glBindRenderbuffer(GL_RENDERBUFFER, _framebuffer);
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    NSInteger x = 0, y = 0, width = _backingWidth, height = _backingHeight;
    
    NSInteger dataLength = width * height * 4;
    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
    
    
    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrderDefault,ref, NULL, NO, kCGRenderingIntentDefault);
    
    
    NSInteger widthInPoints, heightInPoints;
    
    if (NULL != UIGraphicsBeginImageContextWithOptions)
    {
        
        CGFloat scale = 1;
        widthInPoints = width / scale;
        heightInPoints = height / scale;
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(widthInPoints, heightInPoints), NO, scale);
    }
    else
    {
        
        widthInPoints = width;
        heightInPoints = height;
        UIGraphicsBeginImageContext(CGSizeMake(widthInPoints, heightInPoints));
        
    }
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, widthInPoints, heightInPoints), iref);
    
    UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
    
    free(data);
    CFRelease(ref);
    CFRelease(colorspace);
    CGImageRelease(iref);

    return retImage;
    
}



@end
