import SwiftUI
import CoreBluetooth
import Combine

struct PeripheralListView: View {
    @ObservedObject var viewModel = ViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isConnecting {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("connecting")
                            Spacer()
                        }
                        Spacer()
                    }
                }
                List {
                    if viewModel.peripherals.isEmpty {
                        HStack {
                            Text("no peripherals")
                        }.padding()
                    }
                    ForEach(viewModel.peripherals, id: \.identifier) { peripheral in
                        VStack(alignment: .leading, spacing: 0) {
                            Button { viewModel.connect(peripheral: peripheral) } label: {
                                HStack {
                                    Text(peripheral.name ?? "N/A")
                                }.padding()
                            }
                            NavigationLink(
                                destination: PeripheralView(viewModel: .init(peripheral: peripheral)),
                                isActive: viewModel.bindingForPeripheralViewLink(peripheral: peripheral),
                                label: {
                                    EmptyView()
                                })
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.startScan()
            viewModel.connecteSucceededUUID = nil
        }
    }

    class ViewModel: ObservableObject {
        @Published var peripherals: [CBPeripheral] = []
        @Published var isConnecting: Bool = false
        @Published var connecteSucceededUUID: UUID?
        @Published var connectedUUIDs: Set<UUID> = Set([])
        
        private let ble = MyPeripheralCentralManager()
        
        init() {
            ble.didUpdatePeripherals = { [weak self] peripherals in
                self?.peripherals = peripherals
            }
        }
        
        func startScan() {
            ble.scan()
        }
    
        func connect(peripheral: CBPeripheral) {
            isConnecting = true
            ble.connect(peripheral: peripheral) { [weak self] result in
                self?.isConnecting = false
                switch result {
                case .failure:
                    break
                case .success:
                    self?.connectedUUIDs.insert(peripheral.identifier)
                }
            }
        }
        
        func bindingForPeripheralViewLink(peripheral: CBPeripheral) -> Binding<Bool> {
            Binding<Bool> { [weak self] in
                self?.connectedUUIDs.contains(peripheral.identifier) ?? false
            } set: { [weak self] newValue in
                if newValue {
                    self?.connectedUUIDs.insert(peripheral.identifier)
                } else {
                    self?.connectedUUIDs.remove(peripheral.identifier)
                }
            }
        }
    }
}

struct PeripheralListView_Previews: PreviewProvider {
    static var previews: some View {
        PeripheralListView()
    }
}
