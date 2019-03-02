//
//  FileManager.swift
//  Eidetic
//
//  Created by user145467 on 11/21/18.
//  Copyright © 2018 user145467. All rights reserved.
//

import Foundation

public extension FileManager {
    static var applicationSupportDirectoryURL: URL {
        return `default`.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }
    
    static var documentDirectory: URL {
        return `default`.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static var dataFilesDirectoryURL: URL {
        return applicationSupportDirectoryURL.appendingPathComponent("Data Files")
    }
    
    static var tagsFileURL: URL {
        return dataFilesDirectoryURL.appendingPathComponent("tagsFile.json")
    }
    
    static var directoriesURL: URL {
        return dataFilesDirectoryURL.appendingPathComponent("directories.json")
    }
    
}


