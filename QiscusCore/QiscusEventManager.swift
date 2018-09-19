//
//  QiscusEventManager.swift
//  QiscusCore
//
//  Created by Qiscus on 14/08/18.
//

import Foundation

class QiscusEventManager {
    static var shared : QiscusEventManager = QiscusEventManager()
    // MARK: TODO delegate can't be accees from other class, please create setter/function
    var connectionDelegate : QiscusConnectionDelegate? = nil
    var delegate : QiscusCoreDelegate? = nil
    var roomDelegate : QiscusCoreRoomDelegate? = nil
    var room : RoomModel? = nil
    
    func gotMessageStatus(roomID: String, commentUniqueID id: String, status: CommentStatus){
        guard let room = QiscusCore.dataStore.findRoom(byID: String(roomID)) else { return }
        guard let comment = QiscusCore.dataStore.getCommentbyUniqueID(id: id) else { return }

        // only 3 kind status from realtime read, deliverd, and deleted
        var commentStatus : CommentStatus = CommentStatus.read
        switch status {
        case .deleted:
            commentStatus = CommentStatus.deleted
            // delete from local
            QiscusCore.dataStore.deleteComment(uniqueID: comment.uniqId)
            break
        case .read:
            commentStatus = CommentStatus.read
            break
        case .delivered:
            commentStatus = CommentStatus.delivered
            break
        default:
            break
        }
        // update comment
        comment.status = commentStatus
        QiscusCore.dataStore.saveComment(comment)
        if let r = QiscusEventManager.shared.room {
            if r.id == roomID {
                roomDelegate?.didComment(comment: comment, changeStatus: commentStatus)
            }
        }
        // got new comment for other room
        delegate?.onRoom(room, didChangeComment: comment, changeStatus: commentStatus)
        // check comment before, in local then update comment status in this room
        // very tricky, need to review v3
        if let comments = QiscusCore.database.comment.find(roomId: room.id) {
            var _comments = [CommentModel]()
            if commentStatus == .delivered {
                _comments = comments.filter({ ($0.status == CommentStatus.sent)})
            }else if commentStatus == .read {
                _comments = comments.filter({ ($0.status == CommentStatus.delivered) || ($0.status == CommentStatus.sent)})
            }
            for c in _comments {
                c.status = commentStatus
                QiscusCore.dataStore.saveComment(c)
                if let r = QiscusEventManager.shared.room {
                    if r.id == roomID {
                        roomDelegate?.didComment(comment: comment, changeStatus: commentStatus)
                    }
                }
                // got new comment for other room
                delegate?.onRoom(room, didChangeComment: comment, changeStatus: commentStatus)
            }
        }
    }
    
    func gotNewMessage(comment: CommentModel) {
        // check comment already in local, if true should be update comment status(not new comment for this device)
        if !self.checkNewComment(comment) { return }
        // update last comment and increase unread
        QiscusCore.dataStore.saveComment(comment)
        // filter event for room or qiscuscore
        if let r = QiscusEventManager.shared.room {
            if r.id == String(comment.roomId) {
                // publish event new comment inside room
                roomDelegate?.gotNewComment(comment: comment)
                // read comment, assume you read from this room
                QiscusCore.dataStore.readComment(comment)
            }
        }
        // got new comment for other room
        if let room = QiscusCore.dataStore.findRoom(byID: String(comment.roomId)) {
            delegate?.onRoom(room, gotNewComment: comment)
        }
    }
    
    func gotTyping(roomID: String, user: String, value: Bool) {
        // filter event for room or qiscuscore
        if let r = QiscusEventManager.shared.room {
            if r.id == roomID {
                guard let member = QiscusCore.dataStore.getMember(byEmail: user) else { return }
                roomDelegate?.onRoom(thisParticipant: member, isTyping: value)
            }
        }
        // got typing event for other room
        if let room = QiscusCore.dataStore.findRoom(byID: roomID) {
            guard let member = QiscusCore.dataStore.getMember(byEmail: user, inRoom: room) else { return }
            delegate?.onRoom(room, thisParticipant: member, isTyping: value)
        }
    }
    
    func gotEvent(email: String, isOnline: Bool, timestamp time: String) {
        // filter event for room or qiscuscore
        if let r = QiscusEventManager.shared.room {
            guard let member = QiscusCore.dataStore.getMember(byEmail: email, inRoom: r) else { return }
            let date = getDate(timestampUTC: time)
            self.roomDelegate?.onChangeUser(member, onlineStatus: isOnline, whenTime: date)
        }
        guard let user = QiscusCore.dataStore.getMember(byEmail: email) else { return }
        let date = getDate(timestampUTC: time)
        self.delegate?.onChange(user: user, isOnline: isOnline, at: date)
    }
    
    private func getDate(timestampUTC: String) -> Date {
        let date = Date(timeIntervalSince1970: Double(timestampUTC) ?? 0.0)
//        date.tim
//        let df = DateFormatter()
//        df.timeStyle    = DateFormatter.Style.medium
//        df.dateStyle    = DateFormatter.Style.medium
//        df.timeZone     = TimeZone.current
        return date
    }
    
    /// check comment exist in local
    ///
    /// - Parameter data: comment object
    /// - Returns: return true if comment is new or not exist in local
    private func checkNewComment(_ data: CommentModel) -> Bool {
        return !(QiscusCore.dataStore.getCommentbyUniqueID(id: data.uniqId) != nil)
    }
    
//    // MARK: TODO comment status change
//    func onComment(_ comment: CommentModel, statusChange status: CommentStatus) {
//        // filter event for room or qiscuscore
//        if let r = QiscusEventManager.shared.room {
//            if r.id == String(comment.roomId) {
//                self.roomDelegate?.didComment(comment: comment, changeStatus: status)
//            }
//        }
//    }
}
