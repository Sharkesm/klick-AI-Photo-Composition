//
//  NGBottomSheetContentContainer.swift
//  Klick
//
//  Created by Manase on 12/12/2025.
//


import SwiftUI

struct NGBottomSheetContentContainer<Content: View>: View {
    let content: Content
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let showDragIndicator: Bool
    let stretchContentToFill: Bool
    let maxWidth: CGFloat?
    let onDragDismiss: (() -> Void)?
    
    enum ContentBound {
        case fill
        case fit
    }
    
    init(
        backgroundColor: Color = .black,
        cornerRadius: CGFloat = 20,
        showDragIndicator: Bool = true,
        stretchContentToFill: Bool = false,
        maxWidth: CGFloat? = nil,
        onDragDismiss: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.showDragIndicator = showDragIndicator
        self.stretchContentToFill = stretchContentToFill
        self.maxWidth = maxWidth
        self.onDragDismiss = onDragDismiss
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 28)
                .padding(.bottom, stretchContentToFill ? 0 : 40)
                .padding(.top, 20)
        }
        .background(backgroundColor)
        .frame(maxWidth: maxWidth ?? .infinity)
        .cornerRadius(cornerRadius)
        .padding(.bottom, 0)
    }
}


// MARK: - Enhanced Bottom Sheet Modifier

struct NGBottomSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let overlayColor: Color
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let showDragIndicator: Bool
    let stretchContentToFill: Bool
    let maxWidth: CGFloat?
    let sheetContent: () -> SheetContent
    
    private var springAnimation: Animation {
        .spring(
            response: 0.35,
            dampingFraction: 0.85,
            blendDuration: 0.5
        )
    }
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    overlayColor
                        .ignoresSafeArea()
                        .transition(.opacity.animation(.easeInOut(duration: 0.35)))
                        .onTapGesture {
                            withAnimation(springAnimation) {
                                isPresented = false
                            }
                        }
                }
            }
            .overlay {
                if isPresented {
                    VStack {
                        Spacer()
                        NGBottomSheetContentContainer(
                            backgroundColor: backgroundColor,
                            cornerRadius: cornerRadius,
                            showDragIndicator: showDragIndicator,
                            stretchContentToFill: stretchContentToFill,
                            maxWidth: maxWidth,
                            onDragDismiss: {
                                withAnimation(springAnimation) {
                                    isPresented = false
                                }
                            }
                        ) {
                            sheetContent()
                        }
                        .transition(
                            .asymmetric(
                                insertion:
                                    .move(edge: .bottom)
                                    .combined(with: .scale(scale: 0.95, anchor: .bottom)),
                                removal:
                                    .move(edge: .bottom)
                            )
                        )
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
                }
            }
            .animation(springAnimation, value: isPresented)
    }
}

// MARK: - Full Screen Bottom Sheet Modifier (like todayBottomSheet)

struct NGFullScreenBottomSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let showDragIndicator: Bool
    let stretchContentToFill: Bool
    let onDismissWithoutAction: (() -> Void)?
    let sheetContent: () -> SheetContent
    
    @State private var currentHostingController: UIHostingController<FullScreenBottomSheetContent<SheetContent>>?
    
    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { presented in
                if presented {
                    presentFullScreenBottomSheet()
                } else {
                    dismissCurrentHostingController()
                }
            }
    }
    
    private func presentFullScreenBottomSheet() {
        guard let tabBarController = findTabBarController() else {
            print("❌ Could not find tab bar controller")
            return
        }
        
        // Create the content view
        let contentView = FullScreenBottomSheetContent(
            isPresented: $isPresented,
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            showDragIndicator: showDragIndicator,
            stretchContentToFill: stretchContentToFill,
            onDismissWithoutAction: onDismissWithoutAction,
            content: sheetContent
        )
        
        // Create a hosting controller
        let hostingController = UIHostingController(rootView: contentView)
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.modalTransitionStyle = .crossDissolve
        hostingController.view.backgroundColor = .clear
        
        // Store reference to current hosting controller
        currentHostingController = hostingController
        
        // Present directly on the tab bar controller
        tabBarController.present(hostingController, animated: true)
    }
    
    private func dismissCurrentHostingController() {
        guard let controller = currentHostingController else { return }
        
        // Clear the reference first
        currentHostingController = nil
        
        // Dismiss the controller
        controller.dismiss(animated: true)
    }
    
    private func findTabBarController() -> UITabBarController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        // Start from root view controller and find tab bar controller
        var currentVC = window.rootViewController
        
        // Check if root is already a tab bar controller
        if let tabBarController = currentVC as? UITabBarController {
            return tabBarController
        }
        
        // Look for tab bar controller in the hierarchy
        while let presentedVC = currentVC?.presentedViewController {
            if let tabBarController = presentedVC as? UITabBarController {
                return tabBarController
            }
            currentVC = presentedVC
        }
        
        // Check if any child view controllers are tab bar controllers
        if let navigationController = window.rootViewController as? UINavigationController {
            for childVC in navigationController.viewControllers {
                if let tabBarController = childVC as? UITabBarController {
                    return tabBarController
                }
            }
        }
        
        // Fallback: search through all view controllers recursively
        return findTabBarControllerRecursively(from: window.rootViewController)
    }
    
    private func findTabBarControllerRecursively(from viewController: UIViewController?) -> UITabBarController? {
        guard let vc = viewController else { return nil }
        
        if let tabBarController = vc as? UITabBarController {
            return tabBarController
        }
        
        // Check presented view controller
        if let presented = vc.presentedViewController {
            if let tabBarController = findTabBarControllerRecursively(from: presented) {
                return tabBarController
            }
        }
        
        // Check child view controllers
        for child in vc.children {
            if let tabBarController = findTabBarControllerRecursively(from: child) {
                return tabBarController
            }
        }
        
        return nil
    }
}

