//
//  NumericText.swift
//  NumericText
//
//  Created by Илья Аникин on 16.11.2024.
//

import SwiftUI

struct NumericText<F: FormatStyle>: View where F.FormatInput == Double, F.FormatOutput: StringProtocol {
    let double: Double
    let format: F
    
    @StateObject private var numProcessor = NumProcessor<F>()
    
    var body: some View {
        Text(double.formatted(format))
            .hidden()
            .overlay {
                HStack(spacing: 0) {
                    ForEach(numProcessor.symbols) { symbol in
                        Text(symbol.symbol)
                            .transition(symbol.transition)
                    }
                }
                .animation(.spring, value: double)
            }
            .onAppear {
                numProcessor.setFormat(format)
                numProcessor.setNewValue(double)
            }
            .onChange(of: double) { _, newValue in
                numProcessor.setNewValue(newValue)
            }
    }
}

fileprivate final class NumProcessor<F: FormatStyle>: ObservableObject where F.FormatInput == Double, F.FormatOutput: StringProtocol {
    @Published var symbols: [SymbolBox] = []
    
    var format: F?

    private var prevValue: Double?
    
    func setNewValue(_ value: Double) {
        let chars = format != nil ? Array(value.formatted(format!)) : Array("\(value)")
        
        // initial value change
        guard let prevValue else {
            symbols = chars.map {
                SymbolBox(id: UUID(), symbol: String($0), transition: .scale.combined(with: .opacity))
            }
            self.prevValue = value
            return
        }
        
        // value change
        let transition: AnyTransition = .numeric(direction: value > prevValue ? .up : .down, factor: 5)
        
        withAnimation(.spring) {
            symbols = chars.map {
                SymbolBox(id: UUID(), symbol: String($0), transition: transition)
            }
        }
        
        self.prevValue = value
        return
    }
    
    func setFormat(_ format: F) {
        self.format = format
    }
}

fileprivate struct SymbolBox: Identifiable {
    let id: UUID
    let symbol: String
    let transition: AnyTransition
}

fileprivate struct ProxyView: View {
    @State var double: Double = 3.14
    
    var body: some View {
        VStack {
            HStack {
                OneDigitSystem()
                
                OneDigitMine()
            }
            
            Divider()
            
            NumericText(double: double, format: .number.precision(.fractionLength(0)))
                .font(.system(size: 40))
            
            controls
        }
    }
    
    var controls: some View {
        HStack {
            VStack {
                Text("1.00").bold()
                
                HStack {
                    Button("-") {
                        double -= 1.00
                    }
                    
                    Button("+") {
                        double += 1.00
                    }
                }
            }
            .padding(10)
            .border(.gray.opacity(0.3))
            
            VStack {
                Text("0.10").bold()
                
                HStack {
                    Button("-") {
                        double -= 0.10
                    }
                    
                    Button("+") {
                        double += 0.10
                    }
                }
            }
            .padding(10)
            .border(.gray.opacity(0.3))
            
            VStack {
                Text("0.01").bold()
                
                HStack {
                    Button("-") {
                        double -= 0.01
                    }
                    
                    Button("+") {
                        double += 0.01
                    }
                }
            }
            .padding(10)
            .border(.gray.opacity(0.3))
        }
        .buttonStyle(.bordered)
    }
}

fileprivate struct OneDigitSystem: View {
    @State var oneDigit: Double = 1.0

    var body: some View {
        VStack {
            Text(oneDigit.formatted(.number.precision(.fractionLength(0))))
                .contentTransition(.numericText(value: oneDigit))
                .font(.system(size: 40))
            
            HStack {
                Button("-") {
                    withAnimation(.spring) {
                        oneDigit -= 1
                    }
                }
                
                Button("+") {
                    withAnimation(.spring) {
                        oneDigit += 1
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(10)
        .border(.orange)
    }
}

fileprivate struct OneDigitMine: View {
    @State var prevValue: Double = 1.0
    @State var currentValue: Double = 1.0
    @State var transition = AnyTransition.asymmetric(
        insertion: .numeric(direction: .up),
        removal: .numeric(direction: .down)
    )

    var body: some View {
        VStack {
            Text(currentValue.formatted(.number.precision(.fractionLength(0))))
                .font(.system(size: 40))
                .transition(transition)
                .id(currentValue)
            
            HStack {
                Button("-") {
                    transition = .asymmetric(
                        insertion: .numeric(direction: .down),
                        removal: .numeric(direction: .up)
                    )
                    withAnimation(.spring) {
                        currentValue -= 1
                    }
                }
                
                Button("+") {
                    transition = .asymmetric(
                        insertion: .numeric(direction: .up),
                        removal: .numeric(direction: .down)
                    )
                    withAnimation(.spring) {
                        currentValue += 1
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(10)
        .border(.red)
    }
}

#Preview {
    ProxyView()
}
