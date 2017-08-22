//
//  HomeVM.swift
//  BaseVM
//
//  Created by Zul on 8/22/17.
//
//

import Foundation
import SwiftyJSON
import ObjectMapper

class HomeViewModel: BaseViewModel {
    var homeData: HomeModel!
    
    override init() {
        super.init()
        
        self.apiToUse = API.home
    }
    
    override func getData() {
        print("HomeVM getData")
        
        self.getResponse(usingHttpMethod: .GET, onAPI: self.apiToUse, withParameters: self.parameters, andSuccessBlock: self.success)
    }
    
    override func success(response: JSON) {
        print(response.rawString()!)
        
        self.homeData = Mapper<HomeModel>().map(JSONObject: response.object)
        
        self.delegate.dataDidLoad()
    }
    
    override func displayData() {
        print("HomeVM displayData")
    }
}
