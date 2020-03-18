//
//  File.swift
//  
//
//  Created by Maxime Britto on 18/03/2020.
//

import Fluent
import Vapor

struct UserController {
    func create(req: Request) throws -> EventLoopFuture<User> {
        let receivedData = try req.content.decode(User.Create.self)
        let user = try User(name: receivedData.name,
                            email: receivedData.email,
                            passwordHash: Bcrypt.hash(receivedData.password))
        return user.save(on: req.db).transform(to: user)
    }
    
    func login(req: Request) throws -> EventLoopFuture<UserToken> {
        let user = try req.auth.require(User.self)
        let token = try user.generateToken()
        return token.save(on: req.db).transform(to: token)
    }
}

extension User {
    struct Create : Content {
        var name: String
        var email: String
        var password: String
    }
}

extension User : ModelUser {
    static var usernameKey = \User.$email
    static var passwordHashKey = \User.$passwordHash
    
    func verify(password: String) throws -> Bool {
        return try Bcrypt.verify(password, created: self.passwordHash)
    }
    
    func generateToken() throws -> UserToken {
        return try UserToken(value: [UInt8].random(count: 16).base64,
                         userID: self.requireID())
    }
}

