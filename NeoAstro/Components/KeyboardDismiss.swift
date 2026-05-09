import SwiftUI
import UIKit

extension View {
    func dismissKeyboardOnTap() -> some View {
        self.background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
        )
    }
}

struct KeyboardDoneToolbar: ViewModifier {
    @FocusState.Binding var focused: Bool

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = false }
                    .font(.body.weight(.semibold))
            }
        }
    }
}

extension View {
    func keyboardDoneToolbar(focused: FocusState<Bool>.Binding) -> some View {
        modifier(KeyboardDoneToolbar(focused: focused))
    }
}
