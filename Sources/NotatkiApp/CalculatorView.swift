import SwiftUI

struct CalculatorView: View {
    @State private var display    = "0"
    @State private var expression = ""

    let buttons: [[CalcButton]] = [
        [.clear, .sign, .percent, .divide],
        [.seven, .eight, .nine,   .multiply],
        [.four,  .five,  .six,    .subtract],
        [.one,   .two,   .three,  .add],
        [.zero,  .decimal,        .equal]
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Wyswietlacz
            HStack {
                Spacer()
                Text(display)
                    .font(.system(size: display.count > 9 ? 36 : 52, weight: .light))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Color.black)

            // Przyciski
            VStack(spacing: 12) {
                ForEach(buttons, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { btn in
                            CalcButtonView(button: btn) {
                                tap(btn)
                            }
                        }
                    }
                }
            }
            .padding(12)
            .background(Color.black)
        }
        .background(Color.black)
        .navigationTitle("Kalkulator")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tap(_ btn: CalcButton) {
        switch btn {
        case .clear:
            display    = "0"
            expression = ""
        case .equal:
            let expr = expression + display
            if let result = evaluate(expr) {
                display    = formatResult(result)
                expression = ""
            } else {
                display = "Blad"
            }
        case .add, .subtract, .multiply, .divide:
            expression += display + btn.symbol
            display     = "0"
        case .sign:
            if let val = Double(display) { display = formatResult(-val) }
        case .percent:
            if let val = Double(display) { display = formatResult(val / 100) }
        case .decimal:
            if !display.contains(".") { display += "." }
        default:
            let digit = btn.symbol
            display   = display == "0" ? digit : display + digit
        }
    }

    private func evaluate(_ expr: String) -> Double? {
        let e = NSExpression(format: expr
            .replacingOccurrences(of: "x", with: "*")
            .replacingOccurrences(of: "/", with: "/"))
        return e.expressionValue(with: nil, context: nil) as? Double
    }

    private func formatResult(_ val: Double) -> String {
        val.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(val))
            : String(format: "%.8g", val)
    }
}

enum CalcButton: String, Hashable {
    case zero    = "0", one = "1", two = "2", three = "3", four = "4"
    case five    = "5", six = "6", seven = "7", eight = "8", nine = "9"
    case add     = "+", subtract = "-", multiply = "x", divide = "/"
    case equal   = "=", clear = "AC", sign = "+/-", percent = "%", decimal = "."

    var symbol: String { rawValue }

    var bgColor: Color {
        switch self {
        case .add, .subtract, .multiply, .divide, .equal: return .orange
        case .clear, .sign, .percent:                     return Color(.lightGray)
        default:                                           return Color(.darkGray)
        }
    }
}

struct CalcButtonView: View {
    let button: CalcButton
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(button.symbol)
                .font(.title2.weight(.medium))
                .foregroundColor(.white)
                .frame(width: buttonWidth(button), height: buttonWidth(button))
                .background(button.bgColor)
                .clipShape(Circle())
        }
    }

    private func buttonWidth(_ btn: CalcButton) -> CGFloat {
        let screen = UIScreen.main.bounds.width
        let size   = (screen - 5 * 12) / 4
        return btn == .zero ? size * 2 + 12 : size
    }
}
