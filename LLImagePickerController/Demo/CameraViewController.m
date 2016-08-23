//
//  CameraViewController.m
//  LLImagePickerController
//
//  Created by 雷亮 on 16/8/23.
//  Copyright © 2016年 Leiliang. All rights reserved.
//

#import "CameraViewController.h"
#import "LLCameraViewController.h"

@interface CameraViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self buildingUI];
}

- (void)buildingUI {
    self.title = @"拍照";
    self.automaticallyAdjustsScrollViewInsets = YES;
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Item" style:UIBarButtonItemStylePlain target:self action:@selector(showCameraPage:)];
    self.navigationItem.rightBarButtonItem = barButtonItem;
    self.navigationController.navigationBar.tintColor = HEXCOLOR(0x000000);
}

- (void)showCameraPage:(UIBarButtonItem *)sender {
    LLCameraViewController *cameraVC = [[LLCameraViewController alloc] init];
    cameraVC.defaultFlashlampStyle = LLFlashlampStyleAuto;
    cameraVC.saveImageToAlbum = NO;
    [cameraVC getPhotoFromCameraWithBlock:^(UIImage *image) {
        _imageView.image = image;
    }];
    [self presentViewController:cameraVC animated:YES completion:nil];
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
