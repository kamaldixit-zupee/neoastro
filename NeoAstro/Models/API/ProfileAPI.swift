import Foundation

struct UserDetails: Decodable {
    let name: String?
    let email: String?
    let phone: String?
    let dateOfBirth: String?
    let gender: String?
    let city: String?
    let state: String?
    let profilePictureUrl: String?
    let kycStatus: String?
    let zodiacName: String?
}

struct ViewProfileResponse: Decodable {
    let userDetail: UserDetails?
}

struct EditProfilePayload: Encodable {
    var name: String?
    var email: String?
    var dateOfBirth: String?
    var gender: String?
    var city: String?
    var state: String?
    var profilePictureUrl: String?
}

struct DeleteAccountResponse: Decodable {
    let success: Bool?
    let message: String?
}
