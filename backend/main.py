from fastapi import FastAPI, Body, Query, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
import uvicorn
import contextlib
import json
from datetime import datetime
from sqlalchemy.orm import Session
from typing import Optional

from database import get_db, init_db, User, Habit, HabitLog, Task, UserPreferences
from auth import (
    get_password_hash, create_access_token, authenticate_user,
    get_current_user, get_user_by_email, get_user_by_username
)
from ml_pipeline import MockFatigueModel
from monitor.keyboard_mouse import ActivityMonitor

model = MockFatigueModel()
model.train([])
activity_monitor = ActivityMonitor()


@contextlib.asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    try:
        activity_monitor.start()
    except Exception as e:
        print(f"Notice: Activity Monitor disabled: {e}")
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


# ==================== AUTH ROUTES ====================

@app.post("/api/v1/auth/register")
def register(
    username: str = Body(..., embed=True),
    email: str = Body(..., embed=True),
    password: str = Body(..., embed=True),
    db: Session = Depends(get_db)
):
    if get_user_by_email(db, email):
        raise HTTPException(status_code=400, detail="Email already registered")
    if get_user_by_username(db, username):
        raise HTTPException(status_code=400, detail="Username already taken")
    
    hashed = get_password_hash(password)
    user = User(email=email, username=username, hashed_password=hashed)
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Create default preferences
    prefs = UserPreferences(user_id=user.id)
    db.add(prefs)
    
    # Seed default habits
    default_habits = [
        Habit(user_id=user.id, name="Deep Work", icon="code", color="0xFFF44336", reminder="09:00", category="productivity"),
        Habit(user_id=user.id, name="Hydration", icon="water_drop", color="0xFF2196F3", reminder="10:30", category="health"),
        Habit(user_id=user.id, name="Meditation", icon="self_improvement", color="0xFF9C27B0", reminder="20:00", category="wellness"),
    ]
    for h in default_habits:
        db.add(h)
    
    db.commit()
    
    token = create_access_token(data={"sub": str(user.id)})
    return {"access_token": token, "token_type": "bearer", "user": {"id": user.id, "username": user.username, "email": user.email}}


@app.post("/api/v1/auth/login")
def login(
    email: str = Body(..., embed=True),
    password: str = Body(..., embed=True),
    db: Session = Depends(get_db)
):
    user = authenticate_user(db, email, password)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = create_access_token(data={"sub": str(user.id)})
    return {"access_token": token, "token_type": "bearer", "user": {"id": user.id, "username": user.username, "email": user.email}}


@app.get("/api/v1/auth/me")
def get_me(current_user: User = Depends(get_current_user)):
    return {"id": current_user.id, "username": current_user.username, "email": current_user.email}


# ==================== AI PREDICTION ====================

@app.get("/api/v1/fatigue-score")
def get_status(current_user: User = Depends(get_current_user)):
    metrics = activity_monitor.get_metrics()
    prediction = model.predict(metrics)
    return prediction


# ==================== PREFERENCES ====================

