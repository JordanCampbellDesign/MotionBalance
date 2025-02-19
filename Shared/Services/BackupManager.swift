import Foundation
import Compression

class BackupManager {
    static let shared = BackupManager()
    
    private let fileManager = FileManager.default
    private let backupDirectory: URL
    private let maxBackups = 5
    private let defaults = UserDefaults.standard
    
    // Auto-backup interval (24 hours)
    private let autoBackupInterval: TimeInterval = 24 * 60 * 60
    
    private let encryption = EncryptionService.shared
    
    struct BackupFile {
        let url: URL
        let metadata: BackupMetadata
    }
    
    private init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        backupDirectory = appSupport.appendingPathComponent("MotionBalance/Backups", isDirectory: true)
        try? fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        
        setupAutoBackup()
    }
    
    func createBackup(settings: MotionSettings, description: String? = nil) throws -> URL {
        let metadata = BackupMetadata.create(for: settings, description: description)
        let timestamp = ISO8601DateFormatter().string(from: metadata.timestamp)
        let backupURL = backupDirectory.appendingPathComponent("settings_\(timestamp)")
        
        try fileManager.createDirectory(at: backupURL, withIntermediateDirectories: true)
        
        // Combine settings and metadata
        let backup = BackupData(settings: settings, metadata: metadata)
        let jsonData = try JSONEncoder().encode(backup)
        
        // Compress
        let compressedData = try compress(jsonData)
        
        // Encrypt
        let encryptedData = try encryption.encrypt(compressedData)
        
        // Save
        let backupFile = backupURL.appendingPathComponent("backup.enc")
        try encryptedData.write(to: backupFile)
        
        pruneOldBackups()
        updateLastBackupDate()
        
        return backupURL
    }
    
    func listBackups() -> [BackupFile] {
        guard let directories = try? fileManager.contentsOfDirectory(
            at: backupDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return [] }
        
        return directories.compactMap { directory -> BackupFile? in
            guard let metadata = try? loadMetadata(from: directory) else { return nil }
            return BackupFile(url: directory, metadata: metadata)
        }.sorted { $0.metadata.timestamp > $1.metadata.timestamp }
    }
    
    func restoreFromBackup(at url: URL) throws -> MotionSettings {
        let backupFile = url.appendingPathComponent("backup.enc")
        let encryptedData = try Data(contentsOf: backupFile)
        
        // Decrypt
        let compressedData = try encryption.decrypt(encryptedData)
        
        // Decompress
        let jsonData = try decompress(compressedData)
        
        // Decode
        let backup = try JSONDecoder().decode(BackupData.self, from: jsonData)
        return backup.settings
    }
    
    private func loadMetadata(from directory: URL) throws -> BackupMetadata {
        let metadataURL = directory.appendingPathComponent("metadata.json")
        let data = try Data(contentsOf: metadataURL)
        return try JSONDecoder().decode(BackupMetadata.self, from: data)
    }
    
    private func pruneOldBackups() {
        let backups = listBackups()
        if backups.count > maxBackups {
            backups.suffix(from: maxBackups).forEach { backup in
                try? fileManager.removeItem(at: backup.url)
            }
        }
    }
    
    // Auto-backup support
    private func setupAutoBackup() {
        autoBackupTimer?.invalidate()
        autoBackupTimer = Timer.scheduledTimer(
            withTimeInterval: autoBackupInterval,
            repeats: true
        ) { [weak self] _ in
            self?.performAutoBackupIfNeeded()
        }
    }
    
    private func performAutoBackupIfNeeded() {
        guard shouldPerformAutoBackup() else { return }
        
        // Get current settings from SettingsManager
        if let settings = SettingsManager.shared?.settings {
            try? createBackup(settings: settings, description: "Auto-backup")
        }
    }
    
    private func shouldPerformAutoBackup() -> Bool {
        let lastBackup = defaults.object(forKey: "lastBackupDate") as? Date ?? .distantPast
        return Date().timeIntervalSince(lastBackup) >= autoBackupInterval
    }
    
    private func updateLastBackupDate() {
        defaults.set(Date(), forKey: "lastBackupDate")
    }
    
    private func compress(_ data: Data) throws -> Data {
        let pageSize = 512
        var compressedData = Data()
        
        data.withUnsafeBytes { buffer in
            let outputFilter = try? OutputFilter(.compress, using: .lzfse) { data in
                compressedData.append(data)
            }
            
            var index = 0
            while index < buffer.count {
                let pageCount = min(pageSize, buffer.count - index)
                let subset = buffer.prefix(pageCount)
                try? outputFilter?.write(subset)
                index += pageCount
            }
            try? outputFilter?.finalize()
        }
        
        return compressedData
    }
    
    private func decompress(_ data: Data) throws -> Data {
        let pageSize = 512
        var decompressedData = Data()
        
        data.withUnsafeBytes { buffer in
            let outputFilter = try? OutputFilter(.decompress, using: .lzfse) { data in
                decompressedData.append(data)
            }
            
            var index = 0
            while index < buffer.count {
                let pageCount = min(pageSize, buffer.count - index)
                let subset = buffer.prefix(pageCount)
                try? outputFilter?.write(subset)
                index += pageCount
            }
            try? outputFilter?.finalize()
        }
        
        return decompressedData
    }
}

private struct BackupData: Codable {
    let settings: MotionSettings
    let metadata: BackupMetadata
} 