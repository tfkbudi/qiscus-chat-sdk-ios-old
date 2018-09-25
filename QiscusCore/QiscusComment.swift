//
//  QiscusComment.swift
//  QiscusCore
//
//  Created by Qiscus on 25/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import Foundation

// MARK: Comment Management
extension QiscusCore {
    
    public func sendMessage(roomID id: String, comment: CommentModel, completion: @escaping (CommentModel?, QError?) -> Void) {
        // update comment
        let _comment            = comment
        _comment.roomId         = id
        _comment.status         = .sending
        // check comment type, if not Qiscus Comment set as custom type
        if !_comment.isQiscustype() {
            let _payload    = _comment.payload
            let _type       = _comment.type
            _comment.type = "custom"
            _comment.payload?.removeAll() // clear last payload then recreate
            _comment.payload = ["type" : _type]
            if let payload = _payload {
                _comment.payload!["content"] = payload
            }else {
                _comment.payload!["content"] = ["":""]
            }
            
        }
        // save in local comment pending
        QiscusCore.database.comment.save([_comment])
        // send message to server
        QiscusCore.network.postComment(roomId: comment.roomId, type: comment.type, message: comment.message, payload: comment.payload, extras: nil, uniqueTempId: comment.uniqId) { (result, error) in
            if let commentResult = result {
                // save in local
                commentResult.status = .sent
                QiscusCore.database.comment.save([commentResult])
                comment.onChange(commentResult) // view data binding
                completion(commentResult,nil)
            }else {
                let _failed = comment
                _failed.status  = .failed
                QiscusCore.database.comment.save([_failed])
                comment.onChange(_failed) // view data binding
                completion(nil,QError.init(message: error ?? "Failed to send message"))
            }
        }
    }
    
    
    
    /// Load Comment by room
    ///
    /// - Parameters:
    ///   - id: Room ID
    ///   - limit: by default set 20, min 0 and max 100
    ///   - completion: Response new Qiscus Array of Comment Object and error if exist.
    public func loadComments(roomID id: String, limit: Int? = nil, completion: @escaping ([CommentModel]?, QError?) -> Void) {
        // Load message by default 20
        QiscusCore.network.loadComments(roomId: id, limit: limit) { (comments, error) in
            if let c = comments {
                // save comment in local
                QiscusCore.database.comment.save(c)
            }
            completion(comments,nil)
        }
    }
    
    /// Load More Message in room
    ///
    /// - Parameters:
    ///   - roomID: Room ID
    ///   - lastCommentID: last comment id want to load
    ///   - limit: by default set 20, min 0 and max 100
    ///   - completion: Response new Qiscus Array of Comment Object and error if exist.
    public func loadMore(roomID id: String, lastCommentID commentID: Int, limit: Int? = nil, completion: @escaping ([CommentModel]?, QError?) -> Void) {
        // Load message from server
        QiscusCore.network.loadComments(roomId: id, lastCommentId: commentID, timestamp: nil, after: nil, limit: limit) { (comments, error) in
            if let c = comments {
                // save comment in local
                QiscusCore.database.comment.save(c)
            }
            completion(comments,nil)
        }
    }
    
    /// Delete message by id
    ///
    /// - Parameters:
    ///   - uniqueID: comment unique id
    ///   - type: forMe or ForEveryone
    ///   - completion: Response Comments your deleted
    public func deleteMessage(uniqueIDs id: [String], type: DeleteType, completion: @escaping ([CommentModel]?, QError?) -> Void) {
        QiscusCore.network.deleteComment(commentUniqueId: id, type: type, completion: completion)
    }
    
    /// Delete all message in room
    ///
    /// - Parameters:
    ///   - roomID: array of room id
    ///   - completion: Response error if exist
    public func deleteAllMessage(roomID: [String], completion: @escaping (QError?) -> Void) {
        QiscusCore.network.clearMessage(roomsID: roomID, completion: completion)
    }
    
    /// Search message
    ///
    /// - Parameters:
    ///   - keyword: required, keyword to search
    ///   - roomID: optional, search on specific room by room id
    ///   - lastCommentId: optional, will get comments aafter this id
    public func searchMessage(keyword: String, roomID: String?, lastCommentId: Int?, completion: @escaping ([CommentModel]?, QError?) -> Void) {
        QiscusCore.network.searchMessage(keyword: keyword, roomID: roomID, lastCommentId: lastCommentId, completion: completion)
    }
    
    /// Mark Comment as read, include comment before
    ///
    /// - Parameters:
    ///   - roomId: room id, where comment cooming
    ///   - lastCommentReadId: comment id
    public func updateCommentRead(roomId: String, lastCommentReadId commentID: String) {
        QiscusCore.network.updateCommentStatus(roomId: roomId, lastCommentReadId: commentID, lastCommentReceivedId: nil)
    }
    
    /// Mark Comment as received or deliverd, include comment before
    ///
    /// - Parameters:
    ///   - roomId: room id, where comment cooming
    ///   - lastCommentReceivedId: comment id
    public func updateCommentReceive(roomId: String, lastCommentReceivedId commentID: String) {
        QiscusCore.network.updateCommentStatus(roomId: roomId, lastCommentReadId: nil, lastCommentReceivedId: commentID)
    }
    
    /// Get comment status is read or received
    ///
    /// - Parameters:
    ///   - id: comment id
    ///   - completion: return object comment if exist
    public func readReceiptStatus(commentId id: String, completion: @escaping (CommentModel?, QError?) -> Void) {
        QiscusCore.network.readReceiptStatus(commentId: id) { (comment, message) in
            if let c = comment {
                // save comment in local
                QiscusCore.database.comment.save([c])
            }
            completion(comment,nil)
        }
    }
    
}
