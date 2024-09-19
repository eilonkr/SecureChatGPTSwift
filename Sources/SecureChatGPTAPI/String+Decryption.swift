//
//  String+Decryption.swift
//  
//
//  Created by Eilon Krauthammer on 19/09/2024.
//

import Foundation
import CryptoKit

public extension String {
    /// On base64 encoded encrypted token
    func decrypt(using encodedKey: String) throws -> String {
        let key = SymmetricKey(data: Data(base64Encoded: encodedKey)!)
        let encryptedTokenData = Data(base64Encoded: self)!
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedTokenData)
        let decryptedTokenData = try AES.GCM.open(sealedBox, using: key)
        let decryptedToken = String(data: decryptedTokenData, encoding: .utf8)!
        
        return decryptedToken
    }
}
