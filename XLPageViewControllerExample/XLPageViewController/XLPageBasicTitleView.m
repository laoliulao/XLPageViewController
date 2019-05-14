//
//  XLPageBasicTitleView.m
//  XLPageViewControllerExample
//
//  Created by MengXianLiang on 2019/5/8.
//  Copyright © 2019 jwzt. All rights reserved.
//

#import "XLPageBasicTitleView.h"
#import "XLPageViewControllerUtil.h"
#import "XLPageTitleCell.h"

#pragma mark - 布局类
#pragma mark XLPageBasicTitleViewFolowLayout
@interface XLPageBasicTitleViewFolowLayout : UICollectionViewFlowLayout

@property (nonatomic, assign) XLPageTitleViewAlignment alignment;

@property (nonatomic, assign) UIEdgeInsets originSectionInset;

@end

@implementation XLPageBasicTitleViewFolowLayout

//设置标题居中、局左、居右方法
- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    CGRect targetRect = rect;
    targetRect.size = self.collectionView.bounds.size;
    //获取屏幕上所有布局文件
    NSArray *attributes = [super layoutAttributesForElementsInRect:targetRect];
    //获取所有item个数
    CGFloat totalItemCount = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0];
    //如果屏幕未被item充满，执行以下布局，否则保持标准布局
    if (attributes.count < totalItemCount) {return [super layoutAttributesForElementsInRect:rect];}
    //获取第一个cell左边和最后一个cell右边之间的距离
    UICollectionViewLayoutAttributes *firstAttribute = attributes.firstObject;
    UICollectionViewLayoutAttributes *lastAttribute = attributes.lastObject;
    CGFloat attributesFullWidth = CGRectGetMaxX(lastAttribute.frame) - CGRectGetMinX(firstAttribute.frame);
    //计算留白宽度
    CGFloat emptyWidth = self.collectionView.bounds.size.width - attributesFullWidth;
    //设置左缩进
    CGFloat insetLeft = 0;
    if (self.alignment == XLPageTitleViewAlignmentLeft) {
        insetLeft = self.originSectionInset.left;
    }
    if (self.alignment == XLPageTitleViewAlignmentCenter) {
        insetLeft = emptyWidth/2.0f;
    }
    if (self.alignment == XLPageTitleViewAlignmentRight) {
        insetLeft = emptyWidth - self.originSectionInset.right;
    }
    
    //兼容防止出错，最小缩进设置为原始缩进
    insetLeft = insetLeft <= self.originSectionInset.left ? self.originSectionInset.left : insetLeft;
    //更新CollectionView缩进
    self.sectionInset = UIEdgeInsetsMake(self.sectionInset.top, insetLeft, self.sectionInset.bottom, self.sectionInset.right);
    //返回
    return [super layoutAttributesForElementsInRect:rect];
}

@end

#pragma mark - 标题类
#pragma mark XLPageBasicTitleView
@interface XLPageBasicTitleView ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>

//集合视图
@property (nonatomic, strong) UICollectionView *collectionView;

//配置信息
@property (nonatomic, strong) XLPageViewControllerConfig *config;

//阴影线条
@property (nonatomic, strong) UIView *shadowLine;

//底部分割线
@property (nonatomic, strong) UIView *separatorLine;

@end

@implementation XLPageBasicTitleView

- (instancetype)initWithConfig:(XLPageViewControllerConfig *)config {
    if (self = [super init]) {
        [self initTitleViewWithConfig:config];
    }
    return self;
}

