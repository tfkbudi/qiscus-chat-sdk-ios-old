//
//  RoomEvent.swift
//  QiscusCore
//
//  Created by Qiscus on 29/10/18.
//

import Foundation
import SwiftyJSON

public struct RoomEvent {
    public let sender  : String
    public let data    : [String:Any]
}

enum SyncEventTopic : String {
    case deletedMessage = "deleted_message"
    case clearRoom      = "clear_room"
}

struct SyncEvent {
    let id          : Int64
    let timestamp   : Int64
    let actionTopic : SyncEventTopic
    let payload     : [String:Any]
    
    init(json: JSON) {
        self.id = json["id"].int64 ?? 0
        self.timestamp  = json["timestamp"].int64 ?? 0
        self.actionTopic  = SyncEventTopic(rawValue: json["action_topic"].string ?? "") ?? .deletedMessage
        self.payload    = json["payload"].dictionaryObject ?? [:]
    }
}

extension SyncEvent {
    func getDeletedMessageUniqId() -> [String] {
        var result : [String] = [String]()
        guard let data = payload["data"] as? [String:Any] else {
            return result
        }
        guard let messages = data["deleted_messages"] as? [[String:Any]] else {
            return result
        }
        
        messages.forEach { (message) in
            if let _message = message["message_unique_ids"] as? [String] {
                _message.forEach({ (id) in
                    result.append(id)
                })
            }
        }
        
        return result
    }
    
    func getClearRoomUniqId() -> [String] {
        var result : [String] = [String]()
        guard let data = payload["data"] as? [String:Any] else {
            return result
        }
        guard let rooms = data["deleted_rooms"] as? [[String:Any]] else {
            return result
        }
        
        rooms.forEach { (room) in
            if let id = room["unique_id"] as? String {
                result.append(id)
            }
        }
        
        return result
    }
}
