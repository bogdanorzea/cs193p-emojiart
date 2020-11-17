//
//  BorderedWithDeleteButton.swift
//  EmojiArt
//
//  Created by Bogdan Orzea on 11/16/20.
//

import SwiftUI

struct BorderedWithDeleteButton: ViewModifier {
    let borderVisible: Bool
    let onDelete: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if borderVisible {
                        ZStack(alignment: .trailing) {
                            RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 4)
                            GeometryReader { geometry in
                                Button(action: onDelete, label: {
                                    ZStack {
                                        Circle().fill(Color.blue)
                                        Image(systemName: "xmark")
                                            .padding(8)
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 16, height: 16, alignment: .center)
                                })
                                .position(x: geometry.size.width, y: CGFloat(0))
                            }
                        }
                    } else {
                        EmptyView()
                    }
                }
            )
    }
}

extension View {
    func borderedWithDeleteButton(borderVisible: Bool, onDelete: @escaping () -> Void) -> some View {
        modifier(BorderedWithDeleteButton(borderVisible: borderVisible, onDelete: onDelete))
    }
}
