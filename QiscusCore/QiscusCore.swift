//
//  QiscusCore.swift
//  QiscusCore
//
//  Created by Qiscus on 16/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import Foundation

public class QiscusCore: NSObject {
    public static let qiscusCoreVersionNumber:String = "0.3.8"
    class var bundle:Bundle{
        get{
            let podBundle = Bundle(for: QiscusCore.self)
            if let bundleURL = podBundle.url(forResource: "QiscusCore", withExtension: "bundle") {
                return Bundle(url: bundleURL)!
            }else{
                return podBundle
            }
        }
    }
    
    public static let shared    : QiscusCore            = QiscusCore()
    private static var config   : ConfigManager         = ConfigManager.shared
    static var realtime         : RealtimeManager       = RealtimeManager.shared
    static var eventManager     : QiscusEventManager    = QiscusEventManager.shared
    static let fileManager      : QiscusFileManager     = QiscusFileManager.shared
    public static var database  : QiscusDatabaseManager = QiscusDatabaseManager.shared
    static var network          : NetworkManager        = NetworkManager()
    static var worker           : QiscusWorkerManager   = QiscusWorkerManager()
    static var heartBeat        : QiscusHeartBeat?      = nil
    public static var delegate  : QiscusCoreDelegate? {
        get {
            return eventManager.delegate
        }
        set {
            eventManager.delegate = newValue
        }
    }
    public static var enableDebugPrint: Bool = false
    
    /// set your app Qiscus APP ID, always set app ID everytime your app lounch. \nAfter login successculy, no need to setup again
    ///
    /// - Parameter WithAppID: Qiscus SDK App ID
    public class func setup(WithAppID id: String, server: QiscusServer? = nil) {
        config.appID    = id
        if let _server = server {
            config.server = _server
        }else {
            config.server   = QiscusServer(url: URL.init(string: "https://api.qiscus.com")!, realtimeURL: nil, realtimePort: nil)
        }
        
        realtime.setup(appName: id)
        
        if QiscusCore.isLogined{
            // Populate data from db
            QiscusCore.database.loadData()
        }
        
        // Background sync when realtime off
        QiscusCore.heartBeat = QiscusHeartBeat.init(timeInterval: config.syncInterval)
        QiscusCore.heartBeat?.eventHandler = {
            QiscusLogger.debugPrint("Bip")
            QiscusCore.worker.resume()
        }
        QiscusCore.heartBeat?.resume()
    }
    
    
    /// Connect to qiscus server
    ///
    /// - Parameter delegate: qiscuscore delegate to listen the event
    /// - Returns: true if success connect, please make sure you already login before connect.
    public class func connect(delegate: QiscusConnectionDelegate? = nil) -> Bool {
        // check user login
        if let user = getProfile() {
            // setup configuration
//            if let appid = ConfigManager.shared.appID {
//                QiscusCore.setup(WithAppID: appid)
//            }
            // set delegate
            eventManager.connectionDelegate = delegate
            // connect qiscus realtime server
            realtime.connect(username: user.email, password: user.token)
            return true
        }else {
            return false
        }
    }
    
    /// Sync Time interval, by default is 30s. every 30 sec will be sync when realtime server is disconnect
    ///
    /// - Parameter interval: time interval, by default is 30s
    public class func setSync(interval: TimeInterval) {
        config.syncInterval = interval
    }
    
    // MARK: Auth

    /// Get Nonce from SDK server. use when login with JWT
    ///
    /// - Parameter completion: @escaping with Optional(QNonce) and String Optional(error)
    public class func getNonce(onSuccess: @escaping (QNonce) -> Void, onError: @escaping (QError) -> Void) {
        if config.appID == nil {
            fatalError("You need to set App ID")
        }
        network.getNonce(onSuccess: onSuccess, onError: onError)
    }
    
    /// SDK Login or Register with userId and passkey, if new user register you can set username and avatar The handler to be called once the request has finished.
    /// - parameter userID              : must be unique per appid, exm: email, phonenumber, udid.
    /// - userKey                       : user password
    /// - parameter completion          : The code to be executed once the request has finished, also give a user object and error.
    ///
    public class func loginOrRegister(userID: String, userKey: String, username: String? = nil, avatarURL: URL? = nil, extras: [String:Any]? = nil, onSuccess: @escaping (UserModel) -> Void, onError: @escaping (QError) -> Void) {
        if config.appID == nil {
            fatalError("You need to set App ID")
        }
        network.login(email: userID, password: userKey, username: username, avatarUrl: avatarURL?.absoluteString, extras: extras, onSuccess: { (user) in
            // save user in local
            ConfigManager.shared.user = user
            realtime.connect(username: user.email, password: user.token)
            onSuccess(user)
        }) { (error) in
            onError(error)
        }
    }
    
