import AVFoundation
import SwiftUI
import UIKit

/// The camera's state for the UI. Session work happens on `CaptureSessionWorker`'s own queue.
@Observable
final class CameraController {
    enum Status {
        /// Still checking permission or setting up.
        case starting
        /// No camera, e.g. the Simulator. The UI falls back to a drawn placeholder.
        case unavailable
        case denied
        case ready
        case failed
    }

    private(set) var status: Status = .starting
    private(set) var hasFlash = false
    var isFlashOn = false

    @ObservationIgnored let worker = CaptureSessionWorker()

    func start() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            guard await AVCaptureDevice.requestAccess(for: .video) else {
                status = .denied
                return
            }
        default:
            status = .denied
            return
        }

        switch await worker.configureAndStart() {
        case .noCamera: status = .unavailable
        case .failed: status = .failed
        case .running(let flash):
            hasFlash = flash
            status = .ready
        }
    }

    func stop() {
        worker.stop()
    }

    func capturePhoto() async throws -> UIImage {
        let data = try await worker.capturePhoto(flash: hasFlash && isFlashOn)
        guard let image = UIImage(data: data) else { throw CocoaError(.fileReadCorruptFile) }
        return image
    }

    func focus(at devicePoint: CGPoint) {
        worker.focus(at: devicePoint)
    }
}

/// Owns the AVFoundation objects and touches them only on its serial queue.
nonisolated final class CaptureSessionWorker: @unchecked Sendable {
    enum SetupResult: Sendable {
        case running(hasFlash: Bool)
        case noCamera
        case failed
    }

    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "MoveInProof.camera")
    private var device: AVCaptureDevice?
    private var isConfigured = false
    private var inFlight: [Int64: PhotoCaptureDelegate] = [:]

    func configureAndStart() async -> SetupResult {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.configureIfNeeded())
                if self.isConfigured, !self.session.isRunning {
                    self.session.startRunning()
                }
            }
        }
    }

    func stop() {
        queue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    func capturePhoto(flash: Bool) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let settings = AVCapturePhotoSettings()
                if flash, self.output.supportedFlashModes.contains(.on) {
                    settings.flashMode = .on
                }
                let id = settings.uniqueID
                let delegate = PhotoCaptureDelegate { result in
                    continuation.resume(with: result)
                    self.queue.async { self.inFlight[id] = nil }
                }
                self.inFlight[id] = delegate
                if let connection = self.output.connection(with: .video), connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
                self.output.capturePhoto(with: settings, delegate: delegate)
            }
        }
    }

    func focus(at devicePoint: CGPoint) {
        queue.async {
            guard let device = self.device, (try? device.lockForConfiguration()) != nil else { return }
            defer { device.unlockForConfiguration() }
            if device.isFocusPointOfInterestSupported, device.isFocusModeSupported(.autoFocus) {
                device.focusPointOfInterest = devicePoint
                device.focusMode = .autoFocus
            }
            if device.isExposurePointOfInterestSupported, device.isExposureModeSupported(.autoExpose) {
                device.exposurePointOfInterest = devicePoint
                device.exposureMode = .autoExpose
            }
        }
    }

    private func configureIfNeeded() -> SetupResult {
        if isConfigured { return .running(hasFlash: device?.hasFlash ?? false) }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            return .noCamera
        }
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .photo

        guard let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input), session.canAddOutput(output) else {
            return .failed
        }
        session.addInput(input)
        session.addOutput(output)
        output.maxPhotoQualityPrioritization = .quality

        self.device = device
        isConfigured = true
        return .running(hasFlash: device.hasFlash)
    }
}

nonisolated private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    private let completion: (Result<Data, Error>) -> Void

    init(completion: @escaping (Result<Data, Error>) -> Void) {
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            completion(.failure(error))
        } else if let data = photo.fileDataRepresentation() {
            completion(.success(data))
        } else {
            completion(.failure(CocoaError(.fileReadCorruptFile)))
        }
    }
}

/// Live camera feed. Tapping reports the point in camera coordinates (for focus) and in view coordinates (for the focus ring).
struct CameraPreview: UIViewRepresentable {
    var session: AVCaptureSession
    var onTap: (_ devicePoint: CGPoint, _ viewPoint: CGPoint) -> Void

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        if let connection = view.previewLayer.connection, connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        view.onTap = onTap
        return view
    }

    func updateUIView(_ view: PreviewView, context: Context) {
        view.onTap = onTap
    }

    final class PreviewView: UIView {
        var onTap: ((CGPoint, CGPoint) -> Void)?

        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .black
            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

        @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
            let point = recognizer.location(in: self)
            onTap?(previewLayer.captureDevicePointConverted(fromLayerPoint: point), point)
        }
    }
}
