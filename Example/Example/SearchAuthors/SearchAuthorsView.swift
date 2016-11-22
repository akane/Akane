//
//  SearchAuthorsView.swift
//  Example
//
//  Created by Martin MOIZARD-LANVIN on 15/09/16.
//  Copyright © 2016 Akane. All rights reserved.
//

import Foundation
import Akane

class SearchAuthorsView : UIView, ComponentView {
   @IBOutlet var searchField: UITextField!
   @IBOutlet var authorsView: AuthorsView!
   
   func bindings(_ observer: ViewObserver, viewModel: AnyObject) {
      let viewModel = viewModel as! SearchAuthorsViewModel
      observer.observe(viewModel.searchFor).bindTo(self.searchField, events: [.valueChanged, .editingChanged])
      observer.observe(viewModel.authorsViewModel).bindTo(authorsView);
   }
}
