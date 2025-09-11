import SwiftUI

struct DeleteAccountButton: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @State private var showingConfirm = false
    @State private var isDeleting = false
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Button {
                showingConfirm = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                    Text("Delete Account")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.6))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.25), lineWidth: 1)
                        )
                )
            }
            .disabled(isDeleting)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
        .alert("Delete Account", isPresented: $showingConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { performDelete() }
        } message: {
            Text("This will permanently delete your account and all related data. This action cannot be undone.")
        }
    }

    private func performDelete() {
        isDeleting = true
        errorMessage = nil
        Task {
            do {
                try await UserAPI().deleteAccount()
                await MainActor.run {
                    isDeleting = false
                    authViewModel.signOut()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    DeleteAccountButton()
        .environmentObject(AuthenticationViewModel())
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}


