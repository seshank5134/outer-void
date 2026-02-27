import time
import threading
from pynput import keyboard, mouse

class ActivityMonitor:
    def __init__(self):
        self.keystroke_count = 0
        self.backspace_count = 0
        self.mouse_movement_distance = 0.0
        self.click_count = 0
        self.is_monitoring = False
        self.lock = threading.Lock()
        
    def on_press(self, key):
        with self.lock:
            self.keystroke_count += 1
            if key == keyboard.Key.backspace:
                self.backspace_count += 1

    def on_move(self, x, y):
        # In a real scenario, we'd calculate Euclidean distance between points
        with self.lock:
            self.mouse_movement_distance += 1.0 

    def on_click(self, x, y, button, pressed):
        if pressed:
            with self.lock:
                self.click_count += 1

    def start(self):
        self.is_monitoring = True
        self.kb_listener = keyboard.Listener(on_press=self.on_press)
        self.mouse_listener = mouse.Listener(on_move=self.on_move, on_click=self.on_click)
        
        self.kb_listener.start()
        self.mouse_listener.start()
        print("Monitoring started...")

    def stop(self):
        self.is_monitoring = False
        self.kb_listener.stop()
        self.mouse_listener.stop()
        print("Monitoring stopped.")
        
    def get_metrics(self):
        with self.lock:
            metrics = {
                "keystrokes": self.keystroke_count,
                "backspaces": self.backspace_count,
                "mouse_distance": self.mouse_movement_distance,
                "mouse_clicks": self.click_count,
                "timestamp": time.time()
            }
            # Reset counters for the next interval
            self.keystroke_count = 0
            self.backspace_count = 0
            self.mouse_movement_distance = 0.0
            self.click_count = 0
            return metrics

if __name__ == "__main__":
    monitor = ActivityMonitor()
    monitor.start()
    try:
        while True:
            time.sleep(5) # collect metrics every 5 seconds
            print(monitor.get_metrics())
    except KeyboardInterrupt:
        monitor.stop()
