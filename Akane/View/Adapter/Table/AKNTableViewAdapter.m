//
// This file is part of Akane
//
// Created by JC on 05/02/15.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "AKNTableViewAdapter.h"
#import "AKNViewConfigurable.h"
#import "AKNDataSource.h"
#import "AKNItemViewModelProvider.h"
#import "AKNViewCache.h"
#import "AKNItemViewModel.h"
#import <objc/runtime.h>

CGFloat const TableViewAdapterDefaultRowHeight = 44.f;
NSString *const TableViewAdapterCellContentView;

@interface AKNTableViewAdapter () <AKNViewCache>
@property(nonatomic, strong)NSMutableDictionary *sectionModels;
@property(nonatomic, strong)NSMutableDictionary *indexPathModels;
@property(nonatomic, strong)NSMutableDictionary *reusableViews;
@property(nonatomic, strong)NSMutableDictionary *prototypeViews;

@property(nonatomic, weak)UITableView           *tableView;

@end

@implementation AKNTableViewAdapter

- (instancetype)initWithTableView:(UITableView *)tableView {
    if (!(self = [super init])) {
        return nil;
    }

    self.sectionModels = [NSMutableDictionary new];
    self.indexPathModels = [NSMutableDictionary new];
    self.reusableViews = [NSMutableDictionary new];
    self.prototypeViews = [NSMutableDictionary new];

    self.tableView = tableView;

    return self;
}

- (id<AKNItemViewModel>)sectionModel:(NSInteger)section {
    id<AKNItemViewModel> model = self.sectionModels[@(section)];

    if (!model) {
        id item = [self.dataSource supplementaryItemAtSection:section];

        model = [self.itemViewModelProvider supplementaryItemViewModel:item];

        self.sectionModels[@(section)] = model;
    }

    return model;
}

- (id<AKNItemViewModel>)indexPathModel:(NSIndexPath *)indexPath {
    id<AKNItemViewModel> model = self.indexPathModels[indexPath];

    if (!model) {
        id item = [self.dataSource itemAtIndexPath:indexPath];

        model = [self.itemViewModelProvider itemViewModel:item];

        self.indexPathModels[indexPath] = model;
    }

    return model;
}

#pragma mark - Table delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (self.dataSource && self.itemViewModelProvider) ? [self.dataSource numberOfSections] : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataSource numberOfItemsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id<AKNItemViewModel> viewModel = [self indexPathModel:indexPath];
    NSString *identifier = [self.itemViewModelProvider viewIdentifier:viewModel];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

    [self cellContentView:cell withIdentifier:identifier].viewModel = viewModel;

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    id<AKNItemViewModel> viewModel = [self indexPathModel:indexPath];
    NSString *identifier = [self.itemViewModelProvider viewIdentifier:viewModel];
    UITableViewCell *cell = [self prototypeCellWithReuseIdentifier:identifier];

    [self cellContentView:cell withIdentifier:identifier].viewModel = viewModel;

    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;

    if (height == 0) {
        NSLog(@"Detected a case where constraints ambiguously suggest a height of zero for a tableview cell's content view.\
              We're considering the collapse unintentional and using %f height instead", TableViewAdapterDefaultRowHeight);

        height = TableViewAdapterDefaultRowHeight;
    }

    return height;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id<AKNItemViewModel> viewModel = [self indexPathModel:indexPath];

    return [viewModel canSelect] ? indexPath : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id<AKNItemViewModel> viewModel = [self indexPathModel:indexPath];

    [viewModel selectItem];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    id<AKNItemViewModel> sectionViewModel = [self sectionModel:section];
    NSString *identifier = [self.itemViewModelProvider supplementaryViewIdentifier:sectionViewModel];
    identifier = [identifier stringByAppendingString:UICollectionElementKindSectionHeader];

    if (!identifier) {
        return nil;
    }

    id reusableView = self.reusableViews[identifier];
    UIView<AKNViewConfigurable> *view = ([reusableView isKindOfClass:[UINib class]]) ? [reusableView instantiateWithOwner:nil options:nil][0] : [reusableView new];

    view.viewModel = sectionViewModel;

    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    id<AKNItemViewModel> sectionViewModel = [self sectionModel:section];
    NSString *identifier = [self.itemViewModelProvider supplementaryViewIdentifier:sectionViewModel];
    identifier = [identifier stringByAppendingString:UICollectionElementKindSectionHeader];

    if (!identifier) {
        return 0;
    }

    UITableViewHeaderFooterView *sectionView = [self prototypeSectionWithReuseIdentifier:identifier];

    [self cellContentView:(UITableViewCell *)sectionView withIdentifier:identifier].viewModel = sectionViewModel;

    CGFloat height = [sectionView.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;

    if (height == 0) {
        NSLog(@"Detected a case where constraints ambiguously suggest a height of zero for a tableview cell's content view.\
              We're considering the collapse unintentional and using %f height instead", TableViewAdapterDefaultRowHeight);

        height = TableViewAdapterDefaultRowHeight;
    }
    
    return height;}

