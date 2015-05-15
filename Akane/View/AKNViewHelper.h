//
// This file is part of Akkane
//
// Created by JC on 23/03/15.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import <UIKit/UIKit.h>

@protocol AKNPresenter;
@protocol AKNViewConfigurable;

__attribute__((overloadable)) UIView *view_instantiate(Class viewClass);
__attribute__((overloadable)) UIView *view_instantiate(UINib *nib);

id<AKNPresenter> view_presenter_new(UIView<AKNViewConfigurable> *view);