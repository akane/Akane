//
// This file is part of Akkane
//
// Created by JC on 02/01/15.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "AKNView.h"
#import "AKNViewModel.h"
#import <EventListener.h>

@implementation AKNView

- (void)setViewModel:(id<AKNViewModel>)viewModel {
    if (_viewModel == viewModel) {
        return;
    }

    _viewModel = viewModel;
    [self configure];

    if (self.window) {
        [self attachViewModel];
    }
}

- (void)configure {
    // Default implementation do nothing
}

- (void)didMoveToWindow {
    if (self.window) {
        [self attachViewModel];
    }
}

// This avoid some conflicts when view is inside a Cell
// Might not be necessary if we define that every AKNView/AKNViewModel is associated to a presenter?
- (void)attachViewModel {
    _viewModel.eventDispatcher = self;
}

@end