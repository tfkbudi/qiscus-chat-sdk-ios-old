//
//  QiscusRoom.swift
//  QiscusCore
//
//  Created by Qiscus on 17/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import Foundation

// MARK: Room Management
extension QiscusCore {
    /// Get or create room with participant
    ///
    /// - Parameters:
    ///   - withUsers: Qiscus user emaial.
    ///   - completion: Qiscus Room Object and error if exist.
    public func getRoom(withUser user: String, avatarUrl: URL? = nil, distincId: String? = nil, options: String? = nil, onSuccess: @escaping (RoomModel, [CommentModel]) -> Void, onError: @escaping (QError) -> Void) {
        // call api get_or_create_room_with_target
        QiscusCore.network.getOrCreateRoomWithTarget(targetSdkEmail: user,avatarUrl: avatarUrl, distincId: distincId, options: options, onSuccess: { (room, comments) in
            QiscusCore.database.room.save([room])
            var c = [CommentModel]()
            if let _comments = comments {
                // save comments
                QiscusCore.database.comment.save(_comments,publishEvent: false)
                c = _comments
            }
            onSuccess(room,c)
        }) { (error) in
            onError(error)
        }
    }
    
    /// Get or create room by channel name
    /// If room with predefined unique id is not exist then it will create a new one with requester as the only one participant. Otherwise, if room with predefined unique id is already exist, it will return that room and add requester as a participant.
    /// When first call (room is not exist), if requester did not send avatar_url and/or room name it will use default value. But, after the second call (room is exist) and user (requester) send avatar_url and/or room name, it will be updated to that value. Object changed will be true in first call and when avatar_url or room name is updated.
    
    /// - Parameters:
    ///   - channel: channel name or channel id
    ///   - name: channel name
    ///   - avatarUrl: url avatar
    ///   - options: option
    ///   - onSuccess: return object room
    ///   - onError: return object QError
    public func getRoom(withChannel channel: String, name: String? = nil, avatarUrl: URL? = nil, options: String? = nil, onSuccess: @escaping (RoomModel) -> Void, onError: @escaping (QError) -> Void) {
        // call api get_room_by_id
        QiscusCore.network.getOrCreateChannel(uniqueId: channel, name: name, avatarUrl: avatarUrl, options: options) { (rooms, comments, error) in
            if let room = rooms {
                // save room
                QiscusCore.database.room.save([room])
                var c = [CommentModel]()
                if let _comments = comments {
                    // save comments
                    QiscusCore.database.comment.save(_comments)
                    c = _comments
                }
                onSuccess(room)
            }else {
                onError(QError(message: error ?? "Unexpected error"))
            }
        }
    }
    
    /// Get room with room id
    ///
    /// - Parameters:
    ///   - withID: existing roomID from server or local db.
    ///   - completion: Response Qiscus Room Object and error if exist.
    public func getRoom(withID id: String, onSuccess: @escaping (RoomModel, [CommentModel]) -> Void, onError: @escaping (QError) -> Void) {
        if id == "0"{
            onError(QError(message:"Please check your roomID, now your roomID is =\(id)"))
        }else{
            // call api get_room_by_id
            QiscusCore.network.getRoomById(roomId: id, onSuccess: { (room, comments) in
                // save room
                if let comments = comments {
                    room.lastComment = comments.first
                }
                
                QiscusCore.database.room.save([room])
                
                // save comments
                var c = [CommentModel]()
                if let _comments = comments {
                    // save comments
                    QiscusCore.database.comment.save(_comments,publishEvent: false)
                    c = _comments
                }
                onSuccess(room,c)
            }) { (error) in
                onError(error)
            }
        }
    }
    
