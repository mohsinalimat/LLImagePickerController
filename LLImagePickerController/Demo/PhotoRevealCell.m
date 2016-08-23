//
//  PhotoRevealCell.m
//  PSPhotoManager
//
//  Created by 雷亮 on 16/8/11.
//  Copyright © 2016年 Leiliang. All rights reserved.
//

#import "PhotoRevealCell.h"
#import "Config.h"

@interface PhotoRevealCell ()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation PhotoRevealCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        [self buildingUI];
        [self layoutUI];
    }
    return self;
}

- (void)buildingUI {
    self.imageView = [[UIImageView alloc] init];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.backgroundColor = kPlaceholderImageColor;
    [self addSubview:_imageView];
}

- (void)layoutUI {
    WeakSelf(self)
    [_imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.and.right.equalTo(weakSelf);
    }];
}

- (void)reloadDataWithImage:(UIImage *)image {
    self.imageView.image = image;
}

@end