// MARK: - Full Screen Bottom Sheet Content View

private struct FullScreenBottomSheetContent<Content: View>: View {
    @Binding var isPresented: Bool
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let showDragIndicator: Bool
    let stretchContentToFill: Bool
    let onDismissWithoutAction: (() -> Void)?
    let content: () -> Content
    
    @State private var bottomSheetOffset: CGFloat = UIScreen.main.bounds.height
    @State private var backgroundOpacity: Double = 0
    
    private var springAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.8)
    }
    
    var body: some View {
        ZStack {
            // Full screen backdrop
            Color.black.opacity(backgroundOpacity)
                .ignoresSafeArea(.all)
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissBottomSheet()
                }
            
            // Bottom sheet content
            VStack {
                Spacer(minLength: 64)
                
                NGBottomSheetContentContainer(
                    backgroundColor: backgroundColor,
                    cornerRadius: cornerRadius,
                    showDragIndicator: showDragIndicator,
                    stretchContentToFill: stretchContentToFill,
                    onDragDismiss: {
                        dismissBottomSheet()
                    }
                ) {
                    content()
                }
                .offset(y: bottomSheetOffset)
            }
            .ignoresSafeArea(.all)
        }
        .onAppear {
            // Animate in from bottom
            withAnimation(springAnimation) {
                bottomSheetOffset = 0
                backgroundOpacity = 0.6
            }
        }
        .onChange(of: isPresented) { presented in
            if !presented {
                // Animate out to bottom
                withAnimation(springAnimation) {
                    bottomSheetOffset = UIScreen.main.bounds.height
                    backgroundOpacity = 0
                }
            }
        }
    }
    
    private func dismissBottomSheet() {
        // Animate out
        withAnimation(springAnimation) {
            bottomSheetOffset = UIScreen.main.bounds.height
            backgroundOpacity = 0
        }
        
        // Update binding after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isPresented = false
            onDismissWithoutAction?()
        }
    }
}

// MARK: - Convenience Extension

extension View {
    func ngBottomSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        fullScreen: Bool = false,
        overlayColor: Color = Color(.black).opacity(0.6),
        backgroundColor: Color = .black,
        cornerRadius: CGFloat = 20,
        showDragIndicator: Bool = true,
        stretchContentToFill: Bool = false,
        maxWidth: CGFloat? = nil,
        onDismissWithoutAction: (() -> Void)? = nil,
        @ViewBuilder sheetContent: @escaping () -> SheetContent
    ) -> AnyView {
        if fullScreen {
            return AnyView(
                self.modifier(NGFullScreenBottomSheetModifier(
                    isPresented: isPresented,
                    backgroundColor: backgroundColor,
                    cornerRadius: cornerRadius,
                    showDragIndicator: showDragIndicator,
                    stretchContentToFill: stretchContentToFill,
                    onDismissWithoutAction: onDismissWithoutAction,
                    sheetContent: sheetContent
                ))
            )
        } else {
            return AnyView(
                self.modifier(NGBottomSheetModifier(
                    isPresented: isPresented,
                    overlayColor: overlayColor,
                    backgroundColor: backgroundColor,
                    cornerRadius: cornerRadius,
                    showDragIndicator: showDragIndicator,
                    stretchContentToFill: stretchContentToFill,
                    maxWidth: maxWidth,
                    sheetContent: sheetContent
                ))
            )
        }
    }
}