@app.get("/api/v1/preferences")
def get_preferences(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    prefs = db.query(UserPreferences).filter(UserPreferences.user_id == current_user.id).first()
    if not prefs:
        prefs = UserPreferences(user_id=current_user.id)
        db.add(prefs)
        db.commit()
        db.refresh(prefs)
    return {
        "pomodoro_work_mins": prefs.pomodoro_work_mins,
        "pomodoro_break_mins": prefs.pomodoro_break_mins,
        "pomodoro_long_break_mins": prefs.pomodoro_long_break_mins,
        "pomodoro_sessions_before_long_break": prefs.pomodoro_sessions_before_long_break,
        "theme_name": prefs.theme_name,
        "accent_color": prefs.accent_color,
        "bg_gradient_start": prefs.bg_gradient_start,
        "bg_gradient_end": prefs.bg_gradient_end,
        "glass_opacity": prefs.glass_opacity,
        "ui_font_scale": prefs.ui_font_scale,
        "sidebar_width": prefs.sidebar_width,
        "card_border_radius": prefs.card_border_radius,
        "show_animations": prefs.show_animations,
        "compact_mode": prefs.compact_mode,
    }


@app.put("/api/v1/preferences")
def update_preferences(
    updates: dict = Body(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    prefs = db.query(UserPreferences).filter(UserPreferences.user_id == current_user.id).first()
    if not prefs:
        prefs = UserPreferences(user_id=current_user.id)
        db.add(prefs)

    allowed_fields = [
        "pomodoro_work_mins", "pomodoro_break_mins", "pomodoro_long_break_mins",
        "pomodoro_sessions_before_long_break", "theme_name", "accent_color",
        "bg_gradient_start", "bg_gradient_end", "glass_opacity",
        "ui_font_scale", "sidebar_width", "card_border_radius",
        "show_animations", "compact_mode"
    ]
    for field, value in updates.items():
        if field in allowed_fields:
            setattr(prefs, field, value)

    db.commit()
    db.refresh(prefs)
    return {"status": "preferences_updated"}


# ==================== HABITS ====================

@app.get("/api/v1/habits")
def get_habits(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    habits = db.query(Habit).filter(Habit.user_id == current_user.id).all()
    return [
        {
            "id": h.id, "name": h.name, "icon": h.icon, "color": h.color,
            "reminder": h.reminder, "category": h.category, "description": h.description
        }
        for h in habits
    ]


@app.post("/api/v1/habits")
def add_habit(
    name: str = Body(..., embed=True),
    icon: str = Body("circle", embed=True),
    color: str = Body("0xFFF44336", embed=True),
    reminder: str = Body("09:00", embed=True),
    category: str = Body("general", embed=True),
    description: str = Body("", embed=True),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    habit = Habit(
        user_id=current_user.id, name=name, icon=icon,
        color=color, reminder=reminder, category=category, description=description
    )
    db.add(habit)
    db.commit()
    db.refresh(habit)
    return {
        "id": habit.id, "name": habit.name, "icon": habit.icon, "color": habit.color,
        "reminder": habit.reminder, "category": habit.category, "description": habit.description
    }


@app.delete("/api/v1/habits/{habit_id}")
def delete_habit(
    habit_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    habit = db.query(Habit).filter(Habit.id == habit_id, Habit.user_id == current_user.id).first()
    if not habit:
        raise HTTPException(status_code=404, detail="Habit not found")
    db.delete(habit)
    db.commit()
    return {"status": "deleted"}


@app.get("/api/v1/habit-logs/{date}")
def get_habit_logs(
    date: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    logs = db.query(HabitLog).filter(
        HabitLog.user_id == current_user.id,
        HabitLog.date == date
    ).all()
    return {str(log.habit_id): log.completed for log in logs}


@app.post("/api/v1/habit-logs/{date}/{habit_id}")
def toggle_habit(
    date: str,
    habit_id: int,
    status: bool = Body(..., embed=True),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    log = db.query(HabitLog).filter(
        HabitLog.user_id == current_user.id,
        HabitLog.habit_id == habit_id,
        HabitLog.date == date
    ).first()
    if log:
        log.completed = status
    else:
        log = HabitLog(user_id=current_user.id, habit_id=habit_id, date=date, completed=status)
        db.add(log)
    db.commit()
    return {"status": "ok"}


# ==================== TASKS ====================

@app.get("/api/v1/tasks")
def get_tasks(
    date: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    query = db.query(Task).filter(Task.user_id == current_user.id)
    if date:
        query = query.filter(Task.date == date)
    tasks = query.all()
    return [
        {
            "id": t.id, "name": t.name, "date": t.date,
            "reminders": json.loads(t.reminders) if t.reminders else [],
            "notes": t.notes, "completed": t.completed, "priority": t.priority
        }
        for t in tasks
    ]


@app.post("/api/v1/tasks")
def add_task(
    name: str = Body(..., embed=True),
    date: str = Body(..., embed=True),
    reminders: list = Body([], embed=True),
    notes: str = Body("", embed=True),
    priority: str = Body("medium", embed=True),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = Task(
        user_id=current_user.id, name=name, date=date,
        reminders=json.dumps(reminders), notes=notes, priority=priority
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return {
        "id": task.id, "name": task.name, "date": task.date,
        "reminders": reminders, "notes": task.notes,
        "completed": task.completed, "priority": task.priority
    }


@app.post("/api/v1/tasks/{task_id}/toggle")
def toggle_task(
    task_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = db.query(Task).filter(Task.id == task_id, Task.user_id == current_user.id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    task.completed = not task.completed
    db.commit()
    return {"id": task.id, "completed": task.completed}


@app.delete("/api/v1/tasks/{task_id}")
def delete_task(
    task_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = db.query(Task).filter(Task.id == task_id, Task.user_id == current_user.id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    db.delete(task)
    db.commit()
    return {"status": "deleted"}


if __name__ == "__main__":
    import os
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
