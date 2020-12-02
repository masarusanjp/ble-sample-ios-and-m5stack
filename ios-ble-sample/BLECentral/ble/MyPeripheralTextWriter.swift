import Foundation
import CoreBluetooth
import Combine

class MyPeripheralTextWriter: NSObject, CBPeripheralDelegate {
    var writeCompletion: ((Error?) -> Void)?
    private(set) var isWriting: Bool = false
    private var writingText: String?
    let peripheral: CBPeripheral
    private var service: CBService?
    private var characteristic: CBCharacteristic?
    var didServiceDiscover: ((CBService) -> Void)?
    var didCharacteristicDiscover: ((CBCharacteristic) -> Void)?
    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()
        peripheral.delegate = self
    }
    
    func prepare() {
        discoverService()
    }

    func write(text: String, completion: @escaping (Error?) -> Void) {
        guard let characteristic = characteristic else {
            completion(nil)
            return
        }
        if isWriting {
            completion(nil)
        }
        isWriting = true
        writingText = text
        writeCompletion = completion
        writeText(text: text, characteristic: characteristic)
    }
    
    private func discoverService() {
        peripheral.discoverServices([CBUUID(string: MyPeripheral.serviceUUID)])
    }
    
    private func discoverCharacteristic(service: CBService) {
        peripheral.discoverCharacteristics([CBUUID(string: MyPeripheral.characteristicUUID)], for: service)
    }
    
    private func finishWriting(error: Error?) {
        isWriting = false
        writeCompletion?(error)
        writeCompletion = nil
        writingText = nil
    }
    
    private func writeText(text: String, characteristic: CBCharacteristic) {
        guard let data = text.data(using: .utf8) else {
            finishWriting(error: nil)
            return
        }
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        service = peripheral.services?.first { $0.uuid == CBUUID(string: MyPeripheral.serviceUUID) }
        if let service = service {
            discoverCharacteristic(service: service)
            didServiceDiscover?(service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        characteristic = service.characteristics?.first { $0.uuid == CBUUID(string: MyPeripheral.characteristicUUID) }
        if let characteristic = characteristic {
            didCharacteristicDiscover?(characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        finishWriting(error: error)
    }
}
