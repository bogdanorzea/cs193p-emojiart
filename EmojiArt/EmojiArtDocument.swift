//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Bogdan Orzea on 10/8/20.
//

import SwiftUI

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

    @Published private var emojiArt: EmojiArt {
        didSet {
            UserDefaults.standard.set(emojiArt.json, forKey: EmojiArtDocument.untitled)
        }
    }

    init() {
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: EmojiArtDocument.untitled)) ?? EmojiArt()
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

    func setBackgroundUrl(_ url: URL?) {
        emojiArt.backgroundURL = url?.imageURL
        fetchBackgroundImageData()
    }

    func fetchBackgroundImageData() {
        backgroundImage = nil
        if let url = self.emojiArt.backgroundURL {
            DispatchQueue.global(qos: .userInitiated).async {
                if let imageData = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        if url == self.emojiArt.backgroundURL {
                            self.backgroundImage = UIImage(data: imageData)
                        }
                    }
                }
            }
        }
    }
}

extension EmojiArt.Emoji {
    var fontSize: CGFloat { CGFloat(self.size) }
    var location: CGPoint { CGPoint(x: CGFloat(self.x), y: CGFloat(self.y)) }
}
