import Foundation
import CoreData

@objc(Tag)
public class Tag: NSManagedObject, Identifiable {
    @NSManaged public var name: String?
    @NSManaged public var colorHex: String?
    
    public static let entityName = "Tag"
    
    // Relationships
    @NSManaged public var notes: NSSet?
    
    // Convenience properties
    public var noteArray: [Note] {
        let set = notes as? Set<Note> ?? []
        return set.sorted { $0.modificationDate ?? Date() > $1.modificationDate ?? Date() }
    }
}

extension Tag {
    static func fetchRequest() -> NSFetchRequest<Tag> {
        return NSFetchRequest<Tag>(entityName: Tag.entityName)
    }
    
    static func fetchAll(context: NSManagedObjectContext) -> [Tag] {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching tags: \(error)")
            return []
        }
    }
}
