import Foundation
import CoreBluetooth
import Combine

class MyPeripheralCentralManager: NSObject, CBCentralManagerDelegate {
    typealias ConnectCompletionHandler = (Result<Void, Error>) -> Void

    var didUpdatePeripherals: (([CBPeripheral]) -> Void)?
    private(set) var peripherals: [CBPeripheral] = []
    private var centralManager: CBCentralManager!
    private var isWaitingToStartScan: Bool = false
    private var connectingInfos: [UUID: (CBPeripheral, [ConnectCompletionHandler])] = [:]
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func scan() {
        if centralManager.isScanning {
            return
        }
        if centralManager.state != .poweredOn {
            isWaitingToStartScan = true
            return
        }
        executeScan()
    }

    func connect(peripheral: CBPeripheral, completion: @escaping (Result<Void, Error>) -> Void) {
        if peripheral.state == .connected {
            completion(.success(()))
            return
        }
        if let (_, completions) = connectingInfos[peripheral.identifier] {
            connectingInfos[peripheral.identifier] = (peripheral, completions + [completion])
        } else {
            connectingInfos[peripheral.identifier] = (peripheral, [completion])
            centralManager.connect(peripheral, options: nil)
        }
    }

    private func executeScan() {
        isWaitingToStartScan = false
        centralManager.scanForPeripherals(withServices: [CBUUID(string: MyPeripheral.serviceUUID)], options: nil)
    }
    
    // MARK: CBCentralManagerDelegate
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let optIndex = peripherals.firstIndex { $0.identifier == peripheral.identifier }
        if let index = optIndex {
            peripherals.remove(at: index)
            peripherals.insert(peripheral, at: index)
        } else {
            peripherals.append(peripheral)
        }
        didUpdatePeripherals?(peripherals)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn && isWaitingToStartScan {
            executeScan()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let (_, completions) = connectingInfos[peripheral.identifier] {
            for c in completions {
                c(.success(()))
            }
            connectingInfos.removeValue(forKey: peripheral.identifier)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let (_, completions) = connectingInfos[peripheral.identifier] {
            for c in completions {
                c(.failure(error ?? CBError(.unknown)))
            }
            connectingInfos.removeValue(forKey: peripheral.identifier)
        }
    }
}
