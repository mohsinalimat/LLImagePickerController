//
//  LLCameraViewController.m
//  LLImagePickerController
//
//  Created by 雷亮 on 16/8/23.
//  Copyright © 2016年 Leiliang. All rights reserved.
//

#import "LLCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "Config.h"

@interface LLCameraViewController () <UIGestureRecognizerDelegate>

#pragma mark - UI
@property (nonatomic, strong) LLFlashlampView *flashlampView;
@property (nonatomic, strong) UIView *captureBackgroundView;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *cameraLayer;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIView *snapRoundView;
@property (nonatomic, strong) UIButton *snapButton;

#pragma mark - AVFoundation
// 执行输入设备和输出设备之间的数据传递
@property (nonatomic, strong) AVCaptureSession *captureSession;
// 输入设备
@property (nonatomic, strong) AVCaptureDeviceInput *inputDevice;
// 照片输出流
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;

#pragma mark -
#pragma mark - other params
// 开始缩放比例
@property (nonatomic, assign) CGFloat beginScale;
// 结束缩放比例
@property (nonatomic, assign) CGFloat effectiveScale;
// 是否用前摄像头
@property (nonatomic, assign) BOOL isUsingFrontFaceCamera;

@property (nonatomic, copy) CameraBlock cameraBlock;

@end

@implementation LLCameraViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.captureSession) {
        [self.captureSession startRunning];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.captureSession) {
        [self.captureSession stopRunning];
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self buildingParams];
        [self buildingCamera];
        [self buildingUI];
        [self buildingGesture];
        [self handleCallback];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)buildingParams {
    self.isUsingFrontFaceCamera = NO;
    self.beginScale = 1.f;
    self.effectiveScale = self.beginScale;
    self.saveImageToAlbum = YES;
}

- (void)buildingCamera {
    self.captureSession = [[AVCaptureSession alloc] init];
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [device lockForConfiguration:nil];
    // 设置闪光灯为自动
    device.flashMode = AVCaptureFlashModeAuto;
    // 解锁设备
    [device unlockForConfiguration];
    
    NSError *error = nil;
    self.inputDevice = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if (error) {
        NSLog(@"error: %@", error);
    }
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    // 输出设置
    NSDictionary *outputSettings = @{AVVideoCodecKey: AVVideoCodecJPEG};
    self.stillImageOutput.outputSettings = outputSettings;
    
    if ([self.captureSession canAddInput:self.inputDevice]) {
        [self.captureSession addInput:self.inputDevice];
    }
    if ([self.captureSession canAddOutput:self.stillImageOutput]) {
        [self.captureSession addOutput:self.stillImageOutput];
    }
    
    self.cameraLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    self.cameraLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.cameraLayer.frame = CGRectMake(0, 0, kScreenWidth, self.captureBackgroundView.height);
    [self.captureBackgroundView.layer addSublayer:self.cameraLayer];
}

- (void)buildingUI {
    self.view.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.cancelButton];
    [self.view addSubview:self.snapRoundView];
    [self.snapRoundView addSubview:self.snapButton];
    [self.view addSubview:self.captureBackgroundView];
}

- (void)buildingGesture {
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinckGestureAction:)];
    pinch.delegate = self;
    [self.captureBackgroundView addGestureRecognizer:pinch];
}

#pragma mark -
#pragma mark - gesture protocol methods
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
        self.beginScale = self.effectiveScale;
    }
    return YES;
}