- (void)initTitleViewWithConfig:(XLPageViewControllerConfig *)config {
    
    self.config = config;
    
    XLPageBasicTitleViewFolowLayout *layout = [[XLPageBasicTitleViewFolowLayout alloc] init];
    layout.alignment = self.config.titleViewAlignment;
    layout.originSectionInset = self.config.titleViewInset;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.sectionInset = config.titleViewInset;
    layout.minimumInteritemSpacing = config.titleSpace;
    layout.minimumLineSpacing = config.titleSpace;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = config.titleViewBackgroundColor;
    [self.collectionView registerClass:[XLPageTitleCell class] forCellWithReuseIdentifier:@"XLPageTitleCell"];
    self.collectionView.showsHorizontalScrollIndicator = false;
    [self addSubview:self.collectionView];
    
    self.separatorLine = [[UIView alloc] init];
    self.separatorLine.backgroundColor = config.separatorLineColor;
    self.separatorLine.hidden = config.separatorLineHidden;
    [self addSubview:self.separatorLine];
    
    self.shadowLine = [[UIView alloc] init];
    self.shadowLine.bounds = CGRectMake(0, 0, self.config.shadowLineWidth, self.config.shadowLineHeight);
    self.shadowLine.backgroundColor = config.shadowLineColor;
    self.shadowLine.layer.cornerRadius =  self.config.shadowLineHeight/2.0f;
    if (self.config.shadowLineCap == XLPageShadowLineCapSquare) {
        self.shadowLine.layer.cornerRadius = 0;
    }
    self.shadowLine.layer.masksToBounds = true;
    self.shadowLine.hidden = config.shadowLineHidden;
    [self.collectionView addSubview:self.shadowLine];
    
    self.stopAnimation = false;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat collectionW = self.bounds.size.width;
    if (self.rightButton) {
        CGFloat btnW = self.bounds.size.height;
        collectionW = self.bounds.size.width - btnW;
        self.rightButton.frame = CGRectMake(self.bounds.size.width - btnW, 0, btnW, btnW);
    }
    self.collectionView.frame = CGRectMake(0, 0, collectionW, self.bounds.size.height);
    
    self.separatorLine.frame = CGRectMake(0, self.bounds.size.height - self.config.separatorLineHeight, self.bounds.size.width, self.config.separatorLineHeight);
    self.shadowLine.center = [self shadowLineCenterForIndex:_selectedIndex];
    [self.collectionView sendSubviewToBack:self.shadowLine];
    [self bringSubviewToFront:self.separatorLine];
}

#pragma mark -
#pragma mark CollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.dataSource pageTitleViewNumberOfTitle];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake([self widthForItemAtIndexPath:indexPath], collectionView.bounds.size.height - self.config.titleViewInset.top - self.config.titleViewInset.bottom);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XLPageTitleCell *cell = [self.dataSource pageTitleViewCellForItemAtIndex:indexPath.row];
    if (!cell) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"XLPageTitleCell" forIndexPath:indexPath];
    }
    cell.config = self.config;
    cell.textLabel.text = [self.dataSource pageTitleViewTitleForIndex:indexPath.row];
    [cell configCellOfSelected:(indexPath.row == self.selectedIndex)];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate pageTitleViewDidSelectedAtIndex:indexPath.row];
    self.selectedIndex = indexPath.row;
}

#pragma mark -
#pragma mark Setter
- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    [self updateLayout];
}

- (void)setRightButton:(UIButton *)rightButton {
    _rightButton = rightButton;
    [self addSubview:rightButton];
}

- (void)updateLayout {
    if (_selectedIndex == _lastSelectedIndex) {return;}
    
    //更新cellUI
    NSIndexPath *indexPath1 = [NSIndexPath indexPathForRow:_selectedIndex inSection:0];
    NSIndexPath *indexPath2 = [NSIndexPath indexPathForRow:_lastSelectedIndex inSection:0];
    [UIView performWithoutAnimation:^{
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath1,indexPath2]];
    }];
    
    
    //自动居中
    [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:_selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:true];
    
    //设置阴影位置
    self.shadowLine.center = [self shadowLineCenterForIndex:_selectedIndex];
    
    //保存上次选中位置
    _lastSelectedIndex = _selectedIndex;
}

