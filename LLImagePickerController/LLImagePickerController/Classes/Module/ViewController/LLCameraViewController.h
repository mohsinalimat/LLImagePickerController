//
//  LLCameraViewController.h
//  LLImagePickerController
//
//  Created by 雷亮 on 16/8/23.
//  Copyright © 2016年 Leiliang. All rights reserved.
//

#import "LLBaseViewController.h"

typedef NS_ENUM(NSInteger, LLFlashlampStyle) {
    LLFlashlampStyleAuto = 0,
    LLFlashlampStyleOn,
    LLFlashlampStyleOff,
};

typedef void (^CameraBlock) (UIImage *image);

@interface LLCameraViewController : LLBaseViewController

/**
 * @brief defaultFlashlampStyle: 默认闪光灯状态
 */
@property (nonatomic, assign) LLFlashlampStyle defaultFlashlampStyle;

/**
 * @brief saveImageToAlbum: 拍摄照片后是否自动保存到相册
 */
@property (nonatomic, assign) BOOL saveImageToAlbum;

/** 拍照回调
 * @param block: 参数类型 UIImage
 */
- (void)getPhotoFromCameraWithBlock:(CameraBlock)block;

@end

/* * * * * * * * * * * * * * * * * * * *
        以下是内部视图, 不用理会
 * * * * * * * * * * * * * * * * * * * */
 
@interface LLFlashlampView : UIView

@property (nonatomic, assign) LLFlashlampStyle defaultFlashlampStyle;

- (void)changeFlashlampStyleWithBlock:(void(^)(LLFlashlampStyle flashlampStyle))block;

- (void)handleTurnCameraWithBlock:(void(^)())block;

@end