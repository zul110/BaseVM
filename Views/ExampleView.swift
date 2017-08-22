//
//  ExampleView.swift
//  BaseVM
//
//  Created by Zul on 8/22/17.
//
//

import Foundation

class ExampleView {
    var homeVM: HomeViewModel! {
        didSet {
            self.homeVM.setDelegate(delegate: self)
            self.homeVM.getData()
        }
    }
    
    init() {
        initHomeViewModel()
    }
    
    func initHomeViewModel() {
        self.homeVM = HomeViewModel()
    }
}
