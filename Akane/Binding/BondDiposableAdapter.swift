//
// This file is part of Akane
//
// Created by JC on 05/11/15.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

import Foundation
import Bond

class BondDisposableAdapter : Disposable {
    let disposable: DisposableType

    init(_ disposable: DisposableType) {
        self.disposable = disposable
    }

    func dispose() {
        self.disposable.dispose()
    }
}

extension CompositeDisposable : DisposableBag {
    func addDisposable(disposable: Disposable) {
        self.addDisposable(BlockDisposable() { disposable.dispose() })
    }
}