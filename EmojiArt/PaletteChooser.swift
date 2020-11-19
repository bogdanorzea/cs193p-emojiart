//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by Bogdan Orzea on 11/19/20.
//

import SwiftUI

struct PaletteChooser: View {
    @ObservedObject var document: EmojiArtDocument
    @Binding var chosenPalette: String

    var body: some View {
        HStack {
            Stepper(
                onIncrement: {
                    self.chosenPalette = document.palette(after: chosenPalette)
                },
                onDecrement: {
                    self.chosenPalette = document.palette(before: chosenPalette)
                },
                label: { EmptyView() })
            Text(document.paletteNames[chosenPalette] ?? "")
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct PaletteChooser_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChooser(document: EmojiArtDocument(), chosenPalette: Binding.constant(""))
    }
}
