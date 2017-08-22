//
//  ItemModel.swift
//  BaseVM
//
//  Created by Zul on 8/22/17.
//
//

import Foundation
import ObjectMapper

class ItemModel: Mappable {
    var title: String?
    var description: String?
    var itemCount: Int?
    
    init() { }
    
    required init?(map: Map) {
        mapping(map: map)
    }
    
    func mapping(map: Map) {
        title           <- map["title"]
        description     <- map["description"]
    }
}