- (void)handlePinckGestureAction:(UIPinchGestureRecognizer *)gesture {
    BOOL allTouchesOnTheCameraLayer = YES;
    NSUInteger numberOfTouches = [gesture numberOfTouches];
    for (NSInteger i = 0; i < numberOfTouches; i ++) {
        CGPoint locationPoint = [gesture locationOfTouch:i inView:self.captureBackgroundView];
        CGPoint convertLocation = [self.cameraLayer convertPoint:locationPoint fromLayer:self.cameraLayer.superlayer];
        if (![self.cameraLayer containsPoint:convertLocation]) {
            allTouchesOnTheCameraLayer = NO;
            break;
        }
    }
    
    if (allTouchesOnTheCameraLayer) {
        self.effectiveScale = self.beginScale * gesture.scale;
        if (self.effectiveScale < 1.0) {
            self.effectiveScale = 1.0;
        }
        CGFloat maxScaleAndCropFactor = [[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
        if (self.effectiveScale > maxScaleAndCropFactor) {
            self.effectiveScale = maxScaleAndCropFactor;
        }
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.025];
        [self.cameraLayer setAffineTransform:CGAffineTransformMakeScale(self.effectiveScale, self.effectiveScale)];
        [CATransaction commit];
    }
}

#pragma mark -
#pragma mark - click methods
- (void)handleCallback {
    WeakSelf(self)
    // 切换摄像头
    [self.flashlampView handleTurnCameraWithBlock:^{
        weakSelf.isUsingFrontFaceCamera = !weakSelf.isUsingFrontFaceCamera;
        
        [Utils animationFlipFromLeft:self.captureBackgroundView duration:0.5];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            AVCaptureDevicePosition captureDevicePosition;
            if (weakSelf.isUsingFrontFaceCamera) {
                captureDevicePosition = AVCaptureDevicePositionFront;
            } else {
                captureDevicePosition = AVCaptureDevicePositionBack;
            }
            for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
                if ([device position] == captureDevicePosition) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.cameraLayer.session beginConfiguration];
                        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
                        for (AVCaptureDeviceInput *oldInput in self.cameraLayer.session.inputs) {
                            [[self.cameraLayer session] removeInput:oldInput];
                        }
                        [self.cameraLayer.session addInput:input];
                        [self.cameraLayer.session commitConfiguration];
                    });
                    break;
                }
            }
        });
    }];
    
    // 切换闪光灯
    [self.flashlampView changeFlashlampStyleWithBlock:^(LLFlashlampStyle flashlampStyle) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        // 修改之前先锁定
        [device lockForConfiguration:nil];
        // 判定是否有闪光灯
        if ([device hasFlash]) {
            switch (flashlampStyle) {
                case LLFlashlampStyleAuto: {
                    device.flashMode = AVCaptureFlashModeAuto;
                    break;
                }
                case LLFlashlampStyleOn: {
                    device.flashMode = AVCaptureFlashModeOn;
                    break;
                }
                case LLFlashlampStyleOff: {
                    device.flashMode = AVCaptureFlashModeOff;
                    break;
                }
            }
        } else {
            NSLog(@"此设备没有闪光灯");
        }
        // 解锁
        [device unlockForConfiguration];
    }];
}

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)snapButtonAction:(UIButton *)sender {
    AVCaptureConnection *captureConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation captureVideoOrientation = [self captureVideoForDeviceOrientation:deviceOrientation];
    captureConnection.videoOrientation = captureVideoOrientation;
    captureConnection.videoScaleAndCropFactor = self.effectiveScale;
    
    WeakSelf(self)
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:captureConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        NSData *JPEGData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [UIImage imageWithData:JPEGData];
        
        Block_exe(weakSelf.cameraBlock, image);
        
        if (weakSelf.saveImageToAlbum) {
            UIImageWriteToSavedPhotosAlbum(image, weakSelf, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        }
    }];
}

- (void)getPhotoFromCameraWithBlock:(CameraBlock)block {
    self.cameraBlock = block;
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (!error) {
        NSLog(@"已保存到相册");
    } else {
        NSLog(@"保存失败");
    }
}

#pragma mark -
#pragma mark - getter methods
- (LLFlashlampView *)flashlampView {
    if (!_flashlampView) {
        _flashlampView = [[LLFlashlampView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 40)];
        _flashlampView.backgroundColor = [UIColor blackColor];
        [self.view addSubview:_flashlampView];
    }
    return _flashlampView;
}

- (UIView *)captureBackgroundView {
    if (!_captureBackgroundView) {
        _captureBackgroundView = [[UIView alloc] init];
        _captureBackgroundView.frame = CGRectMake(0, 40, kScreenWidth, kScreenHeight - 175);
        _captureBackgroundView.backgroundColor = [UIColor blackColor];
        _captureBackgroundView.clipsToBounds = YES;
    }
    return _captureBackgroundView;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.backgroundColor = [UIColor blackColor];
        [_cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = Font(16);
        _cancelButton.size = CGSizeMake(65, 30);
        _cancelButton.left = 0;
        _cancelButton.bottom = kScreenHeight - 38;
    }
    return _cancelButton;
}

- (UIView *)snapRoundView {
    if (!_snapRoundView) {
        CGFloat radius = 65.f / 2;
        _snapRoundView = [[UIView alloc] init];
        [_snapRoundView cut:radius borderColor:[UIColor whiteColor] borderWidth:5];
        _snapRoundView.backgroundColor = [UIColor blackColor];
        
        _snapRoundView.size = CGSizeMake(radius * 2, radius * 2);
        _snapRoundView.centerX = kScreenWidth / 2;
        _snapRoundView.bottom = kScreenHeight - 25;
    }
    return _snapRoundView;
}

- (UIButton *)snapButton {
    if (!_snapButton) {
        CGFloat radius = 50.5f / 2;
        _snapButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_snapButton setImage:[UIImage imageNamed:@"snapBackground.jpg"] forState:UIControlStateNormal];
        [_snapButton addTarget:self action:@selector(snapButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        _snapButton.size = CGSizeMake(radius * 2, radius * 2);
        _snapButton.centerX = self.snapRoundView.width / 2;
        _snapButton.centerY = self.snapRoundView.height / 2;
        [_snapButton cut];
    }
    return _snapButton;
}

- (AVCaptureVideoOrientation)captureVideoForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
        result = AVCaptureVideoOrientationLandscapeRight;
    } else if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
        result = AVCaptureVideoOrientationLandscapeLeft;
    }
    return result;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

