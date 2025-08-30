//
//  TagSelectorSheet.swift
//  viberanking
//
//  Created by Assistant on 2025/08/10.
//

import SwiftUI

struct TagSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel = TagSelectionViewModel()

    let onDone: (Set<String>) -> Void

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else if let error = viewModel.errorMessage {
                        Text(error).foregroundColor(.red)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible(minimum: 60)), GridItem(.flexible(minimum: 60)), GridItem(.flexible(minimum: 60))], spacing: 12) {
                                ForEach(viewModel.allTags, id: \.id) { tag in
                                    TagChipView(tag: tag, isSelected: viewModel.isSelected(tag)) {
                                        viewModel.toggleSelection(for: tag)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .navigationTitle("Choose Tags")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDone(viewModel.selectedTagIds)
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .task { await viewModel.loadAllTags() }
    }
}

struct TagSelectorSheet_Previews: PreviewProvider {
    static var previews: some View {
        TagSelectorSheet { _ in }
    }
}


