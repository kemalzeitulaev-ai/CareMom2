import Foundation
import SwiftData

enum FamilyShareService {
    static func exportForFamily(children: [Child]) throws -> URL {
        try BackupService.exportData(children: children)
    }
}
