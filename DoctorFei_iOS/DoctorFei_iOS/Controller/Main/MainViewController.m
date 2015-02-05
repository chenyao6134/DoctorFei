//
//  MainViewController.m
//  DoctorFei_iOS
//
//  Created by GuJunjia on 14/11/22.
//
//

#import "MainViewController.h"
#import <UIScrollView+EmptyDataSet.h>
#import <UIImageView+WebCache.h>
#import "Chat.h"
#import "MainChatTableViewCell.h"
#import "ContactDetailViewController.h"
#import "Friends.h"
#import "SocketConnection.h"
#import <WYPopoverController.h>
#import "MainGroupPopoverViewController.h"
#import <WYStoryboardPopoverSegue.h>
#import "MainGroupDetailActionViewController.h"
#import "DoctorAPI.h"
#import "MyPageViewController.h"
#import "AgendaArrangement.h"
#import "AgendaArrangementTableViewCell.h"
#import "MainArrangementNewTableViewCell.h"
#import <JSBadgeView.h>
@interface MainViewController ()
    <UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UIGestureRecognizerDelegate, MainGroupPopoverVCDelegate, WYPopoverControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *hospitalLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
- (IBAction)refreshButtonClicked:(id)sender;
- (IBAction)userInfoButtonClicked:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *titleButton;
@property (weak, nonatomic) IBOutlet UIButton *auditButton;

- (IBAction)titleButtonClicked:(id)sender;
- (IBAction)jumpToChatButtonClicked:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *arrangementButton;
@property (nonatomic, strong) JSBadgeView *arrangementBadgeView;
@end

@implementation MainViewController
{
    NSArray *chatArray, *arrangementArray;
    UIBarButtonItem *fetchButtonItem, *loadingButtonItem;
    CABasicAnimation *rotation;
    WYPopoverController *popoverController;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    [self.navigationController.interactivePopGestureRecognizer setEnabled:YES];

    self.arrangementBadgeView = [[JSBadgeView alloc]initWithParentView:self.arrangementButton alignment:JSBadgeViewAlignmentTopRight];
    [self.arrangementBadgeView setBadgePositionAdjustment:CGPointMake(-8, 8)];
    
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    fetchButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"refresh"] style:UIBarButtonItemStyleDone target:self action:@selector(refreshButtonClicked:)];
    fetchButtonItem.tintColor = [UIColor whiteColor];
    loadingButtonItem = [[UIBarButtonItem alloc]initWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"refresh_after"]]];
//    loadingButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"refresh_after"] style:UIBarButtonItemStyleDone target:self action:@selector(refreshButtonClicked:)];
//    loadingButtonItem.tintColor = [UIColor whiteColor];
    

    

    rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotation.fromValue = [NSNumber numberWithFloat:0];
    rotation.toValue = [NSNumber numberWithFloat:(2 * M_PI)];
    rotation.duration = 0.7f; // Speed
    rotation.repeatCount = HUGE_VALF; // Repeat forever. Can be a finite number.
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(reloadTableViewData) name:@"NewChatArrivedNotification" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(fetchChatComplete) name:@"FetchChatCompleteNotification" object:nil];
//    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"UserId"]) {
//        [[SocketConnection sharedConnection]sendCheckMessages];
//    }

    [self.navigationItem setLeftBarButtonItem:fetchButtonItem animated:YES];
    
    NSString *icon = [[NSUserDefaults standardUserDefaults]objectForKey:@"UserIcon"];
    if (icon && icon.length > 0) {
        [_avatarImageView sd_setImageWithURL:[NSURL URLWithString:icon] placeholderImage:[UIImage imageNamed:@"home_user_example_pic"]];
    }
    else {
        [_avatarImageView setImage:[UIImage imageNamed:@"home_user_example_pic"]];
    }
    [_nameLabel setText:[[NSUserDefaults standardUserDefaults]objectForKey:@"UserRealName"]];
    [_hospitalLabel setText:[[NSUserDefaults standardUserDefaults]objectForKey:@"UserHospital"]];
    NSString *department = [[NSUserDefaults standardUserDefaults]objectForKey:@"UserDepartment"];
    NSString *jobTitle = [[NSUserDefaults standardUserDefaults]objectForKey:@"UserJobTitle"];
    if (department == nil) {
        department = @"";
    }
    if (jobTitle == nil) {
        jobTitle = @"";
    }
    NSString *infoString = [NSString stringWithFormat:@"%@ %@", department, jobTitle];
    [_infoLabel setText:infoString];
    [self fetchArrangement];
    [self reloadTableViewData];
    

