import argparse
import os
import urllib.request

import cv2

MODEL_URL = (
    "https://github.com/opencv/opencv_zoo/raw/main/models/"
    "face_detection_yunet/face_detection_yunet_2023mar.onnx"
)
MODEL_PATH = os.path.join("models", "face_detection_yunet_2023mar.onnx")


def ensure_model():
    """Download the YuNet model on first run."""
    if not os.path.exists(MODEL_PATH):
        os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)
        print(f"Downloading face detection model to {MODEL_PATH}...")
        urllib.request.urlretrieve(MODEL_URL, MODEL_PATH)
    return MODEL_PATH


def create_detector(score_threshold=0.5):
    return cv2.FaceDetectorYN.create(
        ensure_model(),
        "",
        (320, 320),  # placeholder; updated per frame
        score_threshold,
        0.3,   # NMS threshold
        5000,  # top_k
    )


def blur_faces(img, detector):
    """Detect faces in a BGR image and blur them in place."""
    h_img, w_img = img.shape[:2]
    detector.setInputSize((w_img, h_img))
    _, faces = detector.detect(img)  # YuNet takes BGR directly

    if faces is None:
        return img

    for face_info in faces:
        x, y, w, h = face_info[:4]

        # Clamp to image bounds
        x1 = max(int(x), 0)
        y1 = max(int(y), 0)
        x2 = min(int(x + w), w_img)
        y2 = min(int(y + h), h_img)

        if x2 <= x1 or y2 <= y1:
            continue

        face = img[y1:y2, x1:x2]

        # Kernel size scales with face size; must be odd
        k = max(3, (min(face.shape[:2]) // 3) | 1)
        img[y1:y2, x1:x2] = cv2.GaussianBlur(face, (k, k), 0)

    return img


def process_image(path, output_dir, detector):
    img = cv2.imread(path)
    if img is None:
        raise FileNotFoundError(f"Could not read image: {path}")

    img = blur_faces(img, detector)
    out_path = os.path.join(output_dir, "output.png")
    cv2.imwrite(out_path, img)
    print(f"Saved {out_path}")


def process_video(path, output_dir, detector):
    cap = cv2.VideoCapture(path)
    ret, frame = cap.read()
    if not ret:
        raise FileNotFoundError(f"Could not read video: {path}")

    fps = cap.get(cv2.CAP_PROP_FPS) or 25
    h, w = frame.shape[:2]
    out_path = os.path.join(output_dir, "output.mp4")
    writer = cv2.VideoWriter(out_path, cv2.VideoWriter_fourcc(*"mp4v"), fps, (w, h))

    try:
        while ret:
            writer.write(blur_faces(frame, detector))
            ret, frame = cap.read()
    finally:
        cap.release()
        writer.release()
    print(f"Saved {out_path}")


def process_webcam(detector):
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        raise RuntimeError("Could not open webcam")

    try:
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            cv2.imshow("Face blur (press q to quit)", blur_faces(frame, detector))
            if cv2.waitKey(1) & 0xFF == ord("q"):
                break
    finally:
        cap.release()
        cv2.destroyAllWindows()


def main():
    parser = argparse.ArgumentParser(description="Blur faces in images, videos or webcam.")
    parser.add_argument("--mode", choices=["image", "video", "webcam"], default="webcam")
    parser.add_argument("--filePath", help="Input file (required for image/video modes)")
    args = parser.parse_args()

    if args.mode in ("image", "video") and not args.filePath:
        parser.error(f"--filePath is required in {args.mode} mode")

    output_dir = "./output"
    os.makedirs(output_dir, exist_ok=True)

    detector = create_detector(score_threshold=0.5)

    if args.mode == "image":
        process_image(args.filePath, output_dir, detector)
    elif args.mode == "video":
        process_video(args.filePath, output_dir, detector)
    else:
        process_webcam(detector)


if __name__ == "__main__":
    main()