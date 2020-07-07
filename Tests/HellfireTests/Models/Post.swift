//
//  Post.swift
//  Hellfire_Example
//
//  Created by Ed Hellyer on 9/2/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import Hellfire

struct Post: JSONSerializable {
    var postId: Int
    var id: Int
    var name: String
    var email: String
    var body: String
}
