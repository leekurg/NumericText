//
//  NumericTransition.swift
//  NumericText
//
//  Created by Илья Аникин on 14.11.2024.
//

import SwiftUI

public extension AnyTransition {
    static func numeric(direction: NumericTransition.Direction, factor: Double? = 20) -> Self {
        AnyTransition.modifier(
            active: NumericTransition(direction: direction, factor: factor, maxFactor: factor),
            identity: NumericTransition(direction: direction, factor: 0, maxFactor: factor)
        )
        .combined(with: .opacity)
    }
}

public struct NumericTransition: ViewModifier, Animatable {
    private var factor: Double
    private var maxFactor: Double
    private let direction: Direction
    private let recoilThreshold: CGFloat

    public init(direction: Direction, factor: Double?, maxFactor: Double?) {
        self.factor = factor ?? 0
        self.maxFactor = maxFactor ?? 0
        self.direction = direction
        self.recoilThreshold = 0.15 * (maxFactor ?? 0)
    }

    public var animatableData: Double {
        get { factor }
        set { factor = newValue }
    }

    public func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .scaleEffect((1.0 - modulatedFactor / (1.5 * maxFactor)), anchor: direction == .up ? .top : .bottom)
            .blur(radius: factor / 3.0)
            .clipped()
            .overlay {
                Text("\(modulatedFactor)")
                    .hidden()
            }
    }

    var modulatedFactor: CGFloat {
        max(factor - recoilThreshold, 0)
    }

    var offset: CGFloat {
        if factor < recoilThreshold {
            direction.sign * factor
        } else {
            -direction.sign * factor + direction.sign * 2 * recoilThreshold
        }
    }
}

public extension NumericTransition {
    enum Direction {
        case up, down

        var sign: Double {
            switch self {
            case .up: return 1
            case .down: return -1
            }
        }
    }
}

fileprivate struct ProxyView: View {
    @State var isToggled = true
    @State var value = 5

    var body: some View {
        VStack {
            HStack {
                Text("\(value)")
                    .font(.system(size: 150))
                    .frame(width: 100, height: 200)
                    .transition(.numeric(direction: value == 5 ? .up : .down, factor: 40))
                    .id(value)

                Text("\(value)")
                    .font(.system(size: 150))
                    .contentTransition(.numericText(value: Double(value)))

//                if isToggled {
//                    Text("8")
//                    .font(.system(size: 150))
//                    .frame(width: 100, height: 200)
//                    .transition(.numeric(direction: .up, factor: 40))
//                }
            }
            .frame(width: 200, height: 200)
            .border(.gray.opacity(0.3))

            HStack {
                Text("\(value)")
                    .font(.system(size: 20))
                    .transition(.numeric(direction: value == 5 ? .up : .down, factor: 5))
                    .id(value)

                Text("\(value)")
                    .font(.system(size: 20))
                    .contentTransition(.numericText(value: Double(value)))
            }
            .frame(width: 100, height: 100)
            .border(.gray.opacity(0.3))

            HStack {
                Toggle("", isOn: $isToggled.animation(.spring))
                    .labelsHidden()

                Button("Toggle") {
                    withAnimation(.spring(duration: 0.7, bounce: 0.2, blendDuration: 0.8)) {
                        value = value == 5 ? 6 : 5
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 100)
        }
    }
}

#Preview {
    ProxyView()
}
