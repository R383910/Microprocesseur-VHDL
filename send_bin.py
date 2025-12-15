import serial
import time
import os

# python -m serial.tools.list_ports
SERIAL_PORT = 'COM3'
BAUD_RATE = 9600
FILENAME = "programme.bin"

def send_and_monitor():
    print(f"--- UART TOOL : ENVOI & MONITOR ({SERIAL_PORT} @ {BAUD_RATE}) ---")
    
    ser = None
    try:
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=0.1)

        print("Port ouvert. Initialisation (2s)...")
        time.sleep(2) 

        if not os.path.exists(FILENAME):
            print(f"Erreur : Le fichier '{FILENAME}' est introuvable.")
            return

        with open(FILENAME, 'rb') as f:
            data = f.read()

        # 3. ENVOI DES DONNÉES
        print(f"Envoi de {len(data)} octets...")
        ser.write(data)
        ser.flush()
        print("Envoi termine => ecoute...\n")
        print("-" * 55)
        print(f"{'RECU (DEC)':<12} | {'HEX':<8} | {'ASCII':<8}")
        print("-" * 55)

        while True:
            if ser.in_waiting > 0:
                byte_data = ser.read(1)
                
                if byte_data:
                    val = int.from_bytes(byte_data, byteorder='little')
                    char_display = chr(val) if 32 <= val <= 126 else '.'
                    
                    print(f"RECU:  {val:<6} |  0x{val:02X}   |  {char_display}")
            
            time.sleep(0.001)

    except serial.SerialException:
        print(f"\nErreur Serial : Impossible d'acceder à {SERIAL_PORT}.")
        print("Vérifie que le port n'est pas utilise par un autre logiciel.")
        
    except KeyboardInterrupt:
        print("\nArret utilisateur (CTRL+C).")
        
    except Exception as e:
        print(f"\nErreur inattendue : {e}")
        
    finally:
        if ser and ser.is_open:
            ser.close()
            print("Port serie ferme.")

if __name__ == "__main__":
    send_and_monitor()