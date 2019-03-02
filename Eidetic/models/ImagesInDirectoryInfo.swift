//
//  ImageStruct.swift
//  Eidetic
//
//  Created by user145467 on 11/21/18.
//  Copyright © 2018 user145467. All rights reserved.
//

import Foundation
import UIKit

struct Directory: Decodable, Encodable {
    var id: String
    var imageIDs: Set<String>
    
    enum DecodingError: Error {
        case missingFile
    }
}

extension Array where Element == Directory {
    init() throws{
        let url = URL(fileURLWithPath: "directories.json", relativeTo: FileManager.directoriesURL)
        
        let decoder = JSONDecoder()
        let data = try Data(contentsOf: url)
        self = try decoder.decode([Directory].self, from: data)
    }
    
    func save() throws{
        let jsonEncoder = JSONEncoder()
        let jsonData = try jsonEncoder.encode(self)
        
        try jsonData.write(to: FileManager.directoriesURL, options: .atomic)
    }
    
    func read() throws ->[Directory]{
        let url = URL(fileURLWithPath: "directories.json", relativeTo: FileManager.directoriesURL)
        let decoder = JSONDecoder()
        let data = try Data(contentsOf: url)
        let result = try decoder.decode([Directory].self, from: data )
        return result
    }
}
