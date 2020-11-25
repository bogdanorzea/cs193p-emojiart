//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Bogdan Orzea on 10/8/20.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    @State private var chosenPalette: String = ""
    @State var selectedEmojis = Set<EmojiArt.Emoji>()

    var body: some View {
        VStack {
            HStack {
                PaletteChooser(document: document, chosenPalette: $chosenPalette)
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(chosenPalette.map { String($0) }, id: \.self) { emoji in
                            Text(emoji)
                                .font(Font.system(size: defaultEmojiSize))
                                .onDrag { NSItemProvider(object: emoji as NSString) }
                        }
                    }
                }.onAppear { self.chosenPalette = self.document.defaultPalette }
            }
            GeometryReader { geometry in
                ZStack {
                    Color.white.overlay(
                        OptionalImage(uiImage: self.document.backgroundImage)
                            .scaleEffect(self.zoomScale)
                            .offset(self.panOffset)
                    )
                    .gesture(self.doubleTapToZoom(in: geometry.size))

                    if self.isLoading {
                        Image(systemName: "hourglass").imageScale(.large).spinning()
                    } else {
                        ForEach(self.document.emojis) { emoji in
                            Text(emoji.text)
                                .font(animatableWithSize: size(for: emoji))
                                .borderedWithDeleteButton(borderVisible: selectedEmojis.contains(matching: emoji)) {
                                    self.removeEmoji(emoji)
                                }
                                .position(self.position(for: emoji, in: geometry.size))
                                .onTapGesture { self.toggleEmojiSelection(emoji) }
                                .gesture(self.onDragEmoji(emoji))
                        }
                    }
                }
                .clipped()
                .gesture(self.panGesture())
                .gesture(self.zoomGesture())
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onReceive(document.$backgroundImage) { image in
                    self.zoomToFit(image, in: geometry.size)
                }
                .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
                    var location = geometry.convert(location, from: .global)
                    location = CGPoint(x: location.x - geometry.size.width / 2, y: location.y - geometry.size.height / 2)
                    location = CGPoint(x: location.x - self.panOffset.width, y: location.y - self.panOffset.height)
                    location = CGPoint(x: location.x / self.zoomScale, y: location.y / self.zoomScale)

                    return self.drop(providers: providers, at: location)
                }
                .navigationBarItems(trailing: Button(action: {
                    if let url = UIPasteboard.general.url, url != document.backgroundUrl {
                        self.document.backgroundUrl = url
                    } else {
                        self.explainBackgroundPaste = false
                    }
                }, label: {
                    Image(systemName: "doc.on.clipboard").imageScale(.large)
                        .alert(isPresented: $explainBackgroundPaste) {
                            Alert(
                                title: Text("Paste background image"),
                                message: Text("Copy the url of an image to the clipboard and touch this button to make it the background of this document"),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                }))
            }
            .zIndex(-1)
        }.alert(isPresented: $confirmBackgroundPaste) {
            Alert(
                title: Text("Paste background image"),
                message: Text("Replace your background image with \(UIPasteboard.general.url?.absoluteString ?? "nothing")"),
                primaryButton: .default(Text("OK")) {
                    self.document.backgroundUrl = UIPasteboard.general.url
                },
                secondaryButton: .cancel()
            )
        }
    }

    @State private var explainBackgroundPaste: Bool = false
    @State private var confirmBackgroundPaste: Bool = false

    private var isLoading: Bool {
        document.backgroundUrl != nil && document.backgroundImage == nil
    }

    // MARK: - Emoji gestures
    func toggleEmojiSelection(_ emoji: EmojiArt.Emoji) {
        self.selectedEmojis.toggleMatching(emoji)
    }

    func removeEmoji(_ emoji: EmojiArt.Emoji) {
        self.document.removeEmoji(emoji)
    }

    @GestureState private var gestureEmojiPanOffset: CGSize = .zero
    func onDragEmoji(_ emoji: EmojiArt.Emoji) -> some Gesture {
        DragGesture()
            .updating($gestureEmojiPanOffset) { latestDragGestureValue, gestureEmojiPanOffset, _ in
                gestureEmojiPanOffset = latestDragGestureValue.translation / self.zoomScale
            }
            .onEnded { finalDragGestureValue in
                let offset = finalDragGestureValue.translation / self.zoomScale

                if selectedEmojis.contains(matching: emoji) {
                    self.moveSelectedEmojis(by: offset)
                } else {
                    self.document.moveEmoji(emoji, by: offset)
                }
            }
    }

    private func moveSelectedEmojis(by offset: CGSize) {
        selectedEmojis.forEach { emoji in
            self.document.moveEmoji(emoji, by: offset)
        }
    }

    // MARK: - Zoom gestures
    @GestureState private var gestureZoomScale: CGFloat = 1.0

    private var zoomScale: CGFloat {
        if selectedEmojis.count == 0 {
            return document.steadyStateZoomScale * gestureZoomScale
        }

        return document.steadyStateZoomScale
    }

    private func size(for emoji: EmojiArt.Emoji) -> CGFloat {
        if selectedEmojis.contains(emoji) {
            return emoji.fontSize * document.steadyStateZoomScale * gestureZoomScale
        }

        return emoji.fontSize * zoomScale
    }

    private func zoomToFit(_ uiImage: UIImage?, in size: CGSize) {
        if let image = uiImage, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height

            document.steadyStatePanOffset = .zero
            document.steadyStateZoomScale = min(hZoom, vZoom)
        }
    }

    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, _ in
                gestureZoomScale = latestGestureScale
            }
            .onEnded { gestureScale in
                if selectedEmojis.count == 0 {
                    document.steadyStateZoomScale *= gestureScale
                } else {
                    scaleSelectedEmojis(by: gestureScale)
                }
            }
    }

    private func scaleSelectedEmojis(by scale: CGFloat) {
        selectedEmojis.forEach { emoji in
            self.document.scaleEmoji(emoji, by: scale)
        }
    }

    // MARK: - Double tap gesture
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    self.zoomToFit(self.document.backgroundImage, in: size)
                }
            }
            .exclusively(before: TapGesture(count: 1).onEnded {
                selectedEmojis.removeAll()
            })
    }

    // MARK: - Pan gestures
    @GestureState private var gesturePanOffset: CGSize = .zero

    private var panOffset: CGSize {
        (document.steadyStatePanOffset + gesturePanOffset) * zoomScale
    }

    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
            }
            .onEnded { finalDragGestureValue in
                document.steadyStatePanOffset = document.steadyStatePanOffset + (finalDragGestureValue.translation / self.zoomScale)
            }
    }

    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width / 2, y: location.y + size.height / 2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)

        return location
    }

    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            print("dropped: \(url)")
            self.document.backgroundUrl = url
        }

        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }

        return found
    }

    private let defaultEmojiSize: CGFloat = 40
}

extension Set where Element: Identifiable {
    mutating func toggleMatching(_ item: Element) {
        if let index = self.firstIndex(matching: item) {
            self.remove(at: index)
        } else {
            self.insert(item)
        }
    }
}

struct EmojiArtDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
