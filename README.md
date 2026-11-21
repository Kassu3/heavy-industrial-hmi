# Heavy Industrial Control Interface v1.0 

A real-time heavy industrial machine (excavator) human-machine interface (HMI) dashboard and dynamic hardware simulator. The system is built modularly using separate C++ and Python services that communicate over a local network.

### System Architecture

The project implements a modern IoT architecture to ensure separation of concerns and fault tolerance:

* **Hardware & Physics Simulator (Python):** A threaded background process that dynamically calculates engine load, temperatures, and hydraulic physics based on the throttle position. It transmits telemetry data as compressed JSON datagrams over the network.
* **Control Panel / HMI (C++ & Qt6):** A client application that receives the UDP data, parses the JSON packets, and renders real-time charts and status information on an industry-standard control display.

[ Python Hardware Simulator ] ---( JSON via UDP Port 45454 )---> [ C++ / Qt6 Quick HMI ]

> **AI Diagnostics Integration:** In addition to the main HMI stream (port `45454`), the simulator mirrors real-time telemetry to a secondary UDP port (`45456`), allowing a separate **Gemma 2 RAG AI Maintenance Center** to monitor fault states and assist operators live.

### Repository Structure 

```text 
heavy-industrial-hmi/
├── excavator_simulator.py         # Python physics & UDP telemetry simulator 
├── CMakeLists.txt                 # Qt6 / CMake build configuration 
├── main.cpp                       # C++ application entry point
├── machinecontroller.h/.cpp       # C++ backend controller & UDP socket listener 
├── Main.qml                       # Main Qt Quick / QML operator dashboard
├── TelemetryChart.qml             # Real-time telemetry graphing component 
└── i18n/                          # Multilingual translation files (FI, EN, SV, DE)

### Key Features

* **Real-Time Telemetry:** High-performance UDP socket communication guarantees a lag-free data stream from the simulator to the display.
* **Dynamic Multilingual Support (i18n):** Full support for switching the UI language on the fly (Finnish, English, Swedish, German) without restarting the application. Implemented using the Qt translation database (`QTranslator`) and dynamic string arguments (`.arg()`).
* **Intelligent State Machine:** A C++ background diagnostic engine detects critical fault states (such as overheating or hydraulic overpressure) and drives HMI warning states and animations in real time.
* **Real-Time Industrial Charts:** Multi-axis visualization for engine RPM and historical performance data.

### Technologies & Expertise

This project combines practical product development with my Full Stack capabilities and ongoing studies in Information and Communication Technology (B.Eng):

* **C++ & Qt6 (Qt Quick / QML / CMake):** User interface logic, custom components, dynamic bindings, and layouts.
* **Python (Threading, Sockets):** Hardware simulation, I/O logic, and data packetization.
* **Networking (UDP, Sockets):** Message routing and network protocols (applying **CCNA1 & CCNA2** studies to practice).
* **Internationalization (i18n):** Mastery of `lupdate` / `lrelease` tools and multilingual software architecture.

### Installation and Launch

1. Start the Python background simulator:
   ```bash
   cd excavator-simulator
   python excavator_simulator.py
   ```

2. Compile and run the C++ HMI panel using Qt Creator (Qt6 / CMake) or from the command line:
   ```bash
   cd IndustrialDashboard
   cmake -B build -S .
   cmake --build build
   ./build/appIndustrialDashboard
   ```

---