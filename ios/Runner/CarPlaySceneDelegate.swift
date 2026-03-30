import CarPlay
import Flutter
import MediaPlayer
import UIKit

/// CarPlay scene delegate that manages the CarPlay interface for Tunify.
/// Provides a tab-based UI with Now Playing and Library browsing.
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    
    // MARK: - CPTemplateApplicationSceneDelegate
    
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController,
        to window: CPWindow
    ) {
        self.interfaceController = interfaceController
        
        // Create the tab bar with Library and Now Playing
        let libraryTab = createLibraryTab()
        let nowPlayingTab = createNowPlayingTab()
        
        let tabBarTemplate = CPTabBarTemplate(templates: [libraryTab, nowPlayingTab])
        
        interfaceController.setRootTemplate(tabBarTemplate, animated: true) { _, _ in
            print("CarPlay root template set")
        }
        
        // Listen for playback state updates from Flutter
        setupFlutterMethodChannel()
    }
    
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController,
        from window: CPWindow
    ) {
        self.interfaceController = nil
    }
    
    // MARK: - Tab Creation
    
    private func createLibraryTab() -> CPListTemplate {
        let items: [CPListItem] = [
            CPListItem(
                text: "Recently Played",
                detailText: "Songs you played recently"
            ),
            CPListItem(
                text: "Liked Songs",
                detailText: "Your favorite tracks"
            ),
            CPListItem(
                text: "Downloads",
                detailText: "Offline music"
            ),
            CPListItem(
                text: "Playlists",
                detailText: "Your playlists"
            )
        ]
        
        // Set accessory type for all items
        for item in items {
            item.accessoryType = .disclosureIndicator
        }
        
        let section = CPListSection(items: items)
        let listTemplate = CPListTemplate(
            title: "Library",
            sections: [section]
        )
        
        if let image = UIImage(systemName: "music.note.list") {
            listTemplate.tabImage = image
        }
        listTemplate.tabTitle = "Library"
        listTemplate.delegate = self
        
        return listTemplate
    }
    
    private func createNowPlayingTab() -> CPNowPlayingTemplate {
        let nowPlayingTemplate = CPNowPlayingTemplate.shared
        if let image = UIImage(systemName: "play.circle") {
            nowPlayingTemplate.tabImage = image
        }
        nowPlayingTemplate.tabTitle = "Now Playing"
        return nowPlayingTemplate
    }
    
    // MARK: - Flutter Integration
    
    private func setupFlutterMethodChannel() {
        // The method channel will be set up when the Flutter engine is available
        // This allows CarPlay to request media data from the Flutter side
    }
    
    func playMedia(withId mediaId: String) {
        // Send message to Flutter to play the selected media
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let channel = FlutterMethodChannel(
            name: "com.tunify/carplay",
            binaryMessenger: appDelegate.flutterEngine.binaryMessenger
        )
        
        channel.invokeMethod("playFromMediaId", arguments: mediaId)
    }
    
    func fetchMediaItems(forCategory category: String, completion: @escaping ([CPListItem]) -> Void) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            completion([])
            return
        }
        
        let channel = FlutterMethodChannel(
            name: "com.tunify/carplay",
            binaryMessenger: appDelegate.flutterEngine.binaryMessenger
        )
        
        channel.invokeMethod("getMediaItems", arguments: category) { result in
            guard let items = result as? [[String: Any]] else {
                completion([])
                return
            }
            
            let listItems = items.map { dict -> CPListItem in
                let title = dict["title"] as? String ?? "Unknown"
                let artist = dict["artist"] as? String ?? ""
                let mediaId = dict["id"] as? String ?? ""
                
                let item = CPListItem(text: title, detailText: artist)
                item.handler = { [weak self] _, _ in
                    self?.playMedia(withId: mediaId)
                }
                return item
            }
            
            completion(listItems)
        }
    }
}

// MARK: - CPListTemplateDelegate

extension CarPlaySceneDelegate: CPListTemplateDelegate {
    func listTemplate(
        _ listTemplate: CPListTemplate,
        didSelect item: CPListItem,
        at indexPath: IndexPath
    ) {
        // Map index to media category
        let mediaCategories = [
            "__RECENT__",
            "__LIKED__",
            "__DOWNLOADS__",
            "__PLAYLISTS__"
        ]
        
        guard indexPath.row < mediaCategories.count else { return }
        let mediaId = mediaCategories[indexPath.row]
        
        // If it's playlists, push a playlist browser
        if mediaId == "__PLAYLISTS__" {
            pushPlaylistBrowser()
        } else {
            // Otherwise play from that category
            playMedia(withId: mediaId)
        }
    }
    
    private func pushPlaylistBrowser() {
        let placeholderItem = CPListItem(
            text: "Loading playlists...",
            detailText: nil
        )
        let section = CPListSection(items: [placeholderItem])
        let playlistTemplate = CPListTemplate(title: "Playlists", sections: [section])
        playlistTemplate.delegate = self
        
        interfaceController?.pushTemplate(playlistTemplate, animated: true) { [weak self] _, _ in
            // Fetch playlists from Flutter and update the list
            self?.fetchMediaItems(forCategory: "__PLAYLISTS__") { items in
                let newSection = CPListSection(items: items)
                playlistTemplate.updateSections([newSection])
            }
        }
    }
}

// MARK: - Now Playing Updates

extension CarPlaySceneDelegate {
    func updateNowPlayingInfo(
        title: String,
        artist: String,
        artwork: UIImage?,
        duration: TimeInterval,
        elapsed: TimeInterval,
        isPlaying: Bool
    ) {
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        
        if let artwork = artwork {
            let mediaArtwork = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = mediaArtwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
