import Foundation
import CryptoKit

import AuthenticationServices
import GoogleSignIn

func googleSignIn() async throws -> String {
    guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
        throw NSError(domain: "SignInError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find root view controller."])
    }
    
    let nonce = randomNonceString()
    
    let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
    
    guard let idToken = gidSignInResult.user.idToken?.tokenString else {
        throw NSError(domain: "SignInError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not get ID token from Google sign in."])
    }
    
    return idToken
}

func appleSignIn() async throws -> (String, String) {
    let nonce = randomNonceString()
    
    let appleIDProvider = ASAuthorizationAppleIDProvider()
    let request = appleIDProvider.createRequest()
    request.requestedScopes = [.fullName, .email]
    request.nonce = sha256(nonce)
    
    let controller = ASAuthorizationController(authorizationRequests: [request])
    
    return try await withCheckedThrowingContinuation { continuation in
        let delegate = SignInWithAppleDelegator(continuation: continuation, nonce: nonce)
        controller.delegate = delegate
        controller.performRequests()
    }
}

class SignInWithAppleDelegator: NSObject, ASAuthorizationControllerDelegate {
    let continuation: CheckedContinuation<(String, String), Error>
    let nonce: String
    
    init(continuation: CheckedContinuation<(String, String), Error>, nonce: String) {
        self.continuation = continuation
        self.nonce = nonce
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let appleIDToken = appleIDCredential.identityToken else {
                continuation.resume(throwing: NSError(domain: "SignInError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Could not get identity token from Apple sign in."]))
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                continuation.resume(throwing: NSError(domain: "SignInError", code: -4, userInfo: [NSLocalizedDescriptionKey: "Could not convert identity token to string."]))
                return
            }
            
            continuation.resume(returning: (idTokenString, nonce))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
}

private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }
            return random
        }
        
        randoms.forEach { random in
            if remainingLength == 0 {
                return
            }
            
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    
    return result
}

func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
    }.joined()
    
    return hashString
}