    /// connect with identityToken, after use nonce and JWT
    ///
    /// - Parameters:
    ///   - token: identity token from your server, when you implement Nonce or JWT
    ///   - completion: The code to be executed once the request has finished, also give a user object and error.
    public class func login(withIdentityToken token: String, onSuccess: @escaping (UserModel) -> Void, onError: @escaping (QError) -> Void) {
        if config.appID == nil {
            fatalError("You need to set App ID")
        }
        network.login(identityToken: token, onSuccess: { (user) in
            // save user in local
            ConfigManager.shared.user = user
            onSuccess(user)
        }) { (error) in
            onError(error)
        }
    }
    
    /// Disconnect or logout
    ///
    /// - Parameter completionHandler: The code to be executed once the request has finished, also give a user object and error.
    public static func logout(completion: @escaping (QError?) -> Void) {
        let clientRouter    = Router<APIClient>()
        let roomRouter      = Router<APIRoom>()
        let commentRouter   = Router<APIComment>()
        let userRouter      = Router<APIUser>()
        
        clientRouter.cancel()
        roomRouter.cancel()
        commentRouter.cancel()
        userRouter.cancel()
        
        // clear room and comment
        QiscusCore.database.clear()
        // clear config
        ConfigManager.shared.clearConfig()
        // realtime disconnect
        QiscusCore.realtime.disconnect()
        
        completion(nil)
        
    }
    
    /// check already logined
    ///
    /// - Returns: return true if already login
    public static var isLogined : Bool {
        get {
            if let user = getProfile(){
                if !user.token.isEmpty{
                     return true
                }else{
                    return false
                }
            }else{
                return false
            }
        }
    }
    
    /// Register device token Apns or Pushkit
    ///
    /// - Parameters:
    ///   - deviceToken: device token
    ///   - completion: The code to be executed once the request has finished
    public func register(deviceToken : String, onSuccess: @escaping (Bool) -> Void, onError: @escaping (QError) -> Void) {
        if QiscusCore.isLogined {
            QiscusCore.network.registerDeviceToken(deviceToken: deviceToken, onSuccess: { (success) in
                onSuccess(success)
            }) { (error) in
                onError(error)
            }
        }else{
            onError(QError(message: "please login Qiscus first before register deviceToken"))
        }
    }
    
    /// Remove device token
    ///
    /// - Parameters:
    ///   - deviceToken: device token
    ///   - completion: The code to be executed once the request has finished
    public func remove(deviceToken : String, onSuccess: @escaping (Bool) -> Void, onError: @escaping (QError) -> Void) {
        QiscusCore.network.removeDeviceToken(deviceToken: deviceToken, onSuccess: onSuccess, onError: onError)
    }
    
    /// Sync comment
    ///
    /// - Parameters:
    ///   - lastCommentReceivedId: last comment id, to get id you can call QiscusCore.dataStore.getComments().
    ///   - order: "asc" or "desc" only, lowercase. If other than that, it will assumed to "desc"
    ///   - limit: limit number of comment by default 20
    ///   - completion: return object array of comment and return error if exist
    public func sync(lastCommentReceivedId id: String = "", order: String = "", limit: Int = 20, onSuccess: @escaping ([CommentModel]) -> Void, onError: @escaping (QError) -> Void) {
        if id.isEmpty {
            // get last comment id
            if let comment = QiscusCore.database.comment.all().last {
                QiscusCore.network.sync(lastCommentReceivedId: comment.id, order: order, limit: limit) { (comments, error) in
                    if let message = error {
                        onError(QError(message: message))
                    }else {
                        if let results = comments {
                            // Save comment in local
                            if results.count != 0 {
                                let reversedComments : [CommentModel] = Array(results.reversed())
                                QiscusCore.database.comment.save(reversedComments)
                            }
                            onSuccess(results)
                        }
                    }
                }
            }else {
                onError(QError(message: "call sync without parameter is not work, please try to set last comment id. Maybe comment in DB is empty"))
            }
        }else {
            QiscusCore.network.sync(lastCommentReceivedId: id, order: order, limit: limit) { (comments, error) in
                if let message = error {
                    onError(QError(message: message))
                }else {
                    if let results = comments {
                        // Save comment in local
                        if results.count != 0 {
                            let reversedComments : [CommentModel] = Array(results.reversed())
                            QiscusCore.database.comment.save(reversedComments)
                        }
                        onSuccess(results)
                    }
                }
            }
        }
    }
    
    // MARK: User Profile
    
    /// get qiscus user from local storage
    ///
    /// - Returns: return nil when client not logined, and return object user when already logined
    public static func getProfile() -> UserModel? {
        return ConfigManager.shared.user
    }
    
    /// Get Profile from server
    ///
    /// - Parameter completion: The code to be executed once the request has finished
    public func getProfile(onSuccess: @escaping (UserModel) -> Void, onError: @escaping (QError) -> Void) {
        if ConfigManager.shared.appID != nil {
            if QiscusCore.isLogined {
                QiscusCore.network.getProfile(onSuccess: { (userModel) in
                    ConfigManager.shared.user = userModel
                    onSuccess(userModel)
                }) { (error) in
                    onError(error)
                }
            }else{
                onError(QError(message: "please login Qiscus first before register deviceToken"))
            }
        }else{
            onError(QError(message: "please setupAPPID first before call api"))
        }
        
    }
    
    
    /// Start or stop typing in room,
    ///
    /// - Parameters:
    ///   - value: set true if user start typing, and false when finish
    ///   - roomID: room id where you typing
    ///   - keepTyping: automatic false after n second
    public func isTyping(_ value: Bool, roomID: String, keepTyping: UInt16? = nil) {
        QiscusCore.realtime.isTyping(value, roomID: roomID)
    }
    
