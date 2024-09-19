//
//  main.swift
//
//
//  Created by Eilon Krauthammer on 19/09/2024.
//

import Foundation
import CryptoKit

do {
    print("Welcome to SecureChatGPTSwift!\nEnter your OpenAI API key to receive an encrypted key and and encryption key.\n")
    let apiToken = readLine()!
    
    let (key, keyString) = createEncryption()
    let encryptedKey = try encryptAndBase64Encode(apiToken: apiToken, key: key)!
    
    print("\nBase64 encoded encrypted key:")
    print("==============================")
    print(encryptedKey)
    print("==============================\n")
    print("Base64 encoded encryption key:")
    print("==============================")
    print(keyString)
    print("==============================\n")
} catch {
    print("Encryption failed")
}

func createEncryption() -> (SymmetricKey, String) {
    let key = SymmetricKey(size: .bits256)
    let keyString = key.withUnsafeBytes {
        return Data(Array($0)).base64EncodedString()
    }
    
    return (key, keyString)
}

func encryptAndBase64Encode(apiToken: String, key: SymmetricKey) throws -> String? {
    let (key, _) = createEncryption()
    let apiTokenData = Data(apiToken.utf8)
    let sealedBox = try AES.GCM.seal(apiTokenData, using: key)
    if let sealedBoxData = sealedBox.combined {
        return sealedBoxData.base64EncodedString()
    }
    
    return nil
}

func decrypt(encryptedBase64EncodedToken: String, encodedKey: String) throws -> String {
    let key = SymmetricKey(data: Data(base64Encoded: encodedKey)!)
    let encryptedTokenData = Data(base64Encoded: encryptedBase64EncodedToken)!
    let sealedBox = try AES.GCM.SealedBox(combined: encryptedTokenData)
    let decryptedTokenData = try AES.GCM.open(sealedBox, using: key)
    let decryptedToken = String(data: decryptedTokenData, encoding: .utf8)!
    
    return decryptedToken
}
