import socket
import time
import random
import json
import threading

# Verkon määrittelyt
#SEND_IP = "127.0.0.1"
SEND_PORT = 45454 # C++ vastaanottoportti MachineController
LISTEN_PORT = 45455 # Simulaattorin oma portti ohjauskäskyjä C++ lähettää
AI_PORT = 45456 # AI Diagnostic Agentin kuunteluportti

class ExcavatorSimulator:
    # Sisäinen tila
    running = True
    emergency_stop = False
    
    # Telemetria-arvot
    throttle = 0.0         # Prosentteina 0 - 100
    motor_rpm = 0
    engine_temp = 45.0     # Lähtölämpötila
    hydr_pressure = 120.0  # Lepopaine bar
    motor_load = 0
    bucket_angle = 0.0     # Kauhan kulma asteina

    def __init__(self): 
        # Soketit
        self.send_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.listen_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.listen_socket.bind(('127.0.0.1', LISTEN_PORT))

    def listen_commands(self):
        """ Kuuntelee C++ suunnalta QML tulevia ohjauskäskyjä"""
        print(f"[SIMULATOR] Kuuntelu käynnistetty portissa {LISTEN_PORT}...")
        while self.running:
            try:
                data, addr = self.listen_socket.recvfrom(1024)
                command_json = json.loads(data.decode('utf-8'))

                cmd = command_json.get("command")
                val = command_json.get("value", 0)

                if cmd == "emergency_stop":
                    print(f"[SIMULATOR] ⚠ EMERGENCY STOP VASTAANOTETTU!")
                    self.emergency_stop = True
                    self.throttle = 0
                    self.motor_rpm = 0
                    self.motor_load = 0

                elif cmd == "set_speed" and not self.emergency_stop:
                    self.throttle = float(val)
                    print(f"[SIMULATOR] Kaasu asetettu : {self.throttle}%")

                elif cmd == "adjust_bucket" and not self.emergency_stop:
                    # Lisätään tai vähennetään kulmaa (QML antaa esim. +5 tai -5)
                    self.bucket_angle = max(-45.0, min(90.0, self.bucket_angle + float(val)))
                    print(f"[SIMULATOR] Kauhan kulma: {self.bucket_angle}°")

            except Exception as e:
                if self.running:
                    print(f"[SIMULATOR] Virhe käskyä luettaessa: {e}")

    def update_physics(self):
        """ Simuloi kaivinkoneen fysiikkaa dynaamisesti kaasun mukaan"""
        if self.emergency_stop:
            # Hätäseis pudottaa arvot heti nollaan, mutta lämpö laskee hitaasti
            self.motor_rpm = 0
            self.motor_load = 0
            self.hydr_pressure = max(0.0, self.hydr_pressure - 10.0)
            self.engine_temp = max(30.0, self.engine_temp - 0.2)
            return

        # 1. Kierrosluku (RPM) seuraa kaasua (Throttle) pienellä viiveellä
        target_rpm = int(self.throttle * 28) # esim. 100% kaasu = 2800 RPM
        if self.motor_rpm < target_rpm:
            self.motor_rpm += min(150, target_rpm - self.motor_rpm)
        elif self.motor_rpm > target_rpm:
            self.motor_rpm -= min(150, self.motor_rpm - target_rpm)

        # Lisätään pientä tyhjäkäyntiä RPM-arvoon jotta se elää näytöllä
        if self.throttle > 0:
            self.motor_rpm += random.randint(-15, 15)

        # 2. Moottorin kuormitus (Motor Load %)
        # Korkea kaasu luo pohjakuorman, johon lisätään pientä kohinaa
        self.motor_load = int(self.throttle * 0.9 + random.randint(-3, 3))
        self.motor_load = max(0, min(100, self.motor_load))

        # 3. Hydrauliikan paine (Hydraulic Pressure bar)
        #  Paine nousee RPM:n mukana. Lepopaine 120 barm maksimi n. 320 bar.
        base_pressure = 120.0 + (self.motor_rpm / 2800.0) * 180.0
        self.hydr_pressure = base_pressure + random.uniform(-2.0, 2.0)
        self.hydr_pressure = max(0.0, min(400.0, self.hydr_pressure))

        # 4. Moottorin lämpötila (Engine Temp °C)
        # Jos kuorma/kaasu on korkea (> 80%), moottori alkaa kuumeta
        if self.motor_load > 80:
            if self.engine_temp < 105.0:
                self.engine_temp += random.uniform(0.3, 0.7) # Kuumenee vauhdilla
        elif self.motor_load > 30:
            self.engine_temp += random.uniform(0.05, 0.15) # Nousee hitaasti työlämpöön
        else:
            # Jäähtyy kohti lepolämpöä (ympäristö) jos ollaan tyhjäkäynnillä
            if self.engine_temp > 50.0:
                self.engine_temp -= 0.1
     
    def send_telemetry(self):
        """ Lähettää valmiin JSON paketin C++ taustalle 100ms välein"""
        print(f"[SIMULATOR] Telemetrian lähetys aloitettu porttiin {SEND_PORT}...")
        while self.running:
            self.update_physics()

            # Rakennetaan täsmälleen avaimet, joita C++ QJsonDocument odottaa
            telemetry_data = {
                "motorRpm": int(self.motor_rpm),
                "engineTemperature": float(round(self.engine_temp, 1)),
                "hydraulicPressure": float(round(self.hydr_pressure, 1)),
                "motorLoad": int(self.motor_load),
                "bucketAngle": float(round(self.bucket_angle, 1))
            }

            try:
                json_bytes = json.dumps(telemetry_data).encode('utf-8')
                self.send_socket.sendto(json_bytes, ('127.0.0.1', SEND_PORT)) # C++ QML-liittymälle
                self.send_socket.sendto(json_bytes, ('127.0.0.1', AI_PORT)) # Lähetys tekoälyagentille
            except Exception as e:
                if self.running:
                    print(f"[SIMULATOR] Lähetysvirhe: {e}")

            time.sleep(0.1) # 10 Hz pöivitysnopeus (erittäin tasainen kuvaajalle)

    def start(self):
        # Ajetaan kuuntelu ja lähetys omissa säikeissään (Thread), jotta ne toimivat
        self.listener_thread = threading.Thread(target=self.listen_commands)
        self.telemetry_thread = threading.Thread(target=self.send_telemetry)

        self.listener_thread.start()
        self.telemetry_thread.start()

        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("\n[simulator] Suljetaan simulaattori...")
            self.running = False
            try:
                self.listen_socket.close()
                self.send_socket.close()
            except:
                pass

if __name__ == "__main__":
    simulator = ExcavatorSimulator()
    try:
        simulator.start()
    except KeyboardInterrupt:
        simulator.stop()

