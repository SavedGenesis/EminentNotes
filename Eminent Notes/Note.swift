import Foundation
import CoreData

@objc(Note)
public class Note: NSManagedObject, Identifiable {
    @NSManaged public var title: String?
    @NSManaged public var content: String?
    @NSManaged public var creationDate: Date?
    @NSManaged public var modificationDate: Date?
    @NSManaged public var isArchived: Bool
    @NSManaged public var isPinned: Bool
    
    public static let entityName = "Note"
    
    // Relationships
    @NSManaged public var tags: NSSet?
    @NSManaged public var folder: Folder?
    
    // Convenience properties
    public var tagArray: [Tag] {
        let set = tags as? Set<Tag> ?? []
        return set.sorted { $0.name ?? "" < $1.name ?? "" }
    }
}

// Extension for fetching Notes
extension Note {
    static func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: Note.entityName)
    }
    
    static func fetchRecent(context: NSManagedObjectContext, limit: Int = 10) -> [Note] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isArchived == %@", NSNumber(value: false))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.modificationDate, ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching recent notes: \(error)")
            return []
        }
    }
}

extension Note {
    func addToTags(_ tag: Tag) {
        let currentTags = self.tags ?? NSSet()
        let newTags = NSMutableSet(set: currentTags)
        newTags.add(tag)
        self.tags = newTags
    }
}
