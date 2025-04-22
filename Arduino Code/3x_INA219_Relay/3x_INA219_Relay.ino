#include <Wire.h>
#include <Adafruit_INA219.h>

// We create three instances of the Adafruit_INA219 class, one per sensor.
// NOTE: We are using 3x sensors on a single I²C bus.
Adafruit_INA219 ina219_1(0x41); // INA219 for USB Charge Controller #1
Adafruit_INA219 ina219_2(0x44); // INA219 for USB Charge Controller #2
Adafruit_INA219 ina219_3(0x45); // INA219 for Solar Panel production

// Define relay pin (GPIO 0 of XIAO ESP32C6)
// Relay controls power between AC Grid and Solar Panel
#define RELAY_PIN 0

// ***** Stepper Motor Definitions for DRV8825 *****
// Update the pin numbers according to your wiring.
#define MOTOR_STEP_PIN    18    // Connect to DRV8825 STEP pin
#define MOTOR_DIR_PIN     20    // Connect to DRV8825 DIR pin
#define MOTOR_ENABLE_PIN  19    // Connect to DRV8825 ENABLE pin (active LOW by default)

// ***** Limit Switch Definition *****
// The limit switch (SPDT) is connected as an analog input on GPIO1.
// With a 4.7kΩ pull-up resistor, the line is normally high; when pressed,
// the voltage is pulled below 1.0 V.
#define LIMIT_SWITCH_PIN 1
const float LIMIT_SWITCH_THRESHOLD = 1.0;   // Threshold in volts

// Motor movement configuration
// No automatic reversal on full revolution now
const int motorStepsPerRevolution = 200;  // (Optional: if we ever need to count steps)
int motorStepCount = 0;                   // (Optional)

// Timing intervals for step pulse generation (in microseconds)
unsigned long motorLastChangeMicros = 0;
const unsigned long motorStepInterval = 2000;      // Time between steps (adjust as needed)
const unsigned long motorPulseHighDuration = 50;     // Duration the pulse stays HIGH
bool motorPulseState = false;                        // Tracks step pulse state

// Timing variable for sensor reading every 1 second
unsigned long previousSensorMillis = 0;

// --- Finite-State Machine for Motor Direction ---
// Define an enumerator representing motor direction.
enum MotorDirection { ANTICLOCKWISE, CLOCKWISE };
MotorDirection currentDirection = ANTICLOCKWISE; // Start spinning anticlockwise

// Variable for limit switch edge detection, analog based
bool previousLimitPressed = false;
bool sensor1Available,sensor2Available,sensor3Available;
void setup(void)
{
  Serial.begin(115200);
  
  // ----- Initialize INA219 Sensors -----
  Serial.println("Initializing three INA219 sensors...");

  sensor1Available = ina219_1.begin();
  if (!sensor1Available) Serial.println("INA219_1 (0x41) not found.");

  sensor2Available = ina219_2.begin();
  if (!sensor2Available) Serial.println("INA219_2 (0x44) not found.");

  sensor3Available = ina219_3.begin();
  if (!sensor3Available) Serial.println("INA219_3 (0x45) not found.");

  // Only set calibration for sensors that are available
  if (sensor1Available) ina219_1.setCalibration_32V_1A();
  if (sensor2Available) ina219_2.setCalibration_32V_1A();
  if (sensor3Available) ina219_3.setCalibration_32V_1A();

  Serial.println("Sensor initialization complete.");

  
  // Optionally configure each sensor's calibration range.
  ina219_1.setCalibration_32V_1A();
  ina219_2.setCalibration_32V_1A();
  ina219_3.setCalibration_32V_1A();

  Serial.println("All INA219 sensors initialized.");

  // ----- Initialize Relay Control -----
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW); // Start with relay pin LOW

  // ----- Initialize Stepper Motor Control Pins -----
  pinMode(MOTOR_STEP_PIN, OUTPUT);
  pinMode(MOTOR_DIR_PIN, OUTPUT);
  pinMode(MOTOR_ENABLE_PIN, OUTPUT);

  // Enable the motor driver (ENABLE is active LOW for most DRV8825 boards)
  digitalWrite(MOTOR_ENABLE_PIN, LOW);
  // Set the initial motor direction based on the FSM.
  digitalWrite(MOTOR_DIR_PIN, (currentDirection == ANTICLOCKWISE) ? HIGH : LOW);

  // ----- Initialize Limit Switch Pin -----
  // We'll use analogRead on this pin, so setting mode is optional.
  pinMode(LIMIT_SWITCH_PIN, INPUT);

  // Initialize timing variables for stepper pulse generation
  motorLastChangeMicros = micros();
}

