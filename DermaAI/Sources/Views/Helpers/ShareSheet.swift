//
//  ShareSheet.swift
//  DermaAI
//
//  Created by Rithvik Golthi on 12/23/24.
//


//
//  ShareSheet.swift
//  DermaAI
//
//  Created by Rithvik Golthi on 12/23/24.
//

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // Fix for iPad presentation
        if let popover = controller.popoverPresentationController {
            popover.permittedArrowDirections = []
            popover.sourceView = UIView()
            
            // Set the source rect to the center of the screen
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                popover.sourceRect = CGRect(
                    x: window.frame.midX,
                    y: window.frame.midY,
                    width: 0,
                    height: 0
                )
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
#Preview {
    Text("Share Button")
        .sheet(isPresented: .constant(true)) {
            ShareSheet(items: ["Example text to share"])
        }
}
