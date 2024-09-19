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
    func secureChatGPTAPIPriorityOpenAIPublicKeyHash(_ api: SecureChatGPTAPI) -> String?
    func secureChatGPITAPIPollEncryptedBase64OpenAIAPIToken(_ api: SecureChatGPTAPI) -> String
    func secureChatGPTAPIEncodedEncrpytionKey(_ api: SecureChatGPTAPI) -> String
}

public class SecureChatGPTAPI: NSObject {
    private let pollingSeconds: TimeInterval
    private var chatGPTAPI: ChatGPTAPI?
    private var apiKey: String?
    private weak var delegate: SecureChatGPTAPIDelegate?
    
    // MARK: - Lifecycle
    init(pollingSeconds: TimeInterval = 2, delegate: SecureChatGPTAPIDelegate) {
        self.pollingSeconds = pollingSeconds
        self.delegate = delegate
        
        super.init()
    }
    
    // MARK: - Public
    func getAPI(enforceSSLPinning: Bool = true) async -> ChatGPTAPI {
        if let chatGPTAPI {
            return chatGPTAPI
        }
        
        precondition(delegate != nil, "Delegate cannot be nil")
        
        let encryptedBase64APIKey = delegate!.secureChatGPITAPIPollEncryptedBase64OpenAIAPIToken(self)
        guard encryptedBase64APIKey.isEmpty == false else {
            try? await Task.sleep(for: .seconds(pollingSeconds))
            return await getAPI(enforceSSLPinning: enforceSSLPinning)
        }
        
        let encodedKey = delegate!.secureChatGPTAPIEncodedEncrpytionKey(self)
        let decryptedAPIKey = try! encryptedBase64APIKey.decrypt(using: encodedKey)
        let api = ChatGPTAPI(apiKey: decryptedAPIKey, clientTransport: createURLSessionTransport())
        self.chatGPTAPI = api
        
        configureTrustKit(enforcePinning: enforceSSLPinning)
        
        return api
    }
    
    // MARK: - Private
    private func configureTrustKit(enforcePinning: Bool) {
        let trustKitConfig = [
            kTSKPinnedDomains: [
                "api.openai.com": [
                    kTSKEnforcePinning: enforcePinning,
                    kTSKPublicKeyHashes: [
                        delegate?.secureChatGPTAPIPriorityOpenAIPublicKeyHash(self),
                        "FezOCC3qZFzBmD5xRKtDoLgK445Kr0DeJBj2TWVvR9M=",
                        "7z2T5ye+f19+rJoSqmL4lqM2bFirsxLVkLhXlo4mQ0k="
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

