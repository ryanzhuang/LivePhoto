//
//  LivePhotoCollectionViewCell.m
//  LivePhoto
//
//  Created by huya on 2023/10/16.
//

#import "LivePhotoCollectionViewCell.h"

@implementation LivePhotoCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.clipsToBounds = YES;
        [self.contentView addSubview:self.imageView];
        
        self.text = [[UILabel alloc] initWithFrame:self.contentView.bounds];
        self.text.text = @"转换";
        self.text.textColor = [UIColor whiteColor];
        self.text.textAlignment = NSTextAlignmentCenter;
        self.text.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
        [self.contentView addSubview:self.text];
        
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.imageView.image = nil;
}

@end
