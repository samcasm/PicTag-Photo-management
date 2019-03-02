//
//  ImageStruct.swift
//  Eidetic
//
//  Created by user145467 on 11/21/18.
//  Copyright © 2018 user145467. All rights reserved.
//

import Foundation
import UIKit

struct Images: Decodable, Encodable {
    var id: String
    var tags: Set<String>
    var isFavorite: Bool
    
    enum DecodingError: Error {
        case missingFile
    }
}

extension Array where Element == Images {
    init() throws {
        let url = URL(fileURLWithPath: "tagsFile.json", relativeTo: FileManager.tagsFileURL)
        
        let decoder = JSONDecoder()
        let data = try Data(contentsOf: url)
        self = try decoder.decode([Images].self, from: data)
    }
    
    func save() throws{
        let jsonEncoder = JSONEncoder()
        let jsonData = try jsonEncoder.encode(self)
        
        try jsonData.write(to: FileManager.tagsFileURL, options: .atomic)
    }
    
    func read() throws ->[Images]{
        let url = URL(fileURLWithPath: "tagsFile.json", relativeTo: FileManager.tagsFileURL)
        let decoder = JSONDecoder()
        let data = try Data(contentsOf: url)
        let result = try decoder.decode([Images].self, from: data )
        return result
    }
}
