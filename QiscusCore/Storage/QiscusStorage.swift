//
//  QiscusStorage.swift
//  QiscusCore
//
//  Created by Qiscus on 16/08/18.
//

import Foundation

public class QiscusStorage {
    static var shared : QiscusStorage = QiscusStorage()
    private var room    : RoomStorage!
    
    init() {
        room    = RoomStorage()
    }
    
    /// Get rooms from local storage
    ///
    /// - Returns: Array of Rooms
    public func getRooms() -> [RoomModel] {
        return room.all()
    }
    
    func saveRoom(_ data: RoomModel) {
        room.add([data])
    }
    
    func saveRoom(_ data: [RoomModel]) {
        room.add(data)
    }
    
    func clearRoom() {
        room.removeAll()
    }
    
    func findRoom(byID id: String) -> RoomModel? {
        return room.find(byID: id)
    }
    
    func saveComment(_ data: CommentModel) {
        // update last comment in room
        if !room.updateLastComment(data) {
            QiscusLogger.errorPrint("filed to update last comment, mybe room not exist")
        }
    }
    
    func readComment(_ data: CommentModel) {
        // update unread count in room
        if !room.updateUnreadComment(data) {
            QiscusLogger.errorPrint("filed to update unread count, mybe room not exist")
        }
    }
    
    // take time, coz search in all rooms
    func getMember(byEmail email: String) -> MemberModel? {
        let rooms = self.getRooms()
        for room in rooms {
            guard let participants = room.participants else { return nil }
            for p in participants {
                if p.email == email {
                    return p
                }
            }
        }
        return nil
    }
    
    func getMember(byEmail email: String, inRoom room: RoomModel) -> MemberModel? {
        guard let participants = room.participants else { return nil }
        for p in participants {
            if p.email == email {
                return p
            }
        }
        return nil
    }
}
