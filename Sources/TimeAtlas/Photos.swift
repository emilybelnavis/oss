import Foundation
import Photos

/// Native Photos replacement for the osxphotos lookup. Access is requested only by photo commands.
public final class PhotoLibrary {
    private var assetsByFilename: [String: [(PHAsset, PHAssetResource)]] = [:]
    public init() {}
    public func load() async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else { throw AtlasError("Photos access was denied. Enable access in System Settings → Privacy & Security → Photos.") }
        assetsByFilename.removeAll()
        let assets = PHAsset.fetchAssets(with: nil)
        assets.enumerateObjects { asset, _, _ in
            guard asset.mediaType == .image || asset.mediaType == .video else { return }
            for resource in PHAssetResource.assetResources(for: asset) where resource.type == .photo || resource.type == .video || resource.type == .fullSizePhoto || resource.type == .fullSizeVideo {
                self.assetsByFilename[resource.originalFilename, default: []].append((asset, resource))
            }
        }
    }
    public func getPhotoForMedia(_ media: Media) -> PHAsset? { match(media)?.0 }
    private func match(_ media: Media) -> (PHAsset, PHAssetResource)? {
        guard media.hasFilename, let candidates = assetsByFilename[media.filename], !candidates.isEmpty else { return nil }
        if candidates.count > 1, media.hasModifiedTimestamp, let stamp = timestamp(media.modifiedTimestamp) {
            let target = Date(timeIntervalSince1970: stamp)
            let dated = candidates.compactMap { pair -> ((PHAsset, PHAssetResource), Double)? in
                pair.0.modificationDate.map { (pair, abs($0.timeIntervalSince(target))) }
            }
            if let best = dated.min(by: { $0.1 < $1.1 }), best.1 <= 2 { return best.0 }
        }
        return candidates.first
    }
    /// Exports a matched original into a temporary folder for Preview, downloading from iCloud if needed.
    public func exportPhotoForMedia(_ media: Media, to directory: URL) async throws -> URL? {
        guard let (_, resource) = match(media) else { return nil }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let safeName = URL(fileURLWithPath: resource.originalFilename).lastPathComponent
        let url = directory.appendingPathComponent("\(UUID().uuidString)-\(safeName)")
        let options = PHAssetResourceRequestOptions(); options.isNetworkAccessAllowed = true
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHAssetResourceManager.default().writeData(for: resource, toFile: url, options: options) { error in
                if let error { continuation.resume(throwing: error) } else { continuation.resume() }
            }
        }
        return url
    }
}
