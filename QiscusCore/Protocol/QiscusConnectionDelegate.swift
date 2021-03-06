//
//  QiscusConnectionDelegate.swift
//  QiscusCore
//
//  Created by Qiscus on 16/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import UIKit
import QiscusRealtime

public protocol QiscusConnectionDelegate {
    func disconnect(withError err: QError?)
    func connected()
    func connectionState(change state: QiscusConnectionState)
}

public enum QiscusConnectionState : String{
    case connecting     = "connecting"
    case connected      = "connected"
    case disconnected   = "disconnected"
}

public protocol QiscusCoreDelegate {
    // MARK: Event Room List
    
    /// new comment is comming
    ///
    /// - Parameters:
    ///   - room: room where event happen
    ///   - comment: new comment object
    func onRoom(_ room: RoomModel, gotNewComment comment: CommentModel)
    
    /// Deleted Comment
    ///
    /// - Parameter comment: comment deleted
    func onRoom(_ room: RoomModel, didDeleteComment comment: CommentModel)
    
    /// comment status change
    ///
    /// - Parameters:
    ///   - comment: new comment where status is change, you can compare from local data
    ///   - status: comment status, exp: deliverd, receipt, or read.
    ///     special case for read, for example we have message 1,2,3,4,5 then you got status change for message 5 it's mean message 1-4 has been read
    func onRoomDidChangeComment(comment: CommentModel, changeStatus status: CommentStatus)
    
    /// Room update
    ///
    /// - Parameter room: new room object
    func onRoom(update room: RoomModel)
    
    /// Deleted room
    ///
    /// - Parameter room: object room
    func onRoom(deleted room: RoomModel)
    
    func gotNew(room: RoomModel)
    
    func remove(room: RoomModel)
}

public protocol QiscusCoreRoomDelegate {
    // MARK: Comment Event in Room
    
    /// new comment is comming
    ///
    /// - Parameters:
    ///   - comment: new comment object
    func gotNewComment(comment: CommentModel)
    
    /// comment status change
    ///
    /// - Parameters:
    ///   - comment: new comment where status is change, you can compare from local data
    ///   - status: comment status, exp: deliverd, receipt, or read.
    ///     special case for read, for example we have message 1,2,3,4,5 then you got status change for message 5 it's mean message 1-4 has been read
    func didComment(comment: CommentModel, changeStatus status: CommentStatus)
    
    /// Deleted Comment
    ///
    /// - Parameter comment: comment deleted
    func didDelete(Comment comment: CommentModel)
    
    // MARK: User Event in Room
    
    /// User Typing Indicator
    ///
    /// - Parameters:
    ///   - user: object user or participant
    ///   - typing: true if user start typing and false when finish typing. typing time avarange is 5-10s, we assume user typing is finish after that
    func onRoom(thisParticipant user: MemberModel, isTyping typing: Bool)
    
    /// User Online status
    ///
    /// - Parameters:
    ///   - user: object member
    ///   - status: true if user login
    ///   - time: millisecond UTC
    func onChangeUser(_ user: MemberModel, onlineStatus status: Bool, whenTime time: Date)
    
    /// Room update
    ///
    /// - Parameter room: new room object
    func onRoom(update room: RoomModel)
}
