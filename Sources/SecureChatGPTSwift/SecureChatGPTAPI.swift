//
//  SecureChatGPTAPI.swift
//
//
//  Created by Eilon Krauthammer on 19/09/2024.
//

import Foundation
import ChatGPTSwift
import OpenAPIURLSession
import TrustKit

public protocol SecureChatGPTAPIDelegate: AnyObject {
    func secureChatGPTAPIDidValidatePinningSuccessfully(_ api: SecureChatGPTAPI)
    func secureChatGPTAPI(_ api: SecureChatGPTAPI, didFailToValidatePinningWithError error: PinningValidationError)
    func secureChatGPTAPIPriorityOpenAIPublicKeyHash(_ api: SecureChatGPTAPI) async -> String?
    func secureChatGPITAPIEncryptedBase64OpenAIAPIToken(_ api: SecureChatGPTAPI) async -> String
    func secureChatGPTAPIEncodedEncrpytionKey(_ api: SecureChatGPTAPI) async -> String
}

public class SecureChatGPTAPI: NSObject {
    private var chatGPTAPI: ChatGPTAPI?
    private var apiKey: String?
    private weak var delegate: SecureChatGPTAPIDelegate?
    
    // MARK: - Lifecycle
    public init(delegate: SecureChatGPTAPIDelegate) {
        self.delegate = delegate
        
        super.init()
    }
    
    // MARK: - Public
    public func getAPI(enforceSSLPinning: Bool = true) async -> ChatGPTAPI {
        if let chatGPTAPI {
            return chatGPTAPI
        }
        
        precondition(delegate != nil, "Delegate cannot be nil")
        
        let encryptedBase64APIKey = await delegate!.secureChatGPITAPIEncryptedBase64OpenAIAPIToken(self)
        let encodedKey = await delegate!.secureChatGPTAPIEncodedEncrpytionKey(self)
        let decryptedAPIKey = try! encryptedBase64APIKey.decrypt(using: encodedKey)
        let api = ChatGPTAPI(apiKey: decryptedAPIKey, clientTransport: createURLSessionTransport())
        self.chatGPTAPI = api
        
        await configureTrustKit(enforcePinning: enforceSSLPinning)
        
        return api
    }
    
    // MARK: - Private
    // Obtain a public key hash: https://www.ssllabs.com/ssltest/index.html
    private func configureTrustKit(enforcePinning: Bool) async {
        let trustKitConfig = [
            kTSKPinnedDomains: [
                "api.openai.com": [
                    kTSKEnforcePinning: enforcePinning,
                    kTSKPublicKeyHashes: [
                        await delegate?.secureChatGPTAPIPriorityOpenAIPublicKeyHash(self),
                        "q75hT9IAbjlW1R15KT3XNu+mzMFmqGZYFNxbjtCibNk=",
                        "yDu9og255NN5GEf+Bwa9rTrqFQ0EydZ0r1FCh9TdAW4="
                    ]
                    .compactMap { $0 }
                ]
            ]
        ]
        
        TrustKit.initSharedInstance(withConfiguration: trustKitConfig)
        TrustKit.sharedInstance().pinningValidatorCallback = { [weak self] result, _, _ in
            guard let self else {
                return
            }
            
            let evaluationResult = result.evaluationResult
            switch evaluationResult {
            case .success:
                delegate?.secureChatGPTAPIDidValidatePinningSuccessfully(self)
            default:
                delegate?.secureChatGPTAPI(self, didFailToValidatePinningWithError: PinningValidationError(tskEvaluationResult: evaluationResult))
            }
        }
    }
    
    private func createURLSessionTransport() -> URLSessionTransport {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let configuration = URLSessionTransport.Configuration(session: session)
        
        return URLSessionTransport(configuration: configuration)
    }
}

// MARK: - URLSessionDelegate
extension SecureChatGPTAPI: URLSessionDelegate {
    public func urlSession(_ session: URLSession,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let pinningValidator = TrustKit.sharedInstance().pinningValidator
        if !pinningValidator.handle(challenge, completionHandler: completionHandler) {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

