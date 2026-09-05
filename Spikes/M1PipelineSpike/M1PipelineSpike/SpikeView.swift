import SwiftUI

struct SpikeView: View {
    @State private var model = SpikeModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Disposable feasibility harness — not product UI")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    cameraSection
                    controls
                    statusSection

                    if let report = model.report {
                        evidenceSection(report)
                    }

                    if let outputPreview = model.outputPreview {
                        Image(uiImage: outputPreview)
                            .resizable()
                            .scaledToFit()
                            .accessibilityLabel("Core Image composited M1 export preview")
                    }
                }
                .padding()
            }
            .navigationTitle("M1 Pipeline Spike")
        }
    }

    @ViewBuilder
    private var cameraSection: some View {
        switch model.state {
        case .idle, .startingCamera:
            ContentUnavailableView(
                "Camera not started",
                systemImage: "camera",
                description: Text("Permission is requested only after Start Camera is selected.")
            )
            .frame(minHeight: 320)
        default:
            CameraPreview(
                session: model.camera.captureSession,
                onFirstPreviewFrame: model.noteFirstPreviewFrame
            )
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .clipShape(.rect(cornerRadius: 16))
            .accessibilityLabel("Live rear camera preview")
        }
    }

    private var controls: some View {
        HStack {
            Button("Start Camera", systemImage: "camera.fill") {
                Task { await model.startCamera() }
            }
            .disabled(!model.canStartCamera)

            Button("Capture + Run M1", systemImage: "bolt.fill") {
                Task { await model.captureAndRunPipeline() }
            }
            .disabled(!model.canCapture)
        }
        .buttonStyle(.borderedProminent)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.state.title)
                .font(.headline)
                .accessibilityLabel("Pipeline status: \(model.state.title)")

            if let start = model.cameraStartEvidence {
                metric("Session start", start.sessionStartMilliseconds, suffix: " ms")
                Text("Requested capture: \(start.requestedPhotoWidth)×\(start.requestedPhotoHeight)")
                    .font(.caption.monospacedDigit())
            }
            if let preview = model.cameraEntryToPreviewMilliseconds {
                metric("Entry → preview rendering", preview, suffix: " ms")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func evidenceSection(_ report: SpikeRunReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("On-device evidence")
                .font(.title3.weight(.semibold))

            Text("Device: \(report.hardwareIdentifier) — \(report.operatingSystem)")
            Text("Resolved still: \(report.resolvedCaptureWidth)×\(report.resolvedCaptureHeight)")
            Text("Faces detected: \(report.faceCount)")
            metric("Face detection", report.faceDetectionMilliseconds, suffix: " ms")
            metric("Person segmentation", report.personSegmentationMilliseconds, suffix: " ms")
            Text("Iterative segmentation: \(report.iterativeSegmentationStatus)")
            metric("Render + JPEG + reopen", report.renderAndExportMilliseconds, suffix: " ms")

            let verification = report.exportVerification
            Text("Reopened export: \(verification.width)×\(verification.height), \(verification.typeIdentifier)")
            Text("GPS metadata present: \(verification.containsGPSMetadata ? "YES — FAIL" : "No")")
            Text(verification.passed ? "Exact-export verification: PASS" : "Exact-export verification: FAIL")
                .font(.headline)

            if let exportURL = model.exportURL {
                ShareLink(item: exportURL) {
                    Label("Share verified JPEG", systemImage: "square.and.arrow.up")
                }
            }
            if let reportURL = model.reportURL {
                ShareLink(item: reportURL) {
                    Label("Share JSON evidence", systemImage: "doc.text")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metric(_ label: String, _ value: Double, suffix: String) -> some View {
        Text("\(label): \(value, format: .number.precision(.fractionLength(1)))\(suffix)")
            .font(.caption.monospacedDigit())
    }
}