#pragma mark - Internal

- (UIView<AKNViewConfigurable> *)cellContentView:(UITableViewCell *)cell withIdentifier:(NSString *)identifier {
    UIView<AKNViewConfigurable> *view = objc_getAssociatedObject(cell, &TableViewAdapterCellContentView);

    if (!view) {
        id reusableView = self.reusableViews[identifier];
        view = ([reusableView isKindOfClass:[UINib class]]) ? [reusableView instantiateWithOwner:nil options:nil][0] : [reusableView new];
        NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(view);

        view.translatesAutoresizingMaskIntoConstraints = NO;

        [cell.contentView addSubview:view];
        [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:0 views:viewsDictionary]];
        [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:0 views:viewsDictionary]];

        objc_setAssociatedObject(cell, &TableViewAdapterCellContentView, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return view;
}

- (UITableViewCell *)prototypeCellWithReuseIdentifier:(NSString *)identifier {
    UITableViewCell *cell = self.prototypeViews[identifier];

    if (!cell) {
        cell = [UITableViewCell new];
        self.prototypeViews[identifier] = cell;
    }

    return cell;
}

- (UITableViewHeaderFooterView *)prototypeSectionWithReuseIdentifier:(NSString *)identifier {
    UITableViewHeaderFooterView *sectionView = self.prototypeViews[identifier];

    if (!sectionView) {
        sectionView = [UITableViewHeaderFooterView new];
        self.prototypeViews[identifier] = sectionView;
    }

    return sectionView;
}

#pragma mark - ViewCacher delegate

- (void)registerNibName:(NSString *)nibName withReuseIdentifier:(NSString *)identifier {
    self.reusableViews[identifier] = [UINib nibWithNibName:nibName bundle:nil];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:identifier];
}

- (void)registerView:(Class)viewClass withReuseIdentifier:(NSString *)identifier {
    self.reusableViews[identifier] = viewClass;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:identifier];
}

- (void)registerNibName:(NSString *)nibName supplementaryElementKind:(NSString *)kind withReuseIdentifier:(NSString *)identifier {
    identifier = [identifier stringByAppendingString:kind];

    self.reusableViews[identifier] = [UINib nibWithNibName:nibName bundle:nil];
    [self.tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:identifier];
}

- (void)registerView:(Class)viewClass supplementaryElementKind:(NSString *)kind withReuseIdentifier:(NSString *)identifier {
    identifier = [identifier stringByAppendingString:kind];

    self.reusableViews[identifier] = viewClass;
    [self.tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:identifier];
}

#pragma mark - Setters

- (void)setTableView:(UITableView *)tableView {
    if (_tableView == tableView) {
        return;
    }

    _tableView = tableView;

    _tableView.dataSource = self;
    _tableView.delegate = self;
}

- (void)setItemViewModelProvider:(id<AKNItemViewModelProvider>)itemViewModelProvider {
    if (_itemViewModelProvider == itemViewModelProvider) {
        return;
    }

    _itemViewModelProvider = itemViewModelProvider;
    [self.itemViewModelProvider registerViews:self];
    [_tableView reloadData];
}

- (void)setDataSource:(id<AKNDataSource>)dataSource {
    if (_dataSource == dataSource) {
        return;
    }

    _dataSource = dataSource;
    [_tableView reloadData];
}

@end