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
    let transitionFactor: Double
    
    @StateObject private var numProcessor = NumProcessor<F>()

    init(_ double: Double, format: F, transitionFactor: Double = 10) {
        self.double = double
        self.format = format
        self.transitionFactor = transitionFactor
    }
    
    var body: some View {
        Text(double.formatted(format))
            .hidden()
            .overlay {
                HStack(spacing: 0) {
                    ForEach(numProcessor.symbols) { symbol in
                        Text(symbol.symbol)
                            .fixedSize()
                            .transition(numProcessor.transition)
                            .id(symbol.id)
                    }
                }
            }
            .onAppear {
                numProcessor.configure(
                    initialValue: double,
                    format: format,
                    transitionFactor: transitionFactor
                )
            }
            .onChange(of: double) { _, newValue in
                numProcessor.setNewValue(newValue)
            }
    }
}

fileprivate final class NumProcessor<F: FormatStyle>: ObservableObject where F.FormatInput == Double, F.FormatOutput: StringProtocol {
    @Published var symbols: [SymbolBox] = []
    @Published var transition = AnyTransition.identity
    
    var format: F?

    private var transitionFactor: Double = 10
    private var prevValue: Double?
    
    func setNewValue(_ value: Double) {
        let chars = if let format {
            Array(value.formatted(format))
        } else {
            Array("\(value.formatted())")
        }
        
        // initial value change
        guard let prevValue else {
            symbols = chars.map(SymbolBox.init)
            transition = .numeric(direction: .fromTop)

            self.prevValue = value
            return
        }
        
        // value change
        self.transition = value > prevValue
            ? .numeric(direction: .fromBottom, factor: transitionFactor)
            : .numeric(direction: .fromTop, factor: transitionFactor)

        let symbolsCount = symbols.count
        let newSymbols = chars
            .enumerated()
            .map { index, value in
                if
                    index < symbolsCount,
                    symbols[index].symbol == String(value) {
                    return symbols[index]
                }
                
                return SymbolBox(value)
            }
        
        withAnimation(.numeric) {
            self.symbols = newSymbols
        }
        
        self.prevValue = value
        return
    }
    
    func configure(initialValue: Double, format: F?, transitionFactor: Double) {
        self.format = format
        self.transitionFactor = transitionFactor
        
        self.setNewValue(initialValue)
    }
}

fileprivate struct SymbolBox: Identifiable {
    let id: UUID
    let symbol: String
    
    init(_ char: Character) {
        self.id = UUID()
        self.symbol = String(char)
    }
}

struct TextProxyView: View {
    @State var double: Double = 3.14
    
    var body: some View {
        VStack {
            HStack {
                OneDigitSystem()
                
                OneDigitMine()
                
                SimpleTransition()
            }
            
            Divider()
            
            NumericText(double, format: .number.precision(.fractionLength(2)))
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
    @State var transition = AnyTransition.numeric(direction: .fromBottom)

    var body: some View {
        VStack {
            Text(currentValue.formatted(.number.precision(.fractionLength(0))))
                .font(.system(size: 40))
                .transition(transition)
                .id(currentValue)
            
            HStack {
                Button("-") {
                    transition = .numeric(direction: .fromTop)
                    withAnimation(.spring) {
                        currentValue -= 1
                    }
                }
                
                Button("+") {
                    transition = .numeric(direction: .fromBottom)
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

fileprivate struct SimpleTransition: View {
    @State var isShown: Bool = false

    var body: some View {
        VStack {
            if isShown {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 50, height: 50)
                    .transition(.numeric(direction: .fromTop))
            }
            
            Button("Shown") {
                withAnimation(.numeric) {
                    isShown.toggle()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(height: 108)
        .padding(10)
        .border(.green)
    }
}

#Preview {
    TextProxyView()
}
