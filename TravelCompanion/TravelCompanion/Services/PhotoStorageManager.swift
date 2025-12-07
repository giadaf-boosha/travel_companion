import UIKit

/// Manager singleton per la gestione dello storage delle foto
final class PhotoStorageManager {

    // MARK: - Singleton

    static let shared = PhotoStorageManager()

    private init() {
        createPhotosDirectoryIfNeeded()
    }

    // MARK: - Properties

    private let fileManager = FileManager.default

    /// Directory per lo storage delle foto
    private var photosDirectory: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("TripPhotos", isDirectory: true)
    }

    /// Directory per le thumbnail
    private var thumbnailsDirectory: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("TripThumbnails", isDirectory: true)
    }

    // MARK: - Setup

    /// Crea le directory per le foto se non esistono
    private func createPhotosDirectoryIfNeeded() {
        do {
            if !fileManager.fileExists(atPath: photosDirectory.path) {
                try fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
            }
            if !fileManager.fileExists(atPath: thumbnailsDirectory.path) {
                try fileManager.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
            }
        } catch {
            print("Error creating photos directory: \(error)")
        }
    }

    // MARK: - Save Photo

    /// Dimensione massima per le immagini (50MB)
    private let maxImageSizeBytes: Int64 = 50 * 1024 * 1024

    /// Salva una foto e restituisce il path relativo
    func savePhoto(_ image: UIImage, for tripId: UUID) -> String? {
        // Validazione dimensione immagine stimata
        let estimatedSize = Int64(image.size.width * image.size.height * 4) // RGBA
        guard estimatedSize < maxImageSizeBytes else {
            print("Error: Image too large. Estimated size: \(estimatedSize) bytes, max: \(maxImageSizeBytes) bytes")
            return nil
        }

        let fileName = "\(tripId.uuidString)_\(UUID().uuidString).jpg"
        let fileURL = photosDirectory.appendingPathComponent(fileName)

        guard let imageData = image.jpegData(compressionQuality: Constants.Defaults.photoCompressionQuality) else {
            print("Error: Could not convert image to JPEG data")
            return nil
        }

        // Validazione del dato compresso
        guard imageData.count < Int(maxImageSizeBytes) else {
            print("Error: Compressed image too large. Size: \(imageData.count) bytes")
            return nil
        }

        do {
            try imageData.write(to: fileURL)

            // Genera anche la thumbnail
            if let thumbnail = generateThumbnail(for: image, size: Constants.Defaults.thumbnailSize) {
                saveThumbnail(thumbnail, fileName: fileName)
            }

            return fileName
        } catch {
            print("Error saving photo: \(error)")
            return nil
        }
    }

    /// Salva una foto da Data
    func savePhoto(data: Data, for tripId: UUID) -> String? {
        guard let image = UIImage(data: data) else {
            print("Error: Could not create image from data")
            return nil
        }
        return savePhoto(image, for: tripId)
    }

    // MARK: - Load Photo

    /// Carica una foto dal path
    func loadPhoto(at path: String) -> UIImage? {
        let fileURL = photosDirectory.appendingPathComponent(path)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("Photo file does not exist at path: \(path)")
            return nil
        }

        return UIImage(contentsOfFile: fileURL.path)
    }

    /// Carica la thumbnail di una foto
    func loadThumbnail(at path: String) -> UIImage? {
        let fileURL = thumbnailsDirectory.appendingPathComponent(path)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            // Se la thumbnail non esiste, prova a caricare la foto originale
            return loadPhoto(at: path)
        }

        return UIImage(contentsOfFile: fileURL.path)
    }

    // MARK: - Delete Photo

    /// Elimina una foto
    @discardableResult
    func deletePhoto(at path: String) -> Bool {
        let fileURL = photosDirectory.appendingPathComponent(path)
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent(path)

        var success = true

        // Elimina la foto originale
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                print("Error deleting photo: \(error)")
                success = false
            }
        }

        // Elimina la thumbnail
        if fileManager.fileExists(atPath: thumbnailURL.path) {
            do {
                try fileManager.removeItem(at: thumbnailURL)
            } catch {
                print("Error deleting thumbnail: \(error)")
            }
        }

        return success
    }

    /// Elimina tutte le foto di un viaggio
    func deleteAllPhotos(for tripId: UUID) {
        let prefix = tripId.uuidString

        do {
            let files = try fileManager.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: nil)
            for file in files where file.lastPathComponent.hasPrefix(prefix) {
                try fileManager.removeItem(at: file)
            }

            let thumbnails = try fileManager.contentsOfDirectory(at: thumbnailsDirectory, includingPropertiesForKeys: nil)
            for file in thumbnails where file.lastPathComponent.hasPrefix(prefix) {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("Error deleting photos for trip: \(error)")
        }
    }

    // MARK: - Thumbnail Generation

    /// Genera una thumbnail per un'immagine
    func generateThumbnail(for image: UIImage, size: CGSize) -> UIImage? {
        let aspectRatio = image.size.width / image.size.height
        var thumbnailSize = size

        if aspectRatio > 1 {
            // Immagine orizzontale
            thumbnailSize.height = size.width / aspectRatio
        } else {
            // Immagine verticale
            thumbnailSize.width = size.height * aspectRatio
        }

        UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, 0)
        image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return thumbnail
    }

    /// Salva una thumbnail
    private func saveThumbnail(_ thumbnail: UIImage, fileName: String) {
        let fileURL = thumbnailsDirectory.appendingPathComponent(fileName)

        guard let imageData = thumbnail.jpegData(compressionQuality: 0.8) else {
            return
        }

        do {
            try imageData.write(to: fileURL)
        } catch {
            print("Error saving thumbnail: \(error)")
        }
    }

    // MARK: - Utility Methods

    /// Restituisce il path completo di una foto
    func getFullPath(for relativePath: String) -> URL {
        return photosDirectory.appendingPathComponent(relativePath)
    }

    /// Verifica se una foto esiste
    func photoExists(at path: String) -> Bool {
        let fileURL = photosDirectory.appendingPathComponent(path)
        return fileManager.fileExists(atPath: fileURL.path)
    }

    /// Restituisce la dimensione totale delle foto in bytes
    func getTotalStorageSize() -> Int64 {
        var totalSize: Int64 = 0

        do {
            let files = try fileManager.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: [.fileSizeKey])
            for file in files {
                let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(attributes.fileSize ?? 0)
            }
        } catch {
            print("Error calculating storage size: \(error)")
        }

        return totalSize
    }

    /// Formatta la dimensione dello storage in formato leggibile
    func getFormattedStorageSize() -> String {
        let bytes = getTotalStorageSize()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    /// Restituisce il numero di foto salvate
    func getPhotoCount() -> Int {
        do {
            let files = try fileManager.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: nil)
            return files.count
        } catch {
            return 0
        }
    }

    // MARK: - Cleanup

    /// Elimina foto orfane (non associate a nessun viaggio nel database)
    func cleanupOrphanedPhotos(validPaths: Set<String>) {
        do {
            let files = try fileManager.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: nil)
            for file in files {
                let fileName = file.lastPathComponent
                if !validPaths.contains(fileName) {
                    try fileManager.removeItem(at: file)
                    print("Deleted orphaned photo: \(fileName)")
                }
            }
        } catch {
            print("Error cleaning up orphaned photos: \(error)")
        }
    }

    /// Ricostruisce le thumbnail mancanti
    func regenerateMissingThumbnails() {
        do {
            let files = try fileManager.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: nil)
            for file in files {
                let fileName = file.lastPathComponent
                let thumbnailURL = thumbnailsDirectory.appendingPathComponent(fileName)

                if !fileManager.fileExists(atPath: thumbnailURL.path) {
                    if let image = UIImage(contentsOfFile: file.path),
                       let thumbnail = generateThumbnail(for: image, size: Constants.Defaults.thumbnailSize) {
                        saveThumbnail(thumbnail, fileName: fileName)
                        print("Regenerated thumbnail for: \(fileName)")
                    }
                }
            }
        } catch {
            print("Error regenerating thumbnails: \(error)")
        }
    }
}
