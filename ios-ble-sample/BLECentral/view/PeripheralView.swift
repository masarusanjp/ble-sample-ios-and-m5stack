import SwiftUI
import CoreBluetooth
import Combine

struct PeripheralView: View {
    @ObservedObject var viewModel: ViewModel
    var body: some View {
        List {
            Section(header: Text("DEVICE UUID")) {
                Text(viewModel.peripheral.identifier.uuidString).padding()
            }
            Section(header: Text("SERVICE UUID")) {
                if let service = viewModel.service {
                    Text(service.uuid.uuidString).padding()
                } else {
                    Text("unknown").padding()
                }
            }
            Section(header: Text("CHARACTERISTIC UUID")) {
                if let characteristic = viewModel.characteristic {
                    Text(characteristic.uuid.uuidString).padding()
                } else {
                    Text("unknown").padding()
                }
            }
            Section {
                HStack {
                    TextField("input", text: $viewModel.text)
                    Button(viewModel.isWriting ? "sending..." : "send") {
                        viewModel.send()
                    }
                    .disabled(viewModel.isWriting || viewModel.characteristic == nil)
                }
            }
        }
        .onAppear {
            viewModel.prepare()
        }
    }
    
    class ViewModel: ObservableObject {
        let peripheral: CBPeripheral
        let writer: MyPeripheralTextWriter
        @Published var error: String?
        @Published var service: CBService?
        @Published var characteristic: CBCharacteristic?
        @Published var text: String = ""
        @Published var isWriting: Bool = false
        init(peripheral: CBPeripheral) {
            self.peripheral = peripheral
            writer = MyPeripheralTextWriter(peripheral: peripheral)
            writer.didServiceDiscover = { [weak self] service in
                self?.service = service
            }
            writer.didCharacteristicDiscover = { [weak self] c in
                self?.characteristic = c
            }
        }
        
        func send() {
            if text.isEmpty {
                return
            }
            
            isWriting = true
            writer.write(text: text) { [weak self] error in
                self?.isWriting = false
                self?.error = error?.localizedDescription
            }
        }
        func prepare() {
            writer.prepare()
        }
    }
}
