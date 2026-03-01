from sqlalchemy import (
    create_engine, Column, Integer, String, Boolean, Float,
    DateTime, ForeignKey, Text
)
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from datetime import datetime

DATABASE_URL = "sqlite:///./void_os.db"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    habits = relationship("Habit", back_populates="owner", cascade="all, delete")
    tasks = relationship("Task", back_populates="owner", cascade="all, delete")
    preferences = relationship("UserPreferences", back_populates="owner", uselist=False, cascade="all, delete")


class Habit(Base):
    __tablename__ = "habits"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)
    icon = Column(String, default="circle")
    color = Column(String, default="0xFFF44336")
    reminder = Column(String, default="09:00")
    category = Column(String, default="general")
    description = Column(Text, default="")
    created_at = Column(DateTime, default=datetime.utcnow)

    owner = relationship("User", back_populates="habits")
    logs = relationship("HabitLog", back_populates="habit", cascade="all, delete")


class HabitLog(Base):
    __tablename__ = "habit_logs"
    id = Column(Integer, primary_key=True, index=True)
    habit_id = Column(Integer, ForeignKey("habits.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    date = Column(String, nullable=False)  # YYYY-MM-DD
    completed = Column(Boolean, default=False)

    habit = relationship("Habit", back_populates="logs")


class Task(Base):
    __tablename__ = "tasks"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)
    date = Column(String, nullable=False)
    reminders = Column(String, default="")  # JSON string
    notes = Column(Text, default="")
    completed = Column(Boolean, default=False)
    priority = Column(String, default="medium")  # low, medium, high
    created_at = Column(DateTime, default=datetime.utcnow)

    owner = relationship("User", back_populates="tasks")


class UserPreferences(Base):
    __tablename__ = "user_preferences"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)

    # Pomodoro Settings
    pomodoro_work_mins = Column(Integer, default=25)
    pomodoro_break_mins = Column(Integer, default=5)
    pomodoro_long_break_mins = Column(Integer, default=15)
    pomodoro_sessions_before_long_break = Column(Integer, default=4)

    # Theme Settings
    theme_name = Column(String, default="void_red")     # void_red, space_blue, forest_green, solar_gold, nebula_purple
    accent_color = Column(String, default="0xFFEF4444")
    bg_gradient_start = Column(String, default="0xFF0A0A0A")
    bg_gradient_end = Column(String, default="0xFF1A0A0A")
    glass_opacity = Column(Float, default=0.08)

    # Widget / UI Settings
    ui_font_scale = Column(Float, default=1.0)        # 0.8x to 1.4x
    sidebar_width = Column(Integer, default=280)      # 200 to 340
    card_border_radius = Column(Integer, default=16)  # 0 to 32
    show_animations = Column(Boolean, default=True)
    compact_mode = Column(Boolean, default=False)

    owner = relationship("User", back_populates="preferences")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    Base.metadata.create_all(bind=engine)
