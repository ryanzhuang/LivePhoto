//
//  ViewController.m
//  LivePhoto
//
//  Created by huya on 2023/10/16.
//

#import "ViewController.h"
#import "LivePhotoCollectionViewCell.h"
#import <Photos/Photos.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface ViewController ()<UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) IBOutlet UISwitch *converSwitch;
@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property (nonatomic, strong) NSMutableArray<PHAsset *> *livePhotos;

@end

static NSString * const cellIdentifier = @"LivePhotoCellIdentifier";

@implementation ViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.livePhotos = [NSMutableArray array];
    self.imageManager = [[PHCachingImageManager alloc] init];
    [self.converSwitch setOn:YES];
    
    [self setupCollectionView];
    [self loadLivePhotos];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadLivePhotos) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)setupCollectionView {
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[LivePhotoCollectionViewCell class] forCellWithReuseIdentifier:cellIdentifier];
    
    [self.view addSubview:self.collectionView];
}

- (void)loadLivePhotos {
    [self.livePhotos removeAllObjects];
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.predicate = [NSPredicate predicateWithFormat:@"mediaSubtype == %ld", PHAssetMediaSubtypePhotoLive];
    
    PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsWithOptions:options];
    
    [fetchResult enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.livePhotos addObject:asset];
    }];
    
    [self.collectionView reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.livePhotos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LivePhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    PHAsset *asset = self.livePhotos[indexPath.item];
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
    options.networkAccessAllowed = YES;
    
    [self.imageManager requestImageForAsset:asset targetSize:CGSizeMake(240, 240) contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        cell.imageView.image = result;
    }];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *selectedAsset = self.livePhotos[indexPath.item];
    
    [self convertLivePhotoToImage:selectedAsset completion:^(UIImage *image) {
        if (image) {
            // 处理转换后的静态图片，例如展示在另一个界面或进行保存等操作
            [self saveImageToPhotoLibrary:image fromLivePhoto:selectedAsset];
        }
    }];
}

- (void)saveImageToPhotoLibrary:(UIImage *)image fromLivePhoto:(PHAsset *)livePhoto {
    BOOL isOn = self.converSwitch.isOn;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        // 创建图片请求
        PHAssetChangeRequest *createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        
        // 获取Live Photo的时间信息
        PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[livePhoto.localIdentifier] options:nil].firstObject;
        NSTimeInterval creationDate = asset.creationDate.timeIntervalSince1970;
        
        // 设置图片的时间信息
        createAssetRequest.creationDate = [NSDate dateWithTimeIntervalSince1970:creationDate];
        createAssetRequest.location = livePhoto.location;
        
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            [SVProgressHUD showErrorWithStatus:@"转换成功"];
            if(isOn) {
                [self deleteAsset:livePhoto];
            }
            NSLog(@"Image has been saved to the photo library.");
        } else {
            [SVProgressHUD showErrorWithStatus:@"转换失败"];
            NSLog(@"Failed to save image to the photo library: %@", error.localizedDescription);
        }
    }];
}

- (void)deleteAsset:(PHAsset *)asset {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest deleteAssets:@[asset]];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            [SVProgressHUD showErrorWithStatus:@"删除成功"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loadLivePhotos];
            });
            NSLog(@"Asset has been deleted.");
        } else {
            [SVProgressHUD showErrorWithStatus:@"删除失败"];
            NSLog(@"Failed to delete asset: %@", error.localizedDescription);
        }
    }];
}

- (void)convertLivePhotoToImage:(PHAsset *)livePhotoAsset completion:(void (^)(UIImage *))completion {
    PHLivePhotoRequestOptions *options = [[PHLivePhotoRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    [self.imageManager requestLivePhotoForAsset:livePhotoAsset targetSize:CGSizeMake(livePhotoAsset.pixelWidth, livePhotoAsset.pixelHeight) contentMode:PHImageContentModeAspectFit options:options resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
        if (livePhoto) {
            PHImageRequestOptions *imageOptions = [[PHImageRequestOptions alloc] init];
            imageOptions.synchronous = YES;
            [self.imageManager requestImageForAsset:livePhotoAsset targetSize:CGSizeMake(livePhotoAsset.pixelWidth, livePhotoAsset.pixelHeight) contentMode:PHImageContentModeAspectFit options:imageOptions resultHandler:^(UIImage * _Nullable image, NSDictionary * _Nullable info) {
                completion(image);
            }];
        } else {
            completion(nil);
        }
    }];
}

@end
