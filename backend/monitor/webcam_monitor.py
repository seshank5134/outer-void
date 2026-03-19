import cv2
import threading
import time

class WebcamMonitor:
    def __init__(self):
        self.is_monitoring = False
        self.lock = threading.Lock()
        
        # State variables for fatigue detection
        self.blink_count = 0
        self.yawn_count = 0 
        self.eye_closed_frames = 0
        self.head_nod_frames = 0
        
        self.is_drowsy = False
        self.face_visible = False
        
        # Thresholds
        self.EYES_CLOSED_FRAMES = 10    # Frames to trigger drowsiness warning
        
        self.cap = None
        self.thread = None
        self.latest_jpeg = None
        
        # Load OpenCV native Haar cascades for face and eye tracking
        self.face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        self.eye_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_eye_tree_eyeglasses.xml')

    def start(self):
        if self.is_monitoring: return
        self.is_monitoring = True
        self.thread = threading.Thread(target=self._process_video, daemon=True)
        self.thread.start()
        print("Webcam Object Detection (CV2 Cascade) monitoring started...")

    def stop(self):
        self.is_monitoring = False
        if self.thread is not None:
            self.thread.join(timeout=2)
        if self.cap is not None:
            self.cap.release()
        print("Webcam Monitoring stopped.")

    def _process_video(self):
        self.cap = cv2.VideoCapture(0)
        if not self.cap.isOpened():
            print("Warning: Could not open default webcam (0). WebCam Monitor inactive.")
            return

        while self.is_monitoring:
            success, image = self.cap.read()
            if not success:
                time.sleep(0.1)
                continue

            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            
            with self.lock:
                faces = self.face_cascade.detectMultiScale(gray, 1.3, 5)
                if len(faces) > 0:
                    self.face_visible = True
                    # Grab the largest face
                    (x,y,w,h) = max(faces, key=lambda f: f[2]*f[3])
                    cv2.rectangle(image, (x, y), (x+w, y+h), (0, 255, 0), 2)
                    cv2.putText(image, "Face Detected", (x, y-10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 1)
                    roi_gray = gray[y:y+h, x:x+w]
                    roi_color = image[y:y+h, x:x+w]
                    
                    # Detect eyes within the face
                    eyes = self.eye_cascade.detectMultiScale(roi_gray, 1.1, 3)
                    
                    for (ex, ey, ew, eh) in eyes:
                        cv2.rectangle(roi_color, (ex, ey), (ex+ew, ey+eh), (255, 0, 0), 2)
                    
                    if len(eyes) == 0:
                        # Eyes not found -> likely closed or looking away heavily
                        self.eye_closed_frames += 1
                    else:
                        if self.eye_closed_frames > 2 and self.eye_closed_frames < self.EYES_CLOSED_FRAMES:
                            self.blink_count += 1
                        if self.eye_closed_frames >= self.EYES_CLOSED_FRAMES:
                            self.is_drowsy = True
                        else:
                            self.is_drowsy = False
                        self.eye_closed_frames = 0
                        
                    # Basic head nod detection based on vertical face position
                    if y > (image.shape[0] * 0.6): # Face is very low in the frame
                        self.head_nod_frames += 1
                    else:
                        self.head_nod_frames = 0
                        
                else:
                    self.face_visible = False
                    self.is_drowsy = False
                    self.eye_closed_frames = 0
                    cv2.putText(image, "NO FACE DETECTED", (30, 50), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
                    
                if self.is_drowsy:
                    cv2.putText(image, "DROWSINESS DETECTED!", (30, 80), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)

                # Store the annotated frame safely for FastAPI stream
                ret, jpeg = cv2.imencode('.jpg', image)
                if ret:
                    self.latest_jpeg = jpeg.tobytes()

            # Sleep ~30fps
            time.sleep(0.033)
            
        self.cap.release()

    def get_frame(self):
        with self.lock:
            return self.latest_jpeg

    def get_metrics(self):
        with self.lock:
            metrics = {
                "face_visible": self.face_visible,
                "is_drowsy": self.is_drowsy,
                "blinks": self.blink_count,
                "yawns": self.yawn_count, # Mocked for haarcascade unless we add a mouth cascade
                "head_nodding": self.head_nod_frames > 15,
                "timestamp": time.time()
            }
            # Reset
            self.blink_count = 0
            self.yawn_count = 0
            return metrics
