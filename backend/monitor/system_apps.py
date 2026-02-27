import psutil
import time

class SystemMonitor:
    def __init__(self):
        pass

    def get_active_window_process(self):
        # Note: Getting the exact active window across OSes requires OS-specific APIs.
        # Psutil can give us CPU/Mem usage of processes, which is useful for general load.
        # For active window on Windows, we'd typically use win32gui, but we'll use a placeholder
        # or just monitor highest CPU processes as a proxy for "active" tasks for now.
        
        # This is a basic stub that lists top CPU consuming processes.
        processes = []
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent']):
            try:
                if proc.info['cpu_percent'] > 0.0:
                    processes.append(proc.info)
            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                pass
        
        # Sort by CPU usage
        processes = sorted(processes, key=lambda p: p['cpu_percent'], reverse=True)
        return processes[:5] # Return top 5

if __name__ == "__main__":
    sys_mon = SystemMonitor()
    while True:
        print("Top Processes:", sys_mon.get_active_window_process())
        time.sleep(5)
