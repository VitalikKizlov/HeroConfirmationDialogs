//
//  ContentView.swift
//  HeroConfirmationDialogs
//
//  Created by Vitalii Kizlov on 24.11.2025.
//

import SwiftUI

struct AnimatedButtonCornerRadius {
    let source: CGFloat = 30
    let destination: CGFloat = 45
}

struct AnimatedButtonProperties {
    var sourceLocation: CGRect = .zero
    var sourceView: UIImage?
    var hideSource: Bool = false
    var animate: Bool = false
    var showDeleteView: Bool = false
}

struct ContentView: View {
    let cornerRadius: AnimatedButtonCornerRadius = .init()
    @State private var properties: AnimatedButtonProperties = .init()
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        VStack {
            Button {
                let renderer = ImageRenderer(
                    content:
                        text
                        .frame(
                            width: properties.sourceLocation.width,
                            height: properties.sourceLocation.height
                        )
                        .clipShape(.rect(cornerRadius: cornerRadius.source))
                )
                renderer.scale = displayScale
                properties.sourceView = renderer.uiImage

                withoutAnimation {
                    properties.showDeleteView = true
                }
            } label: {
                text
            }
            .onGeometryChange(for: CGRect.self, of: { proxy in
                proxy.frame(in: .global)
            }, action: { oldValue, newValue in
                properties.sourceLocation = newValue
            })
            .buttonStyle(.plain)
            .fullScreenCover(isPresented: $properties.showDeleteView) {
                DeleteAccountView(
                    cornerRadius: cornerRadius,
                    properties: $properties,
                    action: { isUserCanceled in
                        debugPrint("is user canceled: \(isUserCanceled)")
                    }
                )
                .ignoresSafeArea()
                .presentationBackground(.clear)
                .persistentSystemOverlays(.hidden)
            }
        }
        .padding()
    }

    var text: some View {
        Text("Delete account?")
            .foregroundStyle(.white)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding(.vertical)
            .background(.red.gradient)
            .clipShape(.rect(cornerRadius: cornerRadius.source))
            .contentShape(.rect(cornerRadius: cornerRadius.source))
            .opacity(properties.showDeleteView ? 0 : 1)
    }
}

struct DeleteAccountView: View {
    let cornerRadius: AnimatedButtonCornerRadius
    @Binding var properties: AnimatedButtonProperties

    var animate: Bool {
        properties.animate
    }

    var hideSource: Bool {
        properties.hideSource
    }

    var sourceLocation: CGRect {
        properties.sourceLocation
    }

    var animation: Animation {
        //.interpolatingSpring(duration: 0.3)
        .linear(duration: 2)
    }

    var sourceAnimation: Animation {
        //.interpolatingSpring(duration: 0.3)
        .linear(duration: 1)
    }

    var clipShape: AnyShape {
        let radius = properties.animate ? cornerRadius.destination : cornerRadius.source
        return .init(.rect(cornerRadius: radius))
    }

    let action: (_ isUserCanceled: Bool) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(animate ? 0.4 : 0))

            VStack {
                actionButtons()
            }
            .allowsHitTesting(animate)
            .padding(20)
            .compositingGroup()
            .geometryGroup()
            .background(.background, in: clipShape)
            .blur(radius: animate ? 0 : 10)
            .opacity(animate ? 1 : 0)
            .background {
                GeometryReader {
                    let size = $0.size

                    if let sourceView = properties.sourceView {
                        Image(uiImage: sourceView)
                            .resizable()
                            .frame(
                                width: animate ? size.width : sourceLocation.width,
                                height: animate ? size.height : sourceLocation.height
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .blur(radius: hideSource ? 10 : 0)
                            .opacity(hideSource ? 0 : 1)
                    }
                }
            }
            .mask {
                clipShape
                    .frame(
                        width: animate ? nil : sourceLocation.width,
                        height: animate ? nil : sourceLocation.height
                    )
            }
            .padding(.horizontal, 8)
            .visualEffect {
                content,
                proxy in
                content
                    .offset(
                        x: animate ? 0 : sourceLocation.midX - (proxy.size.width / 2),
                        y: animate ? -10 : sourceLocation.midY - (proxy.size.height / 2)
                    )
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: animate ? .bottom : .topLeading
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(animation) {
                properties.animate = true
            }

            Task {
                withAnimation(sourceAnimation) {
                    properties.hideSource = true
                }
            }
        }
    }
}

private extension DeleteAccountView {
    func actionButtons() -> some View {
        HStack(spacing: 8) {
            Button {
                dismiss(false)
            } label: {
                Text("Cancel")
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(.capsule)
            }

            Button {

            } label: {
                Text("Delete")
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    .background(Color.red.gradient)
                    .clipShape(.capsule)
            }
        }
        .fontWeight(.medium)
    }

    func dismiss(_ status: Bool) {
        withAnimation(animation, completionCriteria: .removed) {
            properties.animate = false
        } completion: {
            withoutAnimation {
                properties.sourceView = .none
                properties.showDeleteView = false
            }
        }

        Task {
            withAnimation(sourceAnimation.delay(1)) {
                properties.hideSource = false
            }
        }
    }
}

extension View {
    func withoutAnimation(_ content: @escaping () -> ()) {
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            content()
        }
    }
}

#Preview {
    ContentView()
}