    /// Get Room info
    ///
    /// - Parameters:
    ///   - withId: array of room id
    ///   - showParticipant : default is false
    ///   - showRemoved : default is false
    ///   - completion: Response new Qiscus Room Object and error if exist.
    public func getRooms(withId ids: [String], showParticipant: Bool = false, showRemoved: Bool = false, onSuccess: @escaping ([RoomModel]) -> Void, onError: @escaping (QError) -> Void) {
        if ConfigManager.shared.appID != nil {
            if QiscusCore.isLogined {
                QiscusCore.network.getRoomInfo(roomIds: ids, roomUniqueIds: nil, showParticipant: showParticipant, showRemoved: showRemoved){ (rooms, error) in
                    if let data = rooms {
                        // save room
                        QiscusCore.database.room.save(data)
                        onSuccess(data)
                    }else {
                        onError(error ?? QError(message: "Unexpected error"))
                    }
                }
            }else{
                onError(QError(message: "please login Qiscus first before register deviceToken"))
            }
        }else{
            onError(QError(message: "please setupAPPID first before call api"))
        }
    }
    
    /// Get Room info
    ///
    /// - Parameters:
    ///   - ids: Unique room id
    ///   - showParticipant : default is false
    ///   - showRemoved : default is false
    ///   - completion: Response new Qiscus Room Object and error if exist.
    public func getRooms(withUniqueId ids: [String],showParticipant: Bool = false, showRemoved: Bool = false, onSuccess: @escaping ([RoomModel]) -> Void, onError: @escaping (QError) -> Void) {
        if ConfigManager.shared.appID != nil {
            if QiscusCore.isLogined {
                QiscusCore.network.getRoomInfo(roomIds: nil, roomUniqueIds: ids, showParticipant: showParticipant, showRemoved: showRemoved){ (rooms, error) in
                    if let data = rooms {
                        // save room
                        QiscusCore.database.room.save(data)
                        onSuccess(data)
                    }else {
                        onError(error ?? QError(message: "Unexpected error"))
                    }
                }
            }else{
                onError(QError(message: "please login Qiscus first before register deviceToken"))
            }
        }else{
            onError(QError(message: "please setupAPPID first before call api"))
        }
    }
    
    /// getAllRoom
    ///
    /// - Parameter completion: First Completion will return data from local if exis, then return from server with meta data(totalpage,current). Response new Qiscus Room Object and error if exist.
    public func getAllRoom(limit: Int? = nil, page: Int? = nil, showRemoved: Bool = false, showEmpty: Bool = false,onSuccess: @escaping ([RoomModel],Meta?) -> Void, onError: @escaping (QError) -> Void) {
        // api get room lists
      
        QiscusCore.network.getRoomList(limit: limit, page: page, showRemoved: showRemoved, showEmpty: showEmpty) { (data, meta, error) in
            if let rooms = data {
                // save room
                QiscusCore.database.room.save(rooms)
                rooms.forEach({ (_room) in
                    if let _comment = _room.lastComment {
                        // save last comment
                        QiscusCore.database.comment.save([_comment])
                    }
                })

                onSuccess(rooms,meta)
            }else {
                onError(QError(message: error ?? "Something Wrong"))
            }
        }
    }
    
    /// Create new Group room
    ///
    /// - Parameters:
    ///   - withName: Name of group
    ///   - participants: arrau of user id/qiscus email
    ///   - completion: Response Qiscus Room Object and error if exist.
    public func createGroup(withName name: String, participants: [String], avatarUrl url: URL?, onSuccess: @escaping (RoomModel) -> Void, onError: @escaping (QError) -> Void) {
        // call api create_room
        QiscusCore.network.createRoom(name: name, participants: participants, avatarUrl: url) { (room, error) in
            // save room
            if let data = room {
                QiscusCore.database.room.save([data])
                onSuccess(data)
            }else {
                guard let message = error else {
                    onError(QError(message: "Something Wrong"))
                    return
                }
               onError(QError(message: message))
            }
        }
    }
    
    /// update Group or channel
    ///
    /// - Parameters:
    ///   - id: room id, where room type not single. group and channel is approved
    ///   - name: new room name optional
    ///   - avatarURL: new room Avatar
    ///   - options: String, and JSON string is approved
    ///   - completion: Response new Qiscus Room Object and error if exist.
    public func updateRoom(withID id: String, name: String?, avatarURL url: URL?, options: String?, onSuccess: @escaping (RoomModel) -> Void, onError: @escaping (QError) -> Void) {
        // call api update_room
        QiscusCore.network.updateRoom(roomId: id, roomName: name, avatarUrl: url, options: options) { (room, error) in
            if let data = room {
                QiscusCore.database.room.save([data])
                onSuccess(data)
            }else {
                guard let message = error else {
                    onError(QError(message: "Something Wrong"))
                    return
                }
                onError(message)
            }
        }
    }
    
