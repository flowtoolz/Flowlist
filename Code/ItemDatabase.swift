import SwiftObserver

protocol ItemDatabase: Observable where UpdateType == ItemDatabaseEvent
{
    
}

enum ItemDatabaseEvent { case didNothing }
