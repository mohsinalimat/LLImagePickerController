//
//  LLBrowserCollectionCell.h
//  LLImagePickerController
//
//  Created by 雷亮 on 16/8/17.
//  Copyright © 2016年 Leiliang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PHAsset;
@class ALAsset;

@interface LLBrowserCollectionCell : UICollectionViewCell

- (void)handleSingleTapActionWithBlock:(dispatch_block_t)block;

- (void)reloadDataWithALAsset:(ALAsset *)asset;

- (void)reloadDataWithPHAsset:(PHAsset *)asset;

@end
