//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Bogdan Orzea on 10/8/20.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    @State var selectedEmojis = Set<EmojiArt.Emoji>()

    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(EmojiArtDocument.pallete.map { String($0) }, id: \.self) { emoji in
                        Text(emoji)
                            .font(Font.system(size: defaultEmojiSize))
                            .onDrag { NSItemProvider(object: emoji as NSString) }
                    }
                }
            }
            .padding(.horizontal)
            GeometryReader { geometry in
                ZStack {
                    Color.white.overlay(
                        OptionalImage(uiImage: self.document.backgroundImage)
                            .scaleEffect(self.zoomScale)
                            .offset(self.panOffset)
                    )
                    .gesture(self.doubleTapToZoom(in: geometry.size))

                    ForEach(self.document.emojis) { emoji in
                        Text(emoji.text)
                            .font(animatableWithSize: emoji.fontSize * self.zoomScale)
                            .overlay(
                                Group {
                                    if selectedEmojis.contains(emoji) {
                                        ZStack(alignment: .trailing) {
                                            RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 4)
                                            GeometryReader { geometry in
                                                Button(action: {
                                                        removeEmoji(emoji)
                                                }, label: {
                                                    ZStack {
                                                        Circle().fill(Color.blue)
                                                        Text("X")
                                                        Image(systemName: "xmark")
                                                            .resizable()
                                                            .frame(width: geometry.size.width/10, height: geometry.size.width/10, alignment: .center)
                                                            .foregroundColor(.white)
                                                    }
                                                })
                                                .frame(width: geometry.size.width/5, height: geometry.size.width/5)
                                                .position(x: geometry.size.width, y: CGFloat(0))
                                            }
                                        }
                                    } else {
                                        EmptyView()
                                    }
                            })
                            .position(self.position(for: emoji, in: geometry.size))
                            .onTapGesture {
                                self.toggleEmojiSelection(emoji)
                            }
                    }
                }
                .clipped()
                .gesture(self.panGesture())
                .gesture(self.zoomGesture())
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
                    var location = geometry.convert(location, from: .global)
                    location = CGPoint(x: location.x - geometry.size.width / 2, y: location.y - geometry.size.height / 2)
                    location = CGPoint(x: location.x - self.panOffset.width, y: location.y - self.panOffset.height)
                    location = CGPoint(x: location.x / self.zoomScale, y: location.y / self.zoomScale)

                    return self.drop(providers: providers, at: location)
                }
            }
        }
    }

    // MARK: - Emoji gestures
    func toggleEmojiSelection(_ emoji: EmojiArt.Emoji) {
        if selectedEmojis.contains(emoji) {
            selectedEmojis.remove(emoji)
        } else {
            selectedEmojis.insert(emoji)
        }
    }

    func removeEmoji(_ emoji: EmojiArt.Emoji) {
        self.document.removeEmoji(emoji)
    }

    // MARK: - Zoom gestures
    @State private var steadyStateZoomScale: CGFloat = 1.0
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }

    private func zoomToFit(_ uiImage: UIImage?, in size: CGSize) {
        if let image = uiImage, image.size.width > 0, image.size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height

            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }

    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, _ in
                // gestureZoomScale is an in-out parameter
                gestureZoomScale = latestGestureScale
            }
            .onEnded { gestureScale in
                self.steadyStateZoomScale *= gestureScale
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
    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero

    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }

    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
            }
            .onEnded { finalDragGestureValue in
                self.steadyStatePanOffset = self.steadyStatePanOffset + (finalDragGestureValue.translation / self.zoomScale)
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
            self.document.setBackgroundUrl(url)
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

struct EmojiArtDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
