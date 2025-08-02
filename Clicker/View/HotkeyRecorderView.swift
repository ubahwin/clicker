import SwiftUI

struct HotkeyRecorderView: View {
    @Environment(\.colorScheme) var colorScheme

    let isFocused: Bool
    let name: String
    let isCancelAvailable: Bool

    let cancel: () -> Void
    let onTap: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .light ? .white : Color(hex: "0x3a3e41"))
                .stroke(isFocused ? .blue : .gray, lineWidth: isFocused ? 2 : 1)

            Text(name)
                .foregroundStyle(.gray)

            if isCancelAvailable {
                HStack {
                    Spacer()

                    Button {
                        cancel()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(colorScheme == .light ? .black : .gray)
                    .padding(.trailing, 8)
                }
            }
        }
        .frame(width: 144, height: 24)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture(perform: onTap)
    }
}
