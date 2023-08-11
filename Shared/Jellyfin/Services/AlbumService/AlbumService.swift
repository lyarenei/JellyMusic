import Foundation
import Combine

protocol AlbumService: ObservableObject {
    func getAlbums() async throws -> [Album]
    func getAlbum(by albumId: String) async throws -> Album
}

enum AlbumServiceError: Error {
    case notFound
    case invalidResult
}
