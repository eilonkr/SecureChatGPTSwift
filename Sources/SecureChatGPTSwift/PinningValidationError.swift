//
//  PinningValidationError.swift
//
//
//  Created by Eilon Krauthammer on 19/09/2024.
//

import TrustKit

public enum PinningValidationError {
    case noMatchingPin
    case certificateNotTrusted
    case unknown
    
    init(tskEvaluationResult: TSKTrustEvaluationResult) {
        switch tskEvaluationResult {
        case .failedNoMatchingPin:
            self = .noMatchingPin
        case .failedInvalidCertificateChain:
            self = .certificateNotTrusted
        default:
            self = .unknown
        }
    }
}
