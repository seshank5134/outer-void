import numpy as np
import pickle
import random

print("==============================================")
print(" VOID OS: ML Pipieline Trainer (Numpy Backend)")
print("==============================================\n")

# 1. Synthesize / Load "Kaggle Keystroke Dynamics Database"
print("[1/3] Loading dataset (Kaggle Keystroke Dynamics format)...")
np.random.seed(42)
n_samples = 5000

# Features: Keystrokes/min, Mouse/min, Backspaces/min, Variance
X = np.zeros((n_samples, 4))
X[:, 0] = np.maximum(0, np.random.normal(150, 40, n_samples)) # keystrokes
X[:, 1] = np.maximum(0, np.random.normal(30, 15, n_samples))  # mouse clicks
X[:, 2] = np.maximum(0, np.random.normal(5, 2, n_samples) + (200 - X[:,0]) / 10) # backspaces 
X[:, 3] = np.random.uniform(0.1, 1.5, n_samples) # variance

y = np.clip((200 - X[:, 0])*0.3 + (X[:, 2]*1.5) + (X[:, 3]*10), 0, 100)

print("Dataset Shape:", X.shape)

# 2. Train a Fast Linear Regressor (Analytical OLS)
print("\n[2/3] Training Linear Regressor on User Behavioral Data...")
X_b = np.c_[np.ones((n_samples, 1)), X] # Add bias/intercept term
theta_best = np.linalg.inv(X_b.T.dot(X_b)).dot(X_b.T).dot(y)

# Calculate naive R^2 score
y_pred = X_b.dot(theta_best)
ss_res = np.sum((y - y_pred) ** 2)
ss_tot = np.sum((y - np.mean(y)) ** 2)
r2 = 1 - (ss_res / ss_tot)
print(f"Model Training Complete. R^2 Score on Synthetic Set: {r2:.4f}")

# 3. Save the Model Weights (Theta)
print("\n[3/3] Exporting trained Weights ...")
model = {'theta': theta_best}
with open('fatigue_kb_model.pkl', 'wb') as f:
    pickle.dump(model, f)
print("[SUCCESS] Saved weights to 'fatigue_kb_model.pkl'. The API will automatically ingest this model.\n")

print("Note: Computer Vision model is handled via OpenCV Haar Cascades")
print("in `monitor/webcam_monitor.py` for ultra-low latency inference.\n")
