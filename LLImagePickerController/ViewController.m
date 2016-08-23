//
//  ViewController.m
//  LLImagePickerController
//
//  Created by 雷亮 on 16/8/16.
//  Copyright © 2016年 Leiliang. All rights reserved.
//

#import "ViewController.h"
#import "PhotosViewController.h"
#import "LLCameraViewController.h"

static NSString *const reUse = @"reUse";

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *dataArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.dataArray = @[@"选择相片", @"相机"];
}

#pragma mark - 
#pragma mark - tableView protocol methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reUse forIndexPath:indexPath];
    cell.textLabel.text = self.dataArray[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *viewController;
    if (indexPath.row == 0) {
        viewController = [storyboard instantiateViewControllerWithIdentifier:@"PhotosVC"];
    } else {
        viewController = [storyboard instantiateViewControllerWithIdentifier:@"CameraVC"];
    }
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
