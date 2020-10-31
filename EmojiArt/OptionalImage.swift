//
//  OptionalImage.swift
//  EmojiArt
//
//  Created by Bogdan Orzea on 10/29/20.
//

import SwiftUI

struct OptionalImage: View {
    var uiImage: UIImage?

    var body: some View {
        Group {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
            }
        }
    }
}