//    //医生认证接口
//    NSNumber *doctorId = [[NSUserDefaults standardUserDefaults]objectForKey:@"UserId"];
//    if (!doctorId) {
//        return;
//    }
//    NSDictionary *params = @{
//                             @"doctorid": doctorId
//                             };
//    //    NSLog(@"%@",params);
//    [DoctorAPI getAuditWithParameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSDictionary *dataDict = [responseObject firstObject];
//        NSInteger state = [dataDict[@"state"]intValue];
//        [[NSUserDefaults standardUserDefaults] setObject:dataDict[@"state"] forKey:@"auditState"];
//        if (state == -1)
//        {
//            [self.auditButton setSelected:NO];
////            [self.auditButton setTitle:@"" forState:UIControlStateNormal];
//        }
//        else if(state == -2)
//        {
//            [self.auditButton setSelected:NO];
////            [self.auditButton setTitle:@"审核中" forState:UIControlStateNormal];
//        }
//        else if(state > 0)
//        {
//            [self.auditButton setSelected:YES];
////            [self.auditButton setTitle:@"已认证" forState:UIControlStateNormal];
//        }
//        else
//        {
//            [self.auditButton setSelected:NO];
////            [self.auditButton setTitle:@"审核未通过" forState:UIControlStateNormal];
//        }
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        ;
//    }];
}

- (void)fetchArrangement {
    NSMutableArray *array = [NSMutableArray array];
    NSNumber *doctorId = [[NSUserDefaults standardUserDefaults]objectForKey:@"UserId"];
    if (!doctorId) {
        return;
    }
    NSDictionary *param = @{
                            @"doctorid":doctorId,
                            @"topnum":@0
                            };
    [DoctorAPI getDoctorDayarrangeWithParameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        for (NSDictionary *dict in responseObject) {
            AgendaArrangement *arrangement = [[AgendaArrangement alloc]init];
            arrangement.title = dict[@"title"];
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:[dict[@"daytime"] intValue]];
            arrangement.dayTime = date;
            arrangement.memberName = dict[@"membername"];
            [array addObject:arrangement];
        }
        self.arrangementBadgeView.badgeText = [NSString stringWithFormat:@"%lu", (unsigned long)((NSArray *)responseObject).count];
        arrangementArray = [array copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error.localizedDescription);
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)fetchChatComplete {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [loadingButtonItem.customView.layer removeAllAnimations];
        [self.navigationItem setLeftBarButtonItem:fetchButtonItem animated:YES];
    });
}

- (void)reloadTableViewData {
    chatArray = [Chat MR_findAll];
    [self.tableView reloadData];
}
#pragma mark - Actions

- (IBAction)refreshButtonClicked:(id)sender {
    [self.navigationItem setLeftBarButtonItem:loadingButtonItem animated:YES];
    [loadingButtonItem.customView.layer removeAllAnimations];
    [loadingButtonItem.customView.layer addAnimation:rotation forKey:@"Spin"];
    [[SocketConnection sharedConnection]sendCheckMessages];
}

- (IBAction)userInfoButtonClicked:(id)sender {
//    [self performSegueWithIdentifier:@"UserInfoSegueIdentifier" sender:nil];
    [self.tabBarController setSelectedIndex:2];
}
- (IBAction)titleButtonClicked:(id)sender {
    
}
- (IBAction)jumpToChatButtonClicked:(id)sender {
    CGRect sectionRect = [self.tableView rectForSection:1];
    if (sectionRect.size.height < self.tableView.frame.size.height) {
        [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, self.tableView.frame.size.height - sectionRect.size.height, 0)];
    }
