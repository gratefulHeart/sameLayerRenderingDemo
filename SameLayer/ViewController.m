//
//  ViewController.m
//  SameLayer
//
//  Created by hello on 2024/8/1.
//
/*
 
 */

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ContainerView : UIView

@end

@implementation ContainerView

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    if (aProtocol == NSProtocolFromString(@"WKNativelyInteractible")) {
        return YES;
    }
    return [super conformsToProtocol:aProtocol];
}

@end

@interface ViewController ()<WKScriptMessageHandler,WKNavigationDelegate,AVCaptureFileOutputRecordingDelegate>
{
    WKWebView *webView;
    
}
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic, strong) NSURL *outputURL;
@property (nonatomic, strong) UIButton *startRecordingButton;
@property (nonatomic, strong) UIButton *stopRecordingButton;
@property (nonatomic, strong) AVPlayer *player;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc]init];
    
    webView = [[WKWebView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) configuration:configuration];
    webView.navigationDelegate = self;
    [self.view addSubview:webView];
    
    [configuration.userContentController addScriptMessageHandler:self name:@"nativeViewHandler"];
    
    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"same_01" ofType:@"html"];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:filePath]]];
    //    [webView loadFileURL:[NSURL fileURLWithPath:filePath] allowingReadAccessToURL:nil];
    
}
#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self handleGestrues];
    });
}
- (void)handleGestrues {
//    UIScrollView *webViewScrollView = webView.scrollView;
//    if ([webViewScrollView isKindOfClass:NSClassFromString(@"WKScrollView")]) {
//        UIView *_WKContentView = webViewScrollView.subviews.firstObject;
//        if (![_WKContentView isKindOfClass:NSClassFromString(@"WKContentView")]) return;
//        NSArray *gestrues = _WKContentView.gestureRecognizers;
//        for (UIGestureRecognizer *gesture in gestrues) {
//            gesture.cancelsTouchesInView = NO;
//            gesture.delaysTouchesBegan = NO;
//            gesture.delaysTouchesEnded = NO;
//        }
//    }
}
#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSLog(@"userContentController=====%@",message);
    NSString *name = message.name;
    if ([name isEqualToString:@"nativeViewHandler"]) {
        NSDictionary *body = message.body;
        if ([body isKindOfClass:[NSDictionary class]]) {
            if ([[body valueForKey:@"command"] isEqualToString:@"nativeViewInsert"] && [[body valueForKey:@"label"] isEqualToString:@"videoRecord"]) {
//                插入视频录制
                [self insertNativeView:message];
            }else if ([[body valueForKey:@"command"] isEqualToString:@"nativeViewInsert"] && [[body valueForKey:@"label"] isEqualToString:@"videoPlayer"]){
//                插入视频播放器
                
                [self insertNativeVideoPlayerView:message];
                
            }else{
                NSLog(@"=====nativeViewHandler其他同层渲染组件插入暂不支持=====");
            }
        }
        else {
            NSLog(@"=====nativeViewHandler其他消息不做处理=====");
        }
    }else{
        NSLog(@"=====非nativeViewHandler其他消息不做处理=====");
    }
    
}
#pragma mark - insert Native View

- (void)insertNativeVideoPlayerView:(WKScriptMessage *)message {
    NSDictionary *params = message.body[@"args"];
    NSLog(@"%@", params);
    // 这里创建一个UILabel 做演示
    
    UIView *v = [self findView:webView str:@"" ids:params[@"id"]];
    
    ContainerView *c = [[ContainerView alloc] initWithFrame:v.bounds];

//    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, v.frame.size.width, 100)];
//    l.backgroundColor = UIColor.orangeColor;
//    l.font = [UIFont systemFontOfSize:40];
//    l.text = [NSString stringWithFormat:@"组件ID为：%@的原生同层组件", params[@"id"]];
//    l.textAlignment = NSTextAlignmentCenter;
//    [c addSubview:l];
//    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
//    [button setTitle:@"按钮" forState:UIControlStateNormal];
//    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
//    button.frame = CGRectMake(0, 200, v.frame.size.width, 100);
//    button.titleLabel.font = [UIFont systemFontOfSize:40];
//    [c addSubview:button];
    if (v) {
        // 查目标容器
        for (UIView *sub in v.subviews) {
            if ([sub isKindOfClass:NSClassFromString(@"WKChildScrollView")]) {
                c.frame = sub.bounds;
                [sub addSubview:c];
            }
        }
    }
    NSUserDefaults *uf = [NSUserDefaults standardUserDefaults];
    NSInteger index = [uf integerForKey:@"num"];
    NSString *fileNameStr = [NSString stringWithFormat:@"tempVideo_%ld.mov",(long)(index-1)];
    
    NSURL *videoURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileNameStr]];