    /// Set Online or offline
    ///
    /// - Parameter value: true if user online and false if offline
    public func isOnline(_ value: Bool) {
        QiscusCore.realtime.isOnline(value)
    }
    
    /// Set subscribe rooms
    ///
    /// - Parameter value: RoomModel
    public func subcribeRooms(_ rooms: [RoomModel]) {
        QiscusCore.realtime.subscribeRoomsWithoutOnlineStatus(rooms: rooms)
    }
    
    /// Set subscribe rooms
    ///
    /// - Parameter value: RoomModel
    public func unSubcribeRooms(_ rooms: [RoomModel]) {
        QiscusCore.realtime.unsubscribeRoomsWithoutOnlineStatus(rooms: rooms)
    }
    
    /// Update user profile
    ///
    /// - Parameters:
    ///   - displayName: nick name
    ///   - url: user avatar url
    ///   - completion: The code to be executed once the request has finished
    public func updateProfile(username: String = "", avatarUrl url: URL? = nil, extras: [String : Any]? = nil, onSuccess: @escaping (UserModel) -> Void, onError: @escaping (QError) -> Void) {
        if ConfigManager.shared.appID != nil {
            if QiscusCore.isLogined {
                QiscusCore.network.updateProfile(displayName: username, avatarUrl: url, extras: extras, onSuccess: { (userModel) in
                    ConfigManager.shared.user = userModel
                    onSuccess(userModel)
                }) { (error) in
                    onError(error)
                }
            }else{
                onError(QError(message: "please login Qiscus first before register deviceToken"))
            }
        }else{
            onError(QError(message: "please setupAppID first"))
        }
    }
    
    /// Get total unread count by user
    ///
    /// - Parameter completion: number of unread cout for all room
    public func unreadCount(completion: @escaping (Int, QError?) -> Void) {
        QiscusCore.network.unreadCount(completion: completion)
    }
    
    /// Block Qiscus User
    ///
    /// - Parameters:
    ///   - email: qiscus email user
    ///   - completion: Response object user and error if exist
    public func blockUser(email: String, onSuccess: @escaping (MemberModel) -> Void, onError: @escaping (QError) -> Void) {
        QiscusCore.network.blockUser(email: email, onSuccess: onSuccess, onError: onError)
    }
    
    /// Unblock Qiscus User
    ///
    /// - Parameters:
    ///   - email: qiscus email user
    ///   - completion: Response object user and error if exist
    public func unblockUser(email: String, onSuccess: @escaping (MemberModel) -> Void, onError: @escaping (QError) -> Void) {
        QiscusCore.network.unblockUser(email: email, onSuccess: onSuccess, onError: onError)
    }
    
    /// Get blocked user
    ///
    /// - Parameters:
    ///   - page: page for pagination
    ///   - limit: limit per page
    ///   - completion: Response array of object user and error if exist
    public func listBlocked(page: Int?, limit:Int?, onSuccess: @escaping ([MemberModel]) -> Void, onError: @escaping (QError) -> Void) {
        QiscusCore.network.getBlokedUser(page: page, limit: limit, onSuccess: onSuccess, onError: onError)
    }
    
    /// Upload to qiscus server
    ///
    /// - Parameters:
    ///   - data: data file to upload
    ///   - filename: file Name
    ///   - onSuccess: return object file model when success
    ///   - onError: return QError
    ///   - progress: progress upload
    public func upload(data : Data, filename: String, onSuccess: @escaping (FileModel) -> Void, onError: @escaping (QError) -> Void, progress: @escaping (Double) -> Void ) {
        QiscusCore.network.upload(data: data, filename: filename, onSuccess: onSuccess, onError: onError, progress: progress)
    }
    
    /// Download
    ///
    /// - Parameters:
    ///   - url: url you want to download
    ///   - onSuccess: resturn local url after success download
    ///   - onProgress: progress download
    public func download(url: URL, onSuccess: @escaping (URL) -> Void, onProgress: @escaping (Float) -> Void) {
        QiscusCore.network.download(url: url, onSuccess: onSuccess, onProgress: onProgress)
    }
    
    /// getUsers
    ///
    /// - Parameters:
    ///   - limit: default 20
    ///   - page: default 1
    ///   - querySearch: default nil
    ///   - onSuccess: array of users and metaData
    ///   - onProgress: progress download
    public func getUsers(limit : Int? = 20, page: Int? = 1, querySearch: String? = nil,onSuccess: @escaping ([MemberModel], Meta) -> Void, onError: @escaping (QError) -> Void){
        QiscusCore.network.getUsers(limit: limit, page: page, querySearch: querySearch, onSuccess: onSuccess, onError: onError)
    }
}
