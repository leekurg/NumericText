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
                            .transition(
                                symbol.symbol.first?.isNumber == true
                                    ? numProcessor.transition
                                    : .scale.combined(with: .opacity)
                            )
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
        let nextString: String = if let format {
            "\(value.formatted(format))"
        } else {
            value.formatted()
        }
        
        // initial value change
        guard let prevValue else {
            symbols = nextString.map(SymbolBox.init)
            transition = .numeric(direction: .fromTop)

            self.prevValue = value
            return
        }
        
        // value change
        let nextChars = nextString.map(\.self).reversed()

        self.transition = value > prevValue
            ? .numeric(direction: .fromBottom, factor: transitionFactor)
            : .numeric(direction: .fromTop, factor: transitionFactor)
        
        // Compare
        let prevSymbolsReversed: [SymbolBox] = symbols.reversed()
        
        let newSymbols = nextChars
            .enumerated()
            .map { index, char in
                if
                    index < prevSymbolsReversed.count,
                    prevSymbolsReversed[index].symbol == String(char)
                {
                    return prevSymbolsReversed[index]
                }
                
                return SymbolBox(char)
            }
            .reversed()
        
        
        withAnimation(.numeric) {
            self.symbols = Array(newSymbols)
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

// MARK: - Proxy
struct TextProxyView: View {
    @State var double: Double = 3.14
    
    var body: some View {
        VStack {
            Text("System").font(.title)
            
            OneDigitSystem()
            
            Divider()
            
            Text("NumericText").font(.title)
            
            VStack {
                NumericText(double, format: .number.precision(.fractionLength(2)))
                    .font(.system(size: 40))
                
                controls
            }
            .padding(10)
            .border(.green)
        }
    }
    
    var controls: some View {
        VStack {
            HStack {
                NumControl($double, step: 100)
                NumControl($double, step: 10)
            }
            
            HStack {
                NumControl($double, step: 1)
                NumControl($double, step: 0.1)
                NumControl($double, step: 0.01)
            }
        }
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
                NumControl($oneDigit, step: 100)
                NumControl($oneDigit, step: 10)
                NumControl($oneDigit, step: 1)
            }
        }
        .padding(10)
        .border(.orange)
    }
}

struct NumControl: View {
    @Binding var value: Double
    let step: Double
    let animation: Animation?
    
    init(
        _ value: Binding<Double>,
        step: Double,
        animation: Animation? = .spring
    ) {
        self._value = value
        self.step = step
        self.animation = animation
    }

    var body: some View {
        VStack {
            Text(step.formatted(.number.precision(.fractionLength(2)))).bold()
            
            HStack {
                Button("-") {
                    withAnimation(animation) {
                        value -= step
                    }
                }
                
                Button("+") {
                    withAnimation(animation) {
                        value += step
                    }
                }
            }
        }
        .padding(10)
        .border(.gray.opacity(0.3))
        .buttonStyle(.bordered)
    }
}

#Preview {
    TextProxyView()
}
