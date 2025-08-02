import SwiftUI

struct TimeoutView: View {

    @Binding var timeout: Double
    @FocusState var isTimeoutFocused: Bool

    private var timeoutString: Binding<String> {
        Binding {
            String(Int(timeout))
        } set: { newValue in
            guard let number = Int(newValue) else {
                timeout = Constants.defaultTimeoutMs
                return
            }

            switch number {
            case Int.min...10:
                timeout = 10
            case 1000...Int.max:
                timeout = 1000
            default:
                timeout = Double(number)
            }
        }
    }

    var body: some View {
        VStack {
            HStack {
                Text("Задержка ")

                TextField(timeoutString.wrappedValue, text: timeoutString)
                    .frame(minWidth: 32, maxWidth: 54)
                    .multilineTextAlignment(.trailing)
                    .focused($isTimeoutFocused)

                Text("мс")
            }

            Slider(
                value: $timeout,
                in: 10...1000
            ) {
                Text("Slider")
            } minimumValueLabel: {
                Text("10 мс")
            } maximumValueLabel: {
                Text("1000 мс")
            }
            .labelsHidden()
        }
        .padding()
    }
}
