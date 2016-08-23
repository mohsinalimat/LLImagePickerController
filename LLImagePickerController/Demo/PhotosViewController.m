//
//  SelectPhotosViewController.m
//  LLImagePickerController
//
//  Created by 雷亮 on 16/8/22.
//  Copyright © 2016年 Leiliang. All rights reserved.
//

#import "PhotosViewController.h"
#import "LLImageCollectionCell.h"
#import "Config.h"
#import "LLImagePickerController.h"
#import "PhotoRevealCell.h"
#import "UIImage+LLAdd.h"

static NSString *const reUse = @"reUse";

@interface PhotosViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, copy) NSArray *dataArray;

@end

@implementation PhotosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self buildingUI];
}

- (void)buildingUI {
    self.title = @"图片选择";
    self.automaticallyAdjustsScrollViewInsets = YES;
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Item" style:UIBarButtonItemStylePlain target:self action:@selector(choosePhotosAction:)];
    self.navigationItem.rightBarButtonItem = barButtonItem;
    self.navigationController.navigationBar.tintColor = HEXCOLOR(0x000000);
    [self.collectionView registerClass:[PhotoRevealCell class] forCellWithReuseIdentifier:reUse];
}

- (void)choosePhotosAction:(UIBarButtonItem *)barButtonItem {
    LLImagePickerController *navigationController = [[LLImagePickerController alloc] init];
    navigationController.autoJumpToPhotoSelectPage = YES;
    navigationController.allowSelectReturnType = YES;
    navigationController.maxSelectedCount = 3;
    if (iOS8Upwards) {
        [navigationController getSelectedPHAssetsWithBlock:^(NSArray<UIImage *> *imageArray, NSArray<PHAsset *> *assetsArray) {
            self.dataArray = [NSArray arrayWithArray:imageArray];
            [self.collectionView reloadData];
        }];
    } else {
        [navigationController getSelectedALAssetsWithBlock:^(NSArray<UIImage *> *imageArray, NSArray<ALAsset *> *assetsArray) {
            self.dataArray = [NSArray arrayWithArray:imageArray];
            [self.collectionView reloadData];
        }];
    }
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark -
#pragma mark - collectionView protocol methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoRevealCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reUse forIndexPath:indexPath];
    [cell reloadDataWithImage:self.dataArray[indexPath.row]];
    return cell;
}

#pragma mark -
#pragma mark - getter methods
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        CGFloat kPadding = 3.f;
        CGFloat kWidth = (kScreenWidth - 4 * kPadding) / 3;
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(kWidth, kWidth);
        layout.sectionInset = UIEdgeInsetsMake(kPadding, kPadding, kPadding, kPadding);
        layout.minimumInteritemSpacing = kPadding;
        layout.minimumLineSpacing = kPadding;
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight) collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor groupTableViewBackgroundColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        [self.view addSubview:_collectionView];
    }
    return _collectionView;
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
