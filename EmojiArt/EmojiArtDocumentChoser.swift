//
//  EmojiArtDocumentChoser.swift
//  EmojiArt
//
//  Created by Bogdan Orzea on 11/23/20.
//

import SwiftUI

struct EmojiArtDocumentChoser: View {
    @EnvironmentObject var store: EmojiArtDocumentStore
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationView {
            List {
                ForEach(store.documents) { document in
                    NavigationLink( destination: EmojiArtDocumentView(document: document).navigationBarTitle(self.store.name(for: document))) {
                        EditableText(self.store.name(for: document), isEditing: editMode.isEditing) { name in
                            self.store.setName(name, for: document)
                        }
                    }
                }.onDelete { indexSet in
                    indexSet.map { self.store.documents[$0] }.forEach { document in
                        self.store.removeDocument(document)
                    }
                }
            }
            .navigationBarTitle(self.store.name)
            .navigationBarItems(
                leading: Button(action: { store.addDocument() }, label: { Image(systemName: "plus").imageScale(.large) }),
                trailing: EditButton()
            )
            .environment(\.editMode, $editMode)
        }
    }
}

struct EmojiArtDocumentChoser_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentChoser()
    }
}
