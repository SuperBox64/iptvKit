//
//  Category.swift
//  
//
//  Created by Todd Bruss on 9/26/21.
//

import Foundation

// MARK: - Category
public struct Category: Codable {
    public var categoryID: String
    public var categoryName: String
    public let parentID: Int
    public var uuid: UUID = UUID()
    enum CodingKeys: String, CodingKey {
        case categoryID = "category_id"
        case categoryName = "category_name"
        case parentID = "parent_id"
    }
}


// MARK: - SeriesCategory
public struct SeriesCategory: Codable {
    public let categoryID: String
    public let categoryName: String
    
    enum CodingKeys: String, CodingKey {
        case categoryID = "category_id"
        case categoryName = "category_name"
    }
}
