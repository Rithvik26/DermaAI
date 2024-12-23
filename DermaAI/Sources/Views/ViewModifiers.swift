import SwiftUI

struct iPadAdaptiveModifier: ViewModifier {
    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .frame(
                    width: UIScreen.main.bounds.width * 0.85,
                    height: UIScreen.main.bounds.height * 0.85
                )
                .presentationDetents([PresentationDetent.large])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
        } else {
            content
        }
    }
}

extension View {
    func iPadAdaptive() -> some View {
        modifier(iPadAdaptiveModifier())
    }
    
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// Optional: Add a specific sheet modifier if needed
struct SheetWithModifiers<SheetContent: View>: ViewModifier {
    let isPresented: Binding<Bool>
    let sheetContent: () -> SheetContent
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> SheetContent) {
        self.isPresented = isPresented
        self.sheetContent = content
    }
    
    func body(content: Content) -> some View {
        content.sheet(isPresented: isPresented) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                sheetContent()
                    .frame(
                        width: UIScreen.main.bounds.width * 0.85,
                        height: UIScreen.main.bounds.height * 0.85
                    )
                    .presentationDetents([PresentationDetent.large])
                    .presentationDragIndicator(.visible)
            } else {
                sheetContent()
            }
        }
    }
}

extension View {
    func adaptiveSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(SheetWithModifiers(isPresented: isPresented, content: content))
    }
}
