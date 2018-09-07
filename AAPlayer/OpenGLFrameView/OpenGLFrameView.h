//
//  OpenGLFrameView.h
//  OpenGLFrameView
//
//  Created by chenchao on 2013-1-1.
//  Copyright (c) 2012 chenchao . All rights reserved.





#import <UIKit/UIKit.h>
#import "DecodeH264Data_YUV.h"

@protocol OpenGLESViewPTZDelegate;

@interface OpenGLGLRenderer_YUV : NSObject
{
    
    GLint _uniformSamplers[3];
    GLuint _textures[3];
}

- (BOOL) isValid;
- (NSString *) fragmentShader;
- (void) resolveUniforms: (GLuint) program;
- (void) setFrame: (H264YUV_Frame *) frame;
- (BOOL) prepareRender;

@end



@interface OpenGLFrameView : UIView
{
    EAGLContext     *_context;
    GLuint          _framebuffer;
    GLuint          _renderbuffer;
    GLint           _backingWidth;
    GLint           _backingHeight;
    GLuint          _program;
    GLint           _uniformMatrix;
    GLfloat         _vertices[8];
    
    CGPoint      begainPoint;
    

    
    OpenGLGLRenderer_YUV* _renderer;
    
   // id<OpenGLESViewPTZDelegate> openGLESViewPTZDelegate;
}
@property (nonatomic,assign)id<OpenGLESViewPTZDelegate> openGLESViewPTZDelegate;

- (id) initWithFrame:(CGRect)frame;
- (void) render: (H264YUV_Frame *) frame;
- (UIImage*)snapshotPicture;
@end


@protocol OpenGLESViewPTZDelegate <NSObject>

@optional
- (void)cameraPTZ_Stop;
- (void)cameraPTZ_Left;
- (void)cameraPTZ_Right;
- (void)cameraPTZ_Up;
- (void)cameraPTZ_Down;
- (void)singleTouchOnOpenGLESView;

@end








