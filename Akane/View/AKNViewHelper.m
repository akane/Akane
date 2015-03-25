//
// This file is part of Akkane
//
// Created by JC on 23/03/15.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#include "AKNViewHelper.h"


__attribute__((overloadable)) UIView *view_instantiate(Class viewClass) { return [viewClass new]; };
__attribute__((overloadable)) UIView *view_instantiate(UINib *nib) {
    return [nib instantiateWithOwner:nil options:nil][0];
}