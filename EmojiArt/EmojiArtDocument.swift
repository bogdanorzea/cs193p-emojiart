//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Bogdan Orzea on 10/8/20.
//

import SwiftUI
import Combine

class EmojiArtDocument: ObservableObject {
    static let pallete = "🍭🚗🚜⚛️🕐🇪🇺"

    static private let minEmojiSize = 10
    static private let maxEmojiSize  = 100

    static private func normalizeEmojiSize(_ size: Int) -> Int {
        if size < EmojiArtDocument.minEmojiSize {
            return EmojiArtDocument.minEmojiSize
        } else if size > EmojiArtDocument.maxEmojiSize {
            return EmojiArtDocument.maxEmojiSize
        } else {
            return size
        }
    }

    @Published private var emojiArt: EmojiArt
    private var autoSaveCancellable: AnyCancellable?

    init() {
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: EmojiArtDocument.untitled)) ?? EmojiArt()
        autoSaveCancellable = $emojiArt.sink { emojiArt in
            print(emojiArt)
            UserDefaults.standard.set(emojiArt.json, forKey: EmojiArtDocument.untitled)
        }
        fetchBackgroundImageData()
    }

    static private let untitled = "EmojiArtDocument.Untitled"

    @Published private(set) var backgroundImage: UIImage?

    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }

    // MARK: - Intent(s)
    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat) {
        emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
    }

    func moveEmoji(_ emoji: EmojiArt.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }

    func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            let newSize = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrEven))

            emojiArt.emojis[index].size = EmojiArtDocument.normalizeEmojiSize(newSize)
        }
    }

    func removeEmoji(_ emoji: EmojiArt.Emoji) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis.remove(at: index)
        }
    }

    var backgroundUrl: URL? {
        get {
            emojiArt.backgroundURL
        }
        set {
            emojiArt.backgroundURL = newValue?.imageURL
            fetchBackgroundImageData()
        }
    }

    private var fetchImageCancellable: AnyCancellable?
    func fetchBackgroundImageData() {
        backgroundImage = nil
        if let url = self.emojiArt.backgroundURL {
            fetchImageCancellable?.cancel()

            fetchImageCancellable = URLSession.shared.dataTaskPublisher(for: url)
                .map { data, _ in UIImage(data: data) }
                .receive(on: DispatchQueue.main)
                .replaceError(with: nil)
                .assign(to: \.backgroundImage, on: self)
        }
    }
}

extension EmojiArt.Emoji {
    var fontSize: CGFloat { CGFloat(self.size) }
    var location: CGPoint { CGPoint(x: CGFloat(self.x), y: CGFloat(self.y)) }
}