//    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:videoURL];
//    
//    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    self.player = [AVPlayer playerWithURL:videoURL];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.frame = v.bounds;
    [c.layer addSublayer:playerLayer];
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    
    UIButton *pauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    pauseButton.frame = CGRectMake(50, v.frame.size.height-50, 100, 50);
    [pauseButton setTitle:@"播放/暂停" forState:UIControlStateNormal];
    [pauseButton addTarget:self action:@selector(pauseVideo:) forControlEvents:UIControlEventTouchUpInside];
    [c addSubview:pauseButton];
}
- (void)pauseVideo:(UIButton *)button {
    if ([self.player rate] == 1.0) {
        [self.player pause];
    } else {
        CMTime currentTime = [self.player currentTime];
        CMTime duration = [self.player.currentItem duration];
        if (CMTimeCompare(currentTime, duration) == 0){
            [self.player seekToTime:kCMTimeZero];
        }
        [self.player play];
    }
}

- (void)insertNativeView111:(WKScriptMessage *)message {
    NSDictionary *params = message.body[@"args"];
    NSLog(@"%@", params);
    // 这里创建一个UILabel 做演示
    
    UIView *v = [self findView:webView str:@"" ids:params[@"id"]];
    
    UIView *c = [[UIView alloc] initWithFrame:v.bounds];
    
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, v.frame.size.width, 100)];
    l.backgroundColor = UIColor.orangeColor;
    l.font = [UIFont systemFontOfSize:40];
    l.text = [NSString stringWithFormat:@"组件ID为：%@的原生同层组件", params[@"id"]];
    l.textAlignment = NSTextAlignmentCenter;
    [c addSubview:l];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"按钮" forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.frame = CGRectMake(0, 200, v.frame.size.width, 100);
    button.titleLabel.font = [UIFont systemFontOfSize:40];
    [c addSubview:button];
    if (v) {
        // 查目标容器
        for (UIView *sub in v.subviews) {
            if ([sub isKindOfClass:NSClassFromString(@"WKChildScrollView")]) {
                c.frame = sub.bounds;
                [sub addSubview:c];
            }
        }
    }
}

