#include <Wire.h>
#include <Adafruit_INA219.h>

// Create three instances of the Adafruit_INA219 class, one per sensor. 
// NOTE: We are using 3x sensors over here in 1x I2C bus.
Adafruit_INA219 ina219_1(0x41); // A0 shorted, A1 not shorted => Connected to USB Charge Controller #1
Adafruit_INA219 ina219_2(0x44); // A0 not shorted, A1 shorted => Connected to USB Charge Controller #2
Adafruit_INA219 ina219_3(0x45); // A0 shorted, A1 shorted => Connected and monitors power production of Solar Panel

// Define relay pin (GPIO 0 of XIAO ESP32C6)
// Relay controls power between AC Grid and Solar Panel
#define RELAY_PIN 0

// Timing variable for sensor reading every 2 seconds
unsigned long previousSensorMillis = 0;

void setup(void)
{
  Serial.begin(115200);
  // Optional to wait for serial monitor. Leave this commented out for production units.
  /*
  while (!Serial) {
    delay(1); // wait for Serial monitor
  }
  */
  
  // Initialize the relay control pin
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW); // Start with relay pin LOW

  Serial.println("Initializing three INA219 sensors...");

  // Initialize each INA219 with its specific address
  if (!ina219_1.begin()) {
    Serial.println("Failed to find INA219 chip at 0x41");
    while (1) { delay(10); }
  }
  if (!ina219_2.begin()) {
    Serial.println("Failed to find INA219 chip at 0x44");
    while (1) { delay(10); }
  }
  if (!ina219_3.begin()) {
    Serial.println("Failed to find INA219 chip at 0x45");
    while (1) { delay(10); }
  }

  // Optionally configure each sensor’s calibration range.
  ina219_1.setCalibration_32V_1A();
  ina219_2.setCalibration_32V_1A();
  ina219_3.setCalibration_32V_1A();

  Serial.println("All INA219 sensors initialized.");
}

void loop(void)
{
  unsigned long currentMillis = millis();

  // Read sensors every 2 seconds
  if (currentMillis - previousSensorMillis >= 2000) {
    previousSensorMillis = currentMillis;

    // Readings for INA219 #1
    float shuntvoltage_1 = ina219_1.getShuntVoltage_mV();
    float busvoltage_1   = ina219_1.getBusVoltage_V();
    float current_mA_1   = ina219_1.getCurrent_mA();
    float power_mW_1     = ina219_1.getPower_mW();
    float loadvoltage_1  = busvoltage_1 + (shuntvoltage_1 / 1000);

    // Readings for INA219 #2
    float shuntvoltage_2 = ina219_2.getShuntVoltage_mV();
    float busvoltage_2   = ina219_2.getBusVoltage_V();
    float current_mA_2   = ina219_2.getCurrent_mA();
    float power_mW_2     = ina219_2.getPower_mW();
    float loadvoltage_2  = busvoltage_2 + (shuntvoltage_2 / 1000);

    // Readings for INA219 #3
    float shuntvoltage_3 = ina219_3.getShuntVoltage_mV();
    float busvoltage_3   = ina219_3.getBusVoltage_V();
    float current_mA_3   = ina219_3.getCurrent_mA();
    float power_mW_3     = ina219_3.getPower_mW();
    float loadvoltage_3  = busvoltage_3 + (shuntvoltage_3 / 1000);

    // Print sensor readings for INA219_1
    Serial.print("INA219_1  => Bus: ");
    Serial.print(busvoltage_1); Serial.print(" V; Shunt: ");
    Serial.print(shuntvoltage_1); Serial.print(" mV; Load: ");
    Serial.print(loadvoltage_1); Serial.print(" V; Current: ");
    Serial.print(current_mA_1); Serial.print(" mA; Power: ");
    Serial.print(power_mW_1); Serial.println(" mW");

    // Print sensor readings for INA219_2
    Serial.print("INA219_2  => Bus: ");
    Serial.print(busvoltage_2); Serial.print(" V; Shunt: ");
    Serial.print(shuntvoltage_2); Serial.print(" mV; Load: ");
    Serial.print(loadvoltage_2); Serial.print(" V; Current: ");
    Serial.print(current_mA_2); Serial.print(" mA; Power: ");
    Serial.print(power_mW_2); Serial.println(" mW");

    // Print sensor readings for INA219_3
    Serial.print("INA219_3  => Bus: ");
    Serial.print(busvoltage_3); Serial.print(" V; Shunt: ");
    Serial.print(shuntvoltage_3); Serial.print(" mV; Load: ");
    Serial.print(loadvoltage_3); Serial.print(" V; Current: ");
    Serial.print(current_mA_3); Serial.print(" mA; Power: ");
    Serial.print(power_mW_3); Serial.println(" mW");

    // Check voltage from INA219_3 and set relay accordingly
    if (busvoltage_3 < 13.8) {
      digitalWrite(RELAY_PIN, HIGH);
      Serial.println("INA219_3 voltage < 13.8V: Relay set to HIGH.");
    } 
    else {
      digitalWrite(RELAY_PIN, LOW);
      Serial.println("INA219_3 voltage >= 13.8V: Relay set to LOW.");
    }

    Serial.println();
  }
}
