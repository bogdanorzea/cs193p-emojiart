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
    @State private var showPaletteEditor: Bool = false

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
            Image(systemName: "keyboard").imageScale(.large)
                .onTapGesture {
                    showPaletteEditor = true
                }
                .popover(isPresented: $showPaletteEditor) {
                    PaletteEditor(chosenPalette: $chosenPalette)
                        .environmentObject(document)
                        .frame(minWidth: 300, minHeight: 500)
                }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct PaletteEditor: View {
    @EnvironmentObject var document: EmojiArtDocument

    @Binding var chosenPalette: String
    @State var emojisToAdd: String = ""
    @State var paletteName: String = ""

    var body: some View {
        VStack(spacing: 0) {
            Text("Palette editor").font(.headline).padding()
            Divider()
            Form {
                Section(header: Text("Palette name")) {
                    TextField("Palette name", text: $paletteName, onEditingChanged: { began in
                        if !began {
                            self.document.renamePalette(self.chosenPalette, to: self.paletteName)
                        }
                    })
                    TextField("Add emoji", text: $emojisToAdd, onEditingChanged: { began in
                        if !began {
                            self.chosenPalette = self.document.addEmoji(self.emojisToAdd, toPalette: self.chosenPalette)
                            self.emojisToAdd = ""
                        }
                    })
                }
                Section(header: Text("Remove emoji")) {
                    VStack {
                        ForEach(chosenPalette.map { String($0) }, id: \.self) { emoji in
                            Text(emoji)
                                .onTapGesture {
                                    self.chosenPalette = self.document.removeEmoji(emoji, fromPalette: self.chosenPalette)
                                }
                        }
                    }
                }
            }
        }
        .onAppear {
            self.paletteName = self.document.paletteNames[self.chosenPalette] ?? ""
        }
    }
}
