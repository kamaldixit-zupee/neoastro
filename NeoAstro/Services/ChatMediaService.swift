import Foundation

// MARK: - DTOs

struct ChatPresignedRequest: Encodable {
    let chatId: String
    let astroId: String
    let contentType: String
    let fileName: String
}

struct ChatPresignedResponse: Decodable {
    let presignedUrl: String?
    let fileUrl: String?
}

// MARK: - ChatMediaService

/// Two-step uploads for in-chat media: ask the backend for a presigned URL,
/// then PUT raw bytes to S3, then return the public URL ready to be passed
/// into a `RAISE_QUERY` payload as `mediaUrls[0]`.
enum ChatMediaService {

    /// Voice notes (`messageType=AUDIO`).
    static func uploadVoiceNote(
        data: Data,
        chatId: String,
        astroId: String,
        mimeType: String = "audio/m4a"
    ) async throws -> URL {
        AppLog.info(.chat, "→ uploadVoiceNote bytes=\(data.count) chatId=\(chatId)")
        return try await upload(
            path: "/v1.0/chat/getVoiceNotePreSignedUrl",
            data: data,
            chatId: chatId,
            astroId: astroId,
            mimeType: mimeType,
            fileName: "voice_\(Int(Date().timeIntervalSince1970)).m4a"
        )
    }

    /// Images shared in chat (`messageType=IMAGE`).
    static func uploadImage(
        data: Data,
        chatId: String,
        astroId: String,
        mimeType: String = "image/jpeg"
    ) async throws -> URL {
        AppLog.info(.chat, "→ uploadImage bytes=\(data.count) chatId=\(chatId)")
        return try await upload(
            path: "/v1.0/chat/getImagePreSignedUrl",
            data: data,
            chatId: chatId,
            astroId: astroId,
            mimeType: mimeType,
            fileName: "image_\(Int(Date().timeIntervalSince1970)).jpg"
        )
    }

    private static func upload(
        path: String,
        data: Data,
        chatId: String,
        astroId: String,
        mimeType: String,
        fileName: String
    ) async throws -> URL {
        let presigned = try await APIClient.shared.send(.init(
            path: path,
            method: .POST,
            body: ChatPresignedRequest(
                chatId: chatId,
                astroId: astroId,
                contentType: mimeType,
                fileName: fileName
            )
        ), as: ChatPresignedResponse.self)

        guard
            let presignedString = presigned.presignedUrl,
            let presignedURL = URL(string: presignedString),
            let publicString = presigned.fileUrl,
            let publicURL = URL(string: publicString)
        else {
            throw APIError.businessFailure(message: "Could not get presigned URL")
        }

        var put = URLRequest(url: presignedURL)
        put.httpMethod = "PUT"
        put.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        put.httpBody = data

        let (_, response) = try await URLSession.shared.data(for: put)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw APIError.server(status: http.statusCode, message: "Upload failed")
        }
        AppLog.info(.chat, "← upload ok url=\(publicURL.absoluteString)")
        return publicURL
    }
}