    /// Add new participant in room(Group)
    ///
    /// - Parameters:
    ///   - userEmails: qiscus user email
    ///   - roomId: room id
    ///   - completion:  Response new Qiscus Participant Object and error if exist.
    public func addParticipant(userEmails emails: [String], roomId: String, onSuccess: @escaping ([MemberModel]) -> Void, onError: @escaping (QError) -> Void) {
        
        QiscusCore.network.addParticipants(roomId: roomId, userSdkEmail: emails) { (members, error) in
            if let _members = members {
                // Save participant in local
                QiscusCore.database.member.save(_members, roomID: roomId)
                onSuccess(_members)
            }else{
                if let _error = error {
                    onError(_error)
                }else {
                    onError(QError(message: "Unexpected Error"))
                }
            }
        }
    }
    
    /// remove users from room(Group)
    ///
    /// - Parameters:
    ///   - emails: array qiscus email
    ///   - roomId: room id (group)
    ///   - completion: Response true if success and error if exist
    public func removeParticipant(userEmails emails: [String], roomId: String, onSuccess: @escaping (Bool) -> Void, onError: @escaping (QError) -> Void) {
        QiscusCore.network.removeParticipants(roomId: roomId, userSdkEmail: emails) { (result, error) in
            if result {
                onSuccess(result)
            }else {
                if let _error = error {
                    onError(_error)
                }else {
                    onError(QError(message: "Unexpected Error"))
                }
            }
        }
    }
    
    /// get participant by room id
    ///
    /// - Parameters:
    ///   - roomUniqeId: room id (group)
    ///   - offset : default is nil
    ///   - sorting : default is asc
    ///   - completion: Response new Qiscus Participant Object and error if exist.
    public func getParticipant(roomUniqeId id: String, offset: Int? = nil, sorting: SortType? = nil, onSuccess: @escaping ([MemberModel]) -> Void, onError: @escaping (QError) -> Void ) {
        QiscusCore.network.getParticipants(roomUniqeId: id, offset: offset, sorting: sorting) { (members, error) in
            if let _members = members {
                onSuccess(_members)
            }else{
                if let _error = error {
                    onError(_error)
                }else {
                    onError(QError(message: "Unexpected Error"))
                }
            }
        }
    }
    
    public func leaveRoom(by roomId:String, onSuccess: @escaping (Bool) -> Void, onError: @escaping (QError) -> Void) {
        guard let user = QiscusCore.getProfile() else {
            onError(QError(message: "User not found, please login to continue"))
            return
        }
        guard let room = QiscusCore.database.room.find(id: roomId) else {
            onError(QError(message: "Room not Found"))
            return
        }
        _ = QiscusCore.database.room.delete(room)
        QiscusCore.shared.removeParticipant(userEmails: [user.email], roomId: roomId, onSuccess: onSuccess, onError: onError)
    }
    
    public func subscribeEvent(roomID: String, onEvent: @escaping (RoomEvent) -> Void) {
        return QiscusCore.realtime.subscribeEvent(roomID: roomID, onEvent: onEvent)
    }
    
    public func unsubscribeEvent(roomID: String) {
        QiscusCore.realtime.unsubscribeEvent(roomID: roomID)
    }
    
    public func publishEvent(roomID: String, payload: [String : Any]) -> Bool {
        return QiscusCore.realtime.publishEvent(roomID: roomID, payload: payload)
    }
    
    public func subscribeTyping(roomID: String, onTyping: @escaping (RoomTyping) -> Void) {
        return QiscusCore.realtime.subscribeTyping(roomID:roomID, onTyping: onTyping)
    }
    
    public func unsubscribeTyping(roomID: String) {
        QiscusCore.realtime.unsubscribeTyping(roomID: roomID)
    }
}