#define LLFlashlampYellowColor HEXCOLOR(0xfcca00)
#define LLFlashlampWhiteColor  HEXCOLOR(0xffffff)
static CGFloat const kAlphaDuration = 0.3f;

@interface LLFlashlampView ()

@property (nonatomic, strong) UIButton *flashlampStyleButton;
@property (nonatomic, strong) UIButton *flashlampAutoButton;
@property (nonatomic, strong) UIButton *flashlampOnButton;
@property (nonatomic, strong) UIButton *flashlampOffButton;
@property (nonatomic, strong) UIButton *turnCameraButton;

@property (nonatomic, assign) LLFlashlampStyle flashlampStyle;
@property (nonatomic, assign) BOOL showFlashlampStyleButton;
@property (nonatomic, copy) void(^changeFlashlampStyleBlock)(LLFlashlampStyle flashlampStyle);
@property (nonatomic, copy) void(^turnCameraBlock)();

@end

@implementation LLFlashlampView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildingUI];
        [self buildingParams];
    }
    return self;
}

- (void)buildingParams {
    self.defaultFlashlampStyle = LLFlashlampStyleOff;
    self.showFlashlampStyleButton = NO;
}

- (void)buildingUI {
    // 样式button
    self.flashlampStyleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_flashlampStyleButton setImage:[UIImage imageNamed:@"flashlampOff.png"] forState:UIControlStateNormal];
    [self addSubview:_flashlampStyleButton];

    CGFloat const kFlashStyleFont = 13.f;
    // 自动、打开、关闭button
    self.flashlampAutoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_flashlampAutoButton setTitle:@"自动" forState:UIControlStateNormal];
    _flashlampAutoButton.titleLabel.font = Font(kFlashStyleFont);
    [self addSubview:_flashlampAutoButton];
    
    self.flashlampOnButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_flashlampOnButton setTitle:@"打开" forState:UIControlStateNormal];
    _flashlampOnButton.titleLabel.font = Font(kFlashStyleFont);
    [self addSubview:_flashlampOnButton];
    
    self.flashlampOffButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_flashlampOffButton setTitle:@"关闭" forState:UIControlStateNormal];
    _flashlampOffButton.titleLabel.font = Font(kFlashStyleFont);
    [self addSubview:_flashlampOffButton];
    
    // 摄像头翻转
    self.turnCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_turnCameraButton setImage:[UIImage imageNamed:@"turnCamera.png"] forState:UIControlStateNormal];
    [self addSubview:_turnCameraButton];
    
    // action
    [_flashlampStyleButton addTarget:self action:@selector(flashlampStyleButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [_flashlampAutoButton addTarget:self action:@selector(flashlampAutoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [_flashlampOnButton addTarget:self action:@selector(flashlampOnButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [_flashlampOffButton addTarget:self action:@selector(flashlampOffButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [_turnCameraButton addTarget:self action:@selector(turnCameraButtonAction:) forControlEvents:UIControlEventTouchUpInside];

    // frame
    _flashlampStyleButton.size = CGSizeMake(30, 30);
    _flashlampStyleButton.centerX = 25;
    _flashlampStyleButton.centerY = self.height / 2;
    
    _turnCameraButton.size = CGSizeMake(30, 30);
    _turnCameraButton.centerX = self.width - 25;
    _turnCameraButton.centerY = self.height / 2;
    
    _flashlampAutoButton.size = CGSizeMake(40, 30);
    _flashlampOnButton.size = CGSizeMake(40, 30);
    _flashlampOffButton.size = CGSizeMake(40, 30);

    _flashlampAutoButton.centerY = self.height / 2;
    _flashlampOnButton.centerY = self.height / 2;
    _flashlampOffButton.centerY = self.height / 2;
    
    CGFloat const spacing = kScreenWidth / 4;
    _flashlampAutoButton.centerX = spacing;
    _flashlampOnButton.centerX = spacing * 2;
    _flashlampOffButton.centerX = spacing * 3;
    
    _flashlampAutoButton.hidden = YES;
    _flashlampOnButton.hidden = YES;
    _flashlampOffButton.hidden = YES;
    
    _flashlampAutoButton.alpha = 0;
    _flashlampOnButton.alpha = 0;
    _flashlampOffButton.alpha = 0;
}

- (void)changeFlashlampStyleWithBlock:(void(^)(LLFlashlampStyle flashlampStyle))block {
    _changeFlashlampStyleBlock = block;
}

- (void)handleTurnCameraWithBlock:(void(^)())block {
    _turnCameraBlock = block;
}

#pragma mark -
#pragma mark - action
- (void)flashlampStyleButtonAction:(UIButton *)sender {
    self.showFlashlampStyleButton = !self.showFlashlampStyleButton;
}

- (void)flashlampAutoButtonAction:(UIButton *)sender {
    self.flashlampStyle = LLFlashlampStyleAuto;
    self.showFlashlampStyleButton = NO;
    Block_exe(_changeFlashlampStyleBlock, self.flashlampStyle);
}

- (void)flashlampOnButtonAction:(UIButton *)sender {
    self.flashlampStyle = LLFlashlampStyleOn;
    self.showFlashlampStyleButton = NO;
    Block_exe(_changeFlashlampStyleBlock, self.flashlampStyle);
}

- (void)flashlampOffButtonAction:(UIButton *)sender {
    self.flashlampStyle = LLFlashlampStyleOff;
    self.showFlashlampStyleButton = NO;
    Block_exe(_changeFlashlampStyleBlock, self.flashlampStyle);
}

- (void)turnCameraButtonAction:(UIButton *)sender {
    Block_exe(_turnCameraBlock);
}

#pragma mark -
#pragma mark - setter methods
- (void)setDefaultFlashlampStyle:(LLFlashlampStyle)defaultFlashlampStyle {
    _defaultFlashlampStyle = defaultFlashlampStyle;
    self.flashlampStyle = _defaultFlashlampStyle;
}

- (void)setFlashlampStyle:(LLFlashlampStyle)flashlampStyle {
    _flashlampStyle = flashlampStyle;
    switch (_flashlampStyle) {
        case LLFlashlampStyleAuto: {
            [_flashlampStyleButton setImage:[UIImage imageNamed:@"flashlamp.png"] forState:UIControlStateNormal];
            [_flashlampAutoButton setTitleColor:LLFlashlampYellowColor forState:UIControlStateNormal];
            [_flashlampOnButton setTitleColor:LLFlashlampWhiteColor forState:UIControlStateNormal];
            [_flashlampOffButton setTitleColor:LLFlashlampWhiteColor forState:UIControlStateNormal];
            break;
        }
        case LLFlashlampStyleOn: {
            [_flashlampStyleButton setImage:[UIImage imageNamed:@"flashlampOn.png"] forState:UIControlStateNormal];
            [_flashlampAutoButton setTitleColor:LLFlashlampWhiteColor forState:UIControlStateNormal];
            [_flashlampOnButton setTitleColor:LLFlashlampYellowColor forState:UIControlStateNormal];
            [_flashlampOffButton setTitleColor:LLFlashlampWhiteColor forState:UIControlStateNormal];
            break;
        }
        case LLFlashlampStyleOff: {
            [_flashlampStyleButton setImage:[UIImage imageNamed:@"flashlampOff.png"] forState:UIControlStateNormal];
            [_flashlampAutoButton setTitleColor:LLFlashlampWhiteColor forState:UIControlStateNormal];
            [_flashlampOnButton setTitleColor:LLFlashlampWhiteColor forState:UIControlStateNormal];
            [_flashlampOffButton setTitleColor:LLFlashlampYellowColor forState:UIControlStateNormal];
            break;
        }
    }
}

- (void)setShowFlashlampStyleButton:(BOOL)showFlashlampStyleButton {
    _showFlashlampStyleButton = showFlashlampStyleButton;
    if (showFlashlampStyleButton) {
        _flashlampAutoButton.hidden = NO;
        _flashlampOnButton.hidden = NO;
        _flashlampOffButton.hidden = NO;
        [UIView animateWithDuration:kAlphaDuration animations:^{
            _flashlampAutoButton.alpha = 1.f;
            _flashlampOnButton.alpha = 1.f;
            _flashlampOffButton.alpha = 1.f;
        }];
        
        [UIView animateWithDuration:kAlphaDuration animations:^{
            _turnCameraButton.alpha = 0.f;
        } completion:^(BOOL finished) {
            _turnCameraButton.hidden = YES;
        }];
    } else {
        [UIView animateWithDuration:kAlphaDuration animations:^{
            _flashlampAutoButton.alpha = 0.f;
            _flashlampOnButton.alpha = 0.f;
            _flashlampOffButton.alpha = 0.f;
        } completion:^(BOOL finished) {
            _flashlampAutoButton.hidden = YES;
            _flashlampOnButton.hidden = YES;
            _flashlampOffButton.hidden = YES;
        }];
    
        _turnCameraButton.hidden = NO;
        [UIView animateWithDuration:kAlphaDuration animations:^{
            _turnCameraButton.alpha = 1.f;
        }];
    }
}

@end
