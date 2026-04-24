//
//  Product.swift
//  ShoppingAI
//
//  Created by 김은찬 on 7/13/25.
//

import SwiftUI
import UIKit

struct Product: Identifiable, Equatable, Codable {
    let id: UUID
    var imageData: Data?
    var name: String
    var price: String
    var url: String
    var purchaseDesire: Int
    var usageContext: String
    var features: String
    var category: String

    static func == (lhs: Product, rhs: Product) -> Bool {
        lhs.id == rhs.id
    }
}

extension Product {
    var image: UIImage? {
        imageData.flatMap { UIImage(data: $0) }
    }
}