- (void)insertNativeView:(WKScriptMessage *)message {
    NSDictionary *params = message.body[@"args"];
    NSLog(@"%@", params);
    // 这里创建一个UILabel 做演示
    
    UIView *v = [self findView:webView str:@"" ids:params[@"id"]];
    
    ContainerView *c = [[ContainerView alloc] initWithFrame:v.bounds];
    
    //    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, v.frame.size.width, 100)];
    //    l.backgroundColor = UIColor.orangeColor;
    //    l.font = [UIFont systemFontOfSize:40];
    //    l.text = [NSString stringWithFormat:@"组件ID为：%@的原生同层组件", params[@"id"]];
    //    l.textAlignment = NSTextAlignmentCenter;
    //    [c addSubview:l];
    //    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    //    [button setTitle:@"按钮" forState:UIControlStateNormal];
    //    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    //    button.frame = CGRectMake(0, 200, v.frame.size.width, 100);
    //    button.titleLabel.font = [UIFont systemFontOfSize:40];
    //    [c addSubview:button];
    if (v) {
        // 查目标容器
        for (UIView *sub in v.subviews) {
            if ([sub isKindOfClass:NSClassFromString(@"WKChildScrollView")]) {
                c.frame = sub.bounds;
                [sub addSubview:c];
                [sub setValue:@NO forKey:@"bounces"];
            }
        }
    }
    
    
    // 初始化捕获会话
    self.captureSession = [[AVCaptureSession alloc] init];
    
    // 配置输入设备（例如后置摄像头）
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
    
    if ([self.captureSession canAddInput:videoInput]) {
        [self.captureSession addInput:videoInput];
    }
    
    
    
    NSUserDefaults *uf = [NSUserDefaults standardUserDefaults];
    NSInteger index = [uf integerForKey:@"num"];
    NSString *fileNameStr = [NSString stringWithFormat:@"tempVideo_%ld.mov",(long)(index+1)];
    index = index+1;
    [uf setInteger:index forKey:@"num"];
    // 创建临时文件用于保存录制的视频
    self.outputURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileNameStr]];

    // 配置预览层
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.previewLayer.frame = v.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    NSLog(@"%@",NSStringFromCGRect(v.bounds));
    [c.layer addSublayer:self.previewLayer];
    
    AVCaptureConnection *videoConnection = [self.previewLayer connection];
    if ([videoConnection isVideoOrientationSupported]) {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        NSLog(@"UIInterfaceOrientation:%d",[UIDevice currentDevice].orientation);
        if (orientation == UIInterfaceOrientationLandscapeLeft) {
            [videoConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
        }else if (orientation == UIInterfaceOrientationLandscapeRight){
            [videoConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        }
        else if (orientation == UIInterfaceOrientationPortraitUpsideDown){
            [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
        }else{
            [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }

    }
    // 设置输出
    self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    if ([self.captureSession canAddOutput:self.movieFileOutput]) {
        [self.captureSession addOutput:self.movieFileOutput];
    }
    AVCaptureConnection *videoOutputConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([videoOutputConnection isVideoOrientationSupported]) {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        NSLog(@"UIInterfaceOrientation:%d",[UIDevice currentDevice].orientation);
        if (orientation == UIInterfaceOrientationLandscapeLeft) {
            [videoOutputConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
        }else if (orientation == UIInterfaceOrientationLandscapeRight){
            [videoOutputConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        }
        else if (orientation == UIInterfaceOrientationPortraitUpsideDown){
            [videoOutputConnection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
        }else{
            [videoOutputConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
    }

    // 创建开始录制按钮
    self.startRecordingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.startRecordingButton.frame = CGRectMake(50, c.frame.size.height - 50, 100, 50);
    [self.startRecordingButton setTitle:@"开始录制" forState:UIControlStateNormal];
    [self.startRecordingButton setBackgroundColor:[UIColor greenColor]];
    [self.startRecordingButton addTarget:self action:@selector(startRecordingAction) forControlEvents:UIControlEventTouchUpInside];
    [c addSubview:self.startRecordingButton];
    
    // 创建结束录制按钮
    self.stopRecordingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.stopRecordingButton.frame = CGRectMake(c.frame.size.width - 150, c.frame.size.height - 50, 100, 50);
    [self.stopRecordingButton setTitle:@"结束录制" forState:UIControlStateNormal];
    [self.stopRecordingButton setBackgroundColor:[UIColor redColor]];
    [self.stopRecordingButton addTarget:self action:@selector(stopRecordingAction) forControlEvents:UIControlEventTouchUpInside];
    [self.stopRecordingButton setEnabled:NO];  // 初始时结束录制按钮不可用
    [c addSubview:self.stopRecordingButton];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        // 启动会话
        [self.captureSession startRunning];
    });
}
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    NSLog(@"屏幕方向：%d",[UIDevice currentDevice].orientation);
    AVCaptureConnection *videoConnection = [self.previewLayer connection];
    if ([videoConnection isVideoOrientationSupported]) {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        NSLog(@"UIInterfaceOrientation:%d",[UIDevice currentDevice].orientation);
        if (orientation == UIInterfaceOrientationLandscapeLeft) {
            [videoConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
        }else if (orientation == UIInterfaceOrientationLandscapeRight){
            [videoConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        }
        else if (orientation == UIInterfaceOrientationPortraitUpsideDown){
            [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
        }else{
            [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }

    }
    
}
- (UIView *)findView:(UIView *)root str:(NSString *)pre ids:(NSString *)ids {
    if (!root) {
        return nil;
    }
    NSLog(@"%@%@,%@",pre ,root.class, root.layer.name);
    if ([root.layer.name containsString:[NSString stringWithFormat:@"id='%@'", ids]]) {
        return root;
    }
    
    for (UIView *v in root.subviews) {
        UIView *res = [self findView:v str:[NSString stringWithFormat:@"%@ - ", pre] ids: ids];
        if (res) {
            return res;
        }
    }
    return nil;
}

- (void)startRecordingAction {
    if (!self.captureSession.isRunning) {
        [self.captureSession startRunning];
    }
    if (![self.movieFileOutput isRecording]) {
        [self.movieFileOutput startRecordingToOutputFileURL:self.outputURL recordingDelegate:self];
        [self.startRecordingButton setEnabled:NO];
        [self.stopRecordingButton setEnabled:YES];
    }
}

- (void)stopRecordingAction {
    if ([self.movieFileOutput isRecording]) {
        [self.movieFileOutput stopRecording];
        [self.startRecordingButton setEnabled:YES];
        [self.stopRecordingButton setEnabled:NO];
    }
    if (self.captureSession.isRunning) {
        [self.captureSession stopRunning];
    }
    [webView evaluateJavaScript:@"callVideoPlayer()" completionHandler:^(id _Nullable data, NSError * _Nullable error) {
        NSLog(@"evaluateJavaScript Success = %@",data);
        NSLog(@"evaluateJavaScript Error= %@",error);
    }];
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    NSLog(@"开始录制到: %@", fileURL);
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error {
    if (error) {
        NSLog(@"录制出错: %@", error);
    } else {
        NSLog(@"录制完成: %@", outputFileURL);
    }
}

@end
