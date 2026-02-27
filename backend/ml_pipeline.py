import random
import time
from datetime import datetime, timedelta

class MockFatigueModel:
    def __init__(self):
        self.is_trained = False
        self.current_score = 45.0 
        
        # --- CORE STATE ---
        self.habits = [
            {"id": 1, "name": "Deep Work", "icon": "code", "color": "0xFFF44336", "reminder": "09:00"},
            {"id": 2, "name": "Hydration", "icon": "water_drop", "color": "0xFF2196F3", "reminder": "10:30"},
            {"id": 3, "name": "Meditation", "icon": "self_improvement", "color": "0xFF9C27B0", "reminder": "20:00"},
        ]
        self.habit_logs = {
            datetime.now().strftime("%Y-%m-%d"): {1: True, 2: False, 3: False}
        }
        self.tasks = [
            {
                "id": 1, 
                "name": "Analyze System Logs", 
                "date": datetime.now().strftime("%Y-%m-%d"),
                "reminders": ["14:00", "16:00"],
                "notes": "Look for memory leaks in the listener module.",
                "completed": False
            }
        ]
        self.next_habit_id = 4
        self.next_task_id = 2
        print("Initializing VOID OS: AI Neural Predictor Engine...")

    # --- HABIT & TASK METHODS ---
    def get_habits(self): return self.habits
    def add_habit(self, name, icon, color, reminder):
        new_habit = {"id": self.next_habit_id, "name": name, "icon": icon, "color": color, "reminder": reminder}
        self.habits.append(new_habit); self.next_habit_id += 1; return new_habit
    def toggle_habit_log(self, date, habit_id, status):
        if date not in self.habit_logs: self.habit_logs[date] = {}
        self.habit_logs[date][habit_id] = status; return self.habit_logs[date]
    def get_habit_logs(self, date): return self.habit_logs.get(date, {})
    def get_tasks(self, date=None): return [t for t in self.tasks if t["date"] == date] if date else self.tasks
    def add_task(self, name, date, reminders, notes):
        new_task = {"id": self.next_task_id, "name": name, "date": date, "reminders": reminders, "notes": notes, "completed": False}
        self.tasks.append(new_task); self.next_task_id += 1; return new_task
    def toggle_task_completion(self, task_id):
        for t in self.tasks:
            if t["id"] == task_id: t["completed"] = not t["completed"]; return t
        return None

    # --- ADVANCED AI PREDICTION ENGINE ---
    def train(self, historical_data): self.is_trained = True

    def predict(self, current_metrics):
        ks = current_metrics.get("keystrokes", 0)
        clicks = current_metrics.get("mouse_clicks", 0)
        bs = current_metrics.get("backspaces", 0)
        
        # Heuristic Fatigue Calculation
        if ks == 0 and clicks == 0:
            self.current_score -= 1.2 
        else:
            self.current_score += (ks * 0.08) + (clicks * 0.15) + (bs * 1.8)
            
        self.current_score = max(0.0, min(100.0, self.current_score))
        mental_battery = round(100.0 - self.current_score, 1)
        
        # 1. Decision Quality Index (DQI)
        dqi = mental_battery
        # 2. Burnout Trajectory
        if mental_battery < 30: burnout = "Critical - Immediate Intervention Required."
        elif mental_battery < 60: burnout = "Accelerating - System instability detected."
        else: burnout = "Sustainable - Predictor verifies safe operating range."
        
        # 3. Focus Half-Life (minutes)
        half_life = max(5, int((mental_battery / 100) * 120))
        # 4. Neural Activity Feed
        activity_intensity = "High" if (ks + clicks) > 20 else ("Medium" if (ks + clicks) > 5 else "Idle")
        
        # 5. Recovery Time Estimator
        recovery_mins = round((100 - mental_battery) / 1.5)
        
        # 6. AI Recommendation Logic
        if mental_battery > 80: rec = "System Primed. Execute complex architectural logic or deep-work protocols."
        elif mental_battery > 50: rec = "Nominal State. Target standard operations. Avoid mission-critical decisions."
        else: rec = "Cognitive Degradation. Risk of logic errors high. Initiate recovery or switch to low-load tasks."

        # 7. Adaptive Pomodoro Context
        if mental_battery > 75: pom_work, pom_break, pom_status = 45, 10, "Extended Focus"
        elif mental_battery > 40: pom_work, pom_break, pom_status = 25, 5, "Standard Pulse"
        else: pom_work, pom_break, pom_status = 15, 15, "Recovery Pulse"

        # 8. Task Sync for Dashboard
        today_str = datetime.now().strftime("%Y-%m-%d")
        today_tasks = [t for t in self.tasks if t["date"] == today_str]
        tasks_done = len([t for t in today_tasks if t["completed"]])
        task_completion_rate = int((tasks_done / len(today_tasks)) * 100) if today_tasks else 0

        return {
            "fatigue_score": round(self.current_score, 1), 
            "mental_battery": mental_battery,
            "burnout_trajectory": burnout,
            "focus_half_life": f"{half_life} Minutes",
            "decision_quality": f"{dqi}%",
            "recovery_estimate": f"{recovery_mins} Mins to Full Utility",
            "ai_recommendation": rec,
            "neural_activity": activity_intensity,
            "adaptive_pomodoro": {"work_mins": pom_work, "break_mins": pom_break, "status": pom_status},
            "task_completion": task_completion_rate,
            "streak_stability": 14, # Mocked
            "status_label": "OPTIMAL" if mental_battery > 70 else ("STABLE" if mental_battery > 40 else "CRITICAL")
        }
