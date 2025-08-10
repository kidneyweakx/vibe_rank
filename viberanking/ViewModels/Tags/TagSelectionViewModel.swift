//
//  TagSelectionViewModel.swift
//  viberanking
//
//  Created by Assistant on 2025/08/10.
//

import Foundation

@MainActor
final class TagSelectionViewModel: ObservableObject {
    @Published var allTags: [Tag] = []
    @Published var selectedTagIds: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let tagsAPI = TagsAPI()

    func loadAllTags(category: String? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await tagsAPI.getAllTags(category: category)
            allTags = response.data
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleSelection(for tag: Tag) {
        if selectedTagIds.contains(tag.id) {
            selectedTagIds.remove(tag.id)
        } else {
            selectedTagIds.insert(tag.id)
        }
    }

    func isSelected(_ tag: Tag) -> Bool {
        return selectedTagIds.contains(tag.id)
    }
}


