# SecureChatGPTSwift

A ChatGPT API Swift package based on [ChatGPTSwift](https://github.com/alfianlosari/ChatGPTSwift) with SSL pinning using [TrustKit](https://github.com/datatheorem/TrustKit) and API key symmetric encryption.

## API Key Encryption

You can use SecureChatGPTSwifts `KeyEncryption` executable as a command line tool to encrypt your OpenAI API key, which will be decoded by `SecureChatGPTAPI` when initialized. 

### Steps:

1. Select the **KeyEncryption** executable
2. Choose **My Mac** as the platform
3. Enter your OpenAI API key to the command line
4. You will receive two Base64-encoded outputs:
   - Encrypted API key
   - Encryption key
