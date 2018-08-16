//
//  RoomStorage.swift
//  QiscusCore
//
//  Created by Qiscus on 16/08/18.
//
//  Responsiblilities :
//  save room from restAPI in temp(variable)
//  save room in local storage
//  get rooms from local storage

import Foundation

class RoomStorage {
    var data : [RoomModel] = [RoomModel]()
    var delegate = QiscusCore.eventManager.delegate
    init() {
        // MARK: TODO load data rooms from local storage to var data
    }
    
    func add(_ value: [RoomModel]) {
        // filter if room exist update, if not add
        for room in value {
            if let r = find(byID: room.id)  {
                if !updateRoomDataEvent(old: r, new: room) {
                    // add new room
                    data.insert(room, at: 0)
                    // publish event add new room
                    delegate?.gotNew(room: room)
                }
            }else {
                // add new room
                data.insert(room, at: 0)
                // publish event add new room
                delegate?.gotNew(room: room)
            }
        }
        // mark Todo update last comment
        QiscusLogger.debugPrint("number of room in local temp : \(data.count)")
    }
    
    // update/replace === identical object
    private func updateRoomDataEvent(old: RoomModel, new: RoomModel) -> Bool{
        if let index = data.index(where: { $0 === old }) {
            data[index] = new
            QiscusLogger.debugPrint("room \(new.name), unreadCount \(new.unreadCount)")
            return true
        }else {
            return false
        }
    }
    
    func find(byID id: String) -> RoomModel? {
        if data.isEmpty {
            return nil
        }else {
            return data.filter{ $0.id == id }.first
        }
    }
    
    /// Update last comment in room
    ///
    /// - Parameter comment: new comment object
    /// - Returns: true if room already exist and false if room unavailable
    func updateLastComment(_ comment: CommentModel) -> Bool {
        if let r = find(byID: String(comment.roomId)) {
            let new = r
            new.lastComment = comment
            new.unreadCount = new.unreadCount + 1
            return updateRoomDataEvent(old: r, new: new)
        }else {
            return false
        }
    }
    
    
    /// Update unread count -1 to read
    ///
    /// - Parameter comment: new comment object already read
    /// - Returns: true if room already exist and false if room unavailable
    func updateUnreadComment(_ comment: CommentModel) -> Bool {
        if let r = find(byID: String(comment.roomId)) {
            let new = r
            // compare comment
            if let lastComment = r.lastComment {
                if comment.id == lastComment.id {
                    new.unreadCount = new.unreadCount - 1
                    return updateRoomDataEvent(old: r, new: new)
                }else { return false }
            }else { return false }
        }else {
            return false
        }
    }
    
    func readComments(_ comment : [CommentModel]) {
        // calculate
        
    }
    
}