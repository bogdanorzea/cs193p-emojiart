//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Bogdan Orzea on 10/8/20.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    var body: some Scene {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let store = EmojiArtDocumentStore(directory: url)
//        let store = EmojiArtDocumentStore(named: "Emoji Art")

        WindowGroup {
            EmojiArtDocumentChoser().environmentObject(store)
        }
    }
}
