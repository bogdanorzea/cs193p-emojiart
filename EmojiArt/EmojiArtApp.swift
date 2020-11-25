//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Bogdan Orzea on 10/8/20.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    let store = EmojiArtDocumentStore(named: "Emoji Art")

    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentChoser().environmentObject(store)
        }
    }
}
