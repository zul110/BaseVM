//
//  HomeModel.swift
//  BaseVM
//
//  Created by Zul on 8/22/17.
//
//

import Foundation
import ObjectMapper

class HomeModel: Mappable {
    var items: [ItemModel]?
    var itemCount: Int?
    
    init() { }
    
    required init?(map: Map) {
        mapping(map: map)
    }
    
    func mapping(map: Map) {
        items           <- map["items"]
        itemCount       <- map["itemCount"]
    }
}
