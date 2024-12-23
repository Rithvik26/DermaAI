//
//  AdaptiveSheet.swift
//  DermaAI
//
//  Created by Rithvik Golthi on 12/23/24.
//


import SwiftUI

struct AdaptiveSheet<T: View>: ViewModifier {
    let content: T
    let detents: Set<PresentationDetent>
    
    init(content: T, detents: Set<PresentationDetent> = [.medium, .large]) {
        self.content = content
        self.detents = detents
    }
    
    func body(content: Content) -> some View {
        content.sheet(isPresented: .constant(true)) {
            content
                .presentationDetents(detents)
                .presentationDragIndicator(.visible)
                .if(UIDevice.current.userInterfaceIdiom == .pad) { view in
                    view.frame(minWidth: 540, minHeight: 620)
                }
        }
    }
}

extension View {
    func adaptiveSheet<T: View>(
        detents: Set<PresentationDetent> = [.medium, .large],
        @ViewBuilder content: () -> T
    ) -> some View {
        self.modifier(AdaptiveSheet(content: content(), detents: detents))
    }
    
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct iPadAdaptiveSize: ViewModifier {
    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .frame(minWidth: 540, maxWidth: .infinity, minHeight: 620, maxHeight: .infinity)
                .frame(width: UIScreen.main.bounds.width * 0.7)
        } else {
            content
        }
    }
}

extension View {
    func iPadAdaptiveSize() -> some View {
        modifier(iPadAdaptiveSize())
    }
}