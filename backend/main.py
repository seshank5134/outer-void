from fastapi import FastAPI, Body, Query
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import contextlib
from datetime import datetime

from ml_pipeline import MockFatigueModel
from monitor.keyboard_mouse import ActivityMonitor

model = MockFatigueModel()
model.train([]) 
activity_monitor = ActivityMonitor()

@contextlib.asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        activity_monitor.start()
    except Exception as e:
        print(f"Operational Notice: Activity Monitor (Hardware Feed) disabled on this environment: {e}")
    yield
    try:
        activity_monitor.stop()
    except:
        pass

app = FastAPI(title="VOID OS: Control Center API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/v1/fatigue-score")
def get_status():
    metrics = activity_monitor.get_metrics()
    prediction = model.predict(metrics)
    return prediction

# --- HABIT CONTROL ---

@app.get("/api/v1/habits")
def get_habits():
    return model.get_habits()

@app.post("/api/v1/habits")
def add_habit(
    name: str = Body(..., embed=True),
    icon: str = Body("circle", embed=True),
    color: str = Body("0xFFF44336", embed=True),
    reminder: str = Body("09:00", embed=True)
):
    return model.add_habit(name, icon, color, reminder)

@app.get("/api/v1/habit-logs/{date}")
def get_habit_logs(date: str):
    return model.get_habit_logs(date)

@app.post("/api/v1/habit-logs/{date}/{habit_id}")
def toggle_habit(date: str, habit_id: int, status: bool = Body(..., embed=True)):
    return model.toggle_habit_log(date, habit_id, status)

# --- TASK CONTROL ---

@app.get("/api/v1/tasks")
def get_tasks(date: str = Query(None)):
    return model.get_tasks(date)

@app.post("/api/v1/tasks")
def add_task(
    name: str = Body(..., embed=True),
    date: str = Body(..., embed=True),
    reminders: list = Body([], embed=True),
    notes: str = Body("", embed=True)
):
    return model.add_task(name, date, reminders, notes)

@app.post("/api/v1/tasks/{task_id}/toggle")
def toggle_task(task_id: int):
    return model.toggle_task_completion(task_id)

if __name__ == "__main__":
    import os
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port)