//    sectionRect.size.height = self.tableView.frame.size.height;
    [self.tableView scrollRectToVisible:sectionRect animated:YES];
}
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"MainChatDetailSegueIdentifier"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        ContactDetailViewController *vc = [segue destinationViewController];
        Chat *chat = chatArray[indexPath.row];
        [vc setCurrentFriend:chat.user];
    } else if ([segue.identifier isEqualToString:@"MainGroupPopoverSegueIdentifier"]) {
        [_titleButton setBackgroundImage:[UIImage imageNamed:@"top_arrow_up"] forState:UIControlStateNormal];
        MainGroupPopoverViewController *vc = [segue destinationViewController];
        vc.preferredContentSize = CGSizeMake(180.0f, 81.0f);
        vc.delegate = self;
        WYStoryboardPopoverSegue *popoverSegue = (WYStoryboardPopoverSegue *)segue;
        popoverController = [popoverSegue popoverControllerWithSender:sender permittedArrowDirections:WYPopoverArrowDirectionAny animated:YES];
        popoverController.delegate = self;
        popoverController.dismissOnTap = YES;
        popoverController.theme.outerCornerRadius = 0;
        popoverController.theme.innerCornerRadius = 0;
        popoverController.theme.glossShadowColor = [UIColor clearColor];
        popoverController.theme.fillTopColor = [UIColor clearColor];
        popoverController.theme.fillBottomColor = [UIColor clearColor];
        popoverController.theme.arrowHeight = 8.0f;
        popoverController.popoverLayoutMargins = UIEdgeInsetsZero;
    } else if ([segue.identifier isEqualToString:@"MainEditGroupSegueIdentifier"]) {
        MainGroupDetailActionViewController *vc = [segue destinationViewController];
        [vc setVcMode:MainGroupDetailActionViewControllerModeEdit];
    } else if ([segue.identifier isEqualToString:@"MyPageSegueIdentifier"]) {
        MyPageViewController *vc = [segue destinationViewController];
        NSNumber *doctorId = [[NSUserDefaults standardUserDefaults]objectForKey:@"UserId"];
        if (doctorId) {
            [vc setCurrentDoctorId:doctorId];
        }
    }
}

#pragma mark - UITableView DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section) {
        return chatArray.count;
    } else{
        if (arrangementArray && arrangementArray.count) {
            if (arrangementArray.count > 3) {
                return 3;
            }else{
                return arrangementArray.count;
            }
        }else{
            return 1;
        }
    }
//    return chatArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MainChatCellIdentifier = @"MainChatCellIdentifier";
    static NSString *MainArrangementNewCellIdentifier = @"MainArrangementNewCellIdentifier";
    static NSString *MainArrangementCellIdentifier = @"MainArrangementCellIdentifier";
    if (indexPath.section) {
        MainChatTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MainChatCellIdentifier forIndexPath:indexPath];
        [cell setCurrentChat:chatArray[indexPath.row]];
        return cell;
    }else{
        if (arrangementArray && arrangementArray.count) {
            AgendaArrangementTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MainArrangementCellIdentifier forIndexPath:indexPath];
            [cell setArrangement:arrangementArray[indexPath.row]];
            cell.separatorInset = UIEdgeInsetsMake(0, cell.bounds.size.width, 0, 0);
            return cell;
        } else{
            MainArrangementNewTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MainArrangementNewCellIdentifier forIndexPath:indexPath];

            return cell;
        }
    }
}
#pragma mark - UITableView Delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section) {
        return 65.0f;
    }else{
        return 40.0f;
    }

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    if (section == 0) {
//        return 20.0f;
//    }
    return .1f;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return .1f;
}
#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSAttributedString *emptyTitle = [[NSAttributedString alloc]initWithString:@"暂无记录"];
    return emptyTitle;
}
#pragma mark - DZNEmptySetDelegate

#pragma mark - WYPopover Delegate
- (void)popoverControllerDidDismissPopover:(WYPopoverController *)popoverController{
    [_titleButton setBackgroundImage:[UIImage imageNamed:@"top_arrow_down"] forState:UIControlStateNormal];
}

#pragma mark - Popover Delegate
- (void)editButtonClickedForPopoverVC:(MainGroupPopoverViewController *)vc {
    [self performSegueWithIdentifier:@"MainEditGroupSegueIdentifier" sender:nil];
}

@end
