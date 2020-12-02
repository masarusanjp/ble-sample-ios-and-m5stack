#include <M5Stack.h>
#include <BLEServer.h>
#include <BLEDevice.h>

static const char *serviceUUID = "ef33ee86-37f6-42d0-b454-5b81ef7a14ca";
static const char *characteristicUUID = "6c9aafbe-9725-4550-a7ff-e39aeb8af21b";

class ServerCallbacks: public BLEServerCallbacks {
public:
	virtual void onConnect(BLEServer* pServer) {
    Serial.println("connected");
  }
	virtual void onConnect(BLEServer* pServer, esp_ble_gatts_cb_param_t *param) {
    onConnect(pServer);
  }
	virtual void onDisconnect(BLEServer* pServer) {
    Serial.println("disconnected");
  }
};

class CharacteristicCallbacks: public BLECharacteristicCallbacks {
public:
	virtual void onRead(BLECharacteristic* pCharacteristic) {
    Serial.println("read");
  }
	virtual void onWrite(BLECharacteristic* pCharacteristic) {
    Serial.println("write");
    std::string value = pCharacteristic->getValue();
    M5.Lcd.setCursor(10, 10);
    M5.Lcd.printf(value.c_str());
  }
};

void setup() {
  setupM5Stack();
  setupBLE();
}

void loop() {
  delay(1000);
}

void setupM5Stack() {
  M5.begin();
  Serial.begin(115200);
}

void setupBLE() {
  Serial.println("Starting BLE");
  BLEDevice::init("my-peripheral");
  BLEServer *server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());

  BLEService *service = server->createService(serviceUUID);
  BLECharacteristic *characteristic = service->createCharacteristic(
                                         characteristicUUID,
                                         BLECharacteristic::PROPERTY_READ |
                                         BLECharacteristic::PROPERTY_WRITE
                                       );
  characteristic->setValue("Please input value");
  characteristic->setCallbacks(new CharacteristicCallbacks());
  service->start();
  BLEAdvertising *advertising = server->getAdvertising();
  advertising->addServiceUUID(service->getUUID());
  advertising->start();
}

void resetLcdCursor() {
  M5.Lcd.setCursor(10, 10);
}

template<typename ... Args>
void printTextToLcd(const std::string& format, Args const & ... args) {
  M5.Lcd.printf(format.c_str(), args ...);
}