- (void)setAnimationProgress:(CGFloat)animationProgress {
    if (self.stopAnimation) {return;}
    if (animationProgress == 0) {return;}
    
    //获取下一个index
    NSInteger targetIndex = animationProgress < 0 ? _selectedIndex - 1 : _selectedIndex + 1;
    if (targetIndex < 0 || targetIndex >= [self.dataSource pageTitleViewNumberOfTitle]) {return;}
    
    //获取cell
    XLPageTitleCell *currentCell = (XLPageTitleCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:_selectedIndex inSection:0]];
    XLPageTitleCell *targetCell = (XLPageTitleCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:targetIndex inSection:0]];
    
    //标题颜色过渡
    if (self.config.titleColorTransition) {
        
        [currentCell showAnimationOfProgress:fabs(animationProgress) type:XLPageTitleCellAnimationTypeSelected];
        
        [targetCell showAnimationOfProgress:fabs(animationProgress) type:XLPageTitleCellAnimationTypeWillSelected];
    }
    
    //给阴影添加动画
    [XLPageViewControllerUtil showAnimationToShadow:self.shadowLine shadowWidth:self.config.shadowLineWidth fromItemRect:currentCell.frame toItemRect:targetCell.frame type:self.config.shadowLineAnimationType progress:animationProgress];
}

//刷新方法
- (void)reloadData {
    [self.collectionView reloadData];
}

#pragma mark -
#pragma mark 阴影位置
- (CGPoint)shadowLineCenterForIndex:(NSInteger)index {
    XLPageTitleCell *cell = (XLPageTitleCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    CGFloat centerX = cell.center.x;
    CGFloat separatorLineHeight = self.config.separatorLineHidden ? 0 : self.config.separatorLineHeight;
    CGFloat centerY = self.bounds.size.height - self.config.shadowLineHeight/2.0f - separatorLineHeight;
    if (self.config.shadowLineAlignment == XLPageShadowLineAlignmentTop) {
        centerY = self.config.shadowLineHeight/2.0f;
    }
    if (self.config.shadowLineAlignment == XLPageShadowLineAlignmentCenter) {
        centerY = cell.center.y;
    }
    return CGPointMake(centerX, centerY);
}

#pragma mark -
#pragma mark 辅助方法
- (CGFloat)widthForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.config.titleWidth > 0) {
        return self.config.titleWidth;
    }
    
   CGFloat normalTitleWidth = [XLPageViewControllerUtil widthForText:[self.dataSource pageTitleViewTitleForIndex:indexPath.row] font:self.config.titleNormalFont size:self.bounds.size];
    
    CGFloat selectedTitleWidth = [XLPageViewControllerUtil widthForText:[self.dataSource pageTitleViewTitleForIndex:indexPath.row] font:self.config.titleSelectedFont size:self.bounds.size];
    
    return selectedTitleWidth > normalTitleWidth ? selectedTitleWidth : normalTitleWidth;
}

#pragma mark -
#pragma mark 自定cell方法
- (void)registerClass:(Class)cellClass forTitleViewCellWithReuseIdentifier:(NSString *)identifier {
    if (!identifier.length) {
        [NSException raise:@"This identifier must not be nil and must not be an empty string." format:@""];
    }
    if ([identifier isEqualToString:NSStringFromClass(XLPageTitleCell.class)]) {
        [NSException raise:@"please change an identifier" format:@""];
    }
    if (![cellClass isSubclassOfClass:[XLPageTitleCell class]]) {
        [NSException raise:@"The cell class must be a subclass of XLPageTitleCell." format:@""];
    }
    [self.collectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
}

- (__kindof XLPageTitleCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier forIndex:(NSInteger)index {
    if (!identifier.length) {
        [NSException raise:@"This identifier must not be nil and must not be an empty string." format:@""];
    }
    if ([identifier isEqualToString:NSStringFromClass(XLPageTitleCell.class)]) {
        [NSException raise:@"please change an identifier" format:@""];
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    if (!indexPath) {
        [NSException raise:@"please change an identifier" format:@""];
    }
    XLPageTitleCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    return cell;
}

@end