void loop(void)
{
  unsigned long currentMillis = millis();
  unsigned long currentMicros = micros();

  // Limit Switch Processing (Analog Read)
  // Read the analog voltage on GPIO1.
  int analogVal = analogRead(LIMIT_SWITCH_PIN);
  // Convert ADC value to voltage (assuming a 3.3V reference and 12-bit ADC).
  float limitVoltage = analogVal * (3.3 / 4095.0);
  
  // Determine if the limit switch is "pressed" (voltage below threshold).
  bool currentLimitPressed = (limitVoltage < LIMIT_SWITCH_THRESHOLD);
  
  // Edge detection: Toggle direction only when the switch is pressed (transition from not-pressed to pressed).
  if (currentLimitPressed && !previousLimitPressed) {
    // Toggle the motor direction.
    if (currentDirection == ANTICLOCKWISE)
      currentDirection = CLOCKWISE;
    else
      currentDirection = ANTICLOCKWISE;
      
    // Update the direction output.
    digitalWrite(MOTOR_DIR_PIN, (currentDirection == ANTICLOCKWISE) ? HIGH : LOW); // Finite State Machine
    Serial.print("Limit switch triggered (Voltage = ");
    Serial.print(limitVoltage, 2);
    Serial.println(" V): Changing motor direction.");
  }
  previousLimitPressed = currentLimitPressed;
  
  // --- Sensor Reading and Relay Control (every 1 second) ---
  if (currentMillis - previousSensorMillis >= 1000) {
    previousSensorMillis = currentMillis;

    if (sensor1Available) {
      float shuntvoltage_1 = ina219_1.getShuntVoltage_mV();
      float busvoltage_1   = ina219_1.getBusVoltage_V();
      float current_mA_1   = ina219_1.getCurrent_mA();
      float power_mW_1     = ina219_1.getPower_mW();
      float loadvoltage_1  = busvoltage_1 + (shuntvoltage_1 / 1000);
      
      Serial.print("INA219_1  => Bus: ");
      Serial.print(busvoltage_1); Serial.print(" V; Current: ");
      Serial.print(current_mA_1); Serial.print(" mA; Power: ");
      Serial.print(power_mW_1); Serial.println(" mW");
    }

    if (sensor2Available) {
      float shuntvoltage_2 = ina219_2.getShuntVoltage_mV();
      float busvoltage_2   = ina219_2.getBusVoltage_V();
      float current_mA_2   = ina219_2.getCurrent_mA();
      float power_mW_2     = ina219_2.getPower_mW();
      float loadvoltage_2  = busvoltage_2 + (shuntvoltage_2 / 1000);
      
      Serial.print("INA219_2  => Bus: ");
      Serial.print(busvoltage_2); Serial.print(" V; Current: ");
      Serial.print(current_mA_2); Serial.print(" mA; Power: ");
      Serial.print(power_mW_2); Serial.println(" mW");
    }

    if (sensor3Available) {
      float shuntvoltage_3 = ina219_3.getShuntVoltage_mV();
      float busvoltage_3   = ina219_3.getBusVoltage_V();
      float current_mA_3   = ina219_3.getCurrent_mA();
      float power_mW_3     = ina219_3.getPower_mW();
      float loadvoltage_3  = busvoltage_3 + (shuntvoltage_3 / 1000);
      
      Serial.print("INA219_3  => Bus: ");
      Serial.print(busvoltage_3); Serial.print(" V; Current: ");
      Serial.print(current_mA_3); Serial.print(" mA; Power: ");
      Serial.print(power_mW_3); Serial.println(" mW");

      // Only control relay if sensor 3 is available
      if (busvoltage_3 < 11.8) {
        digitalWrite(RELAY_PIN, HIGH);
        Serial.println("INA219_3 voltage < 11.8V: Relay set to HIGH.");
      } else {
        digitalWrite(RELAY_PIN, LOW);
        Serial.println("INA219_3 voltage >= 11.8V: Relay set to LOW.");
      }
    } else {
      Serial.println("INA219_3 unavailable: Relay left unchanged.");
    }

    Serial.println();
  }


  // --- Stepper Motor Control (nonblocking) ---
  // Generate a step pulse for continuous motor movement.
  if (!motorPulseState && (currentMicros - motorLastChangeMicros >= motorStepInterval)) {
    // Start the pulse.
    digitalWrite(MOTOR_STEP_PIN, HIGH);
    motorPulseState = true;
    motorLastChangeMicros = currentMicros;
  }
  else if (motorPulseState && (currentMicros - motorLastChangeMicros >= motorPulseHighDuration)) {
    // End the pulse.
    digitalWrite(MOTOR_STEP_PIN, LOW);
    motorPulseState = false;
    motorLastChangeMicros = currentMicros;
    
    // Optionally, count steps if needed:
    motorStepCount++;
    // No auto-reversal on full revolution here.
  }
}
