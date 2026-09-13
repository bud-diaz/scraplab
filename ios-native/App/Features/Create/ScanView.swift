import PhotosUI
import ScrapLabModels
import SwiftUI

struct ScanView: View {
    @Bindable var session: SessionStore
    @Bindable var router: AppRouter
    @State private var store: ScanStore
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isShowingCamera = false

    init(baseURL: URL, session: SessionStore, router: AppRouter) {
        self.session = session
        self.router = router
        _store = State(initialValue: ScanStore(baseURL: baseURL, session: session))
    }

    var body: some View {
        Group {
            if !session.isAuthenticated {
                GuestSignInNudge(title: "Scan Materials", message: "Sign in and upgrade to Plus to scan your materials instantly.") {
                    router.presentedSheet = .signIn
                }
            } else {
                content
            }
        }
        .navigationTitle("Scan Materials")
        .navigationBarTitleDisplayMode(.inline)
        .background(SLColor.pageBackground)
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraCapture { image in
                Task { await store.upload(image) }
            }
            .ignoresSafeArea()
        }
        .onChange(of: photoPickerItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    await store.upload(image)
                }
                photoPickerItem = nil
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: SLSpacing.x4) {
                preview
                if case .detected(let materials) = store.phase {
                    detectedList(materials)
                }
                if case .failed(let message) = store.phase {
                    Text(message).font(SLFont.callout).foregroundStyle(SLColor.coralText).multilineTextAlignment(.center)
                }
                if store.phase != .scanning {
                    actionButtons
                }
                if case .planGate(let message) = store.phase {
                    UpgradeCard(title: "Material Scanner", message: message) {}
                }
            }
            .padding(SLSpacing.x4)
        }
    }

    @ViewBuilder
    private var preview: some View {
        RoundedRectangle(cornerRadius: SLRadius.largeCard)
            .fill(SLColor.surface)
            .frame(height: 224)
            .overlay {
                if let data = store.previewImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 224)
                        .clipShape(RoundedRectangle(cornerRadius: SLRadius.largeCard))
                        .overlay {
                            if store.phase == .scanning {
                                ZStack {
                                    Color.black.opacity(0.4)
                                    VStack(spacing: SLSpacing.x2) {
                                        ProgressView().tint(.white)
                                        Text("Scanning…").foregroundStyle(.white).font(SLFont.callout)
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: SLRadius.largeCard))
                            }
                        }
                } else {
                    VStack(spacing: SLSpacing.x2) {
                        Image(systemName: "camera.fill").font(.title).foregroundStyle(SLColor.mutedText)
                        Text("Take or upload a photo of your materials").font(SLFont.callout).foregroundStyle(SLColor.bodyText)
                    }
                }
            }
    }

    @ViewBuilder
    private func detectedList(_ materials: [DetectedMaterial]) -> some View {
        VStack(alignment: .leading, spacing: SLSpacing.x2) {
            Label(
                materials.isEmpty ? "No materials detected" : "Found \(materials.count) material\(materials.count == 1 ? "" : "s")",
                systemImage: "checkmark.seal.fill"
            )
            .font(SLFont.headline)
            .foregroundStyle(SLColor.ink)

            if materials.isEmpty {
                Text("Try a clearer photo with better lighting.").font(SLFont.callout).foregroundStyle(SLColor.bodyText)
            } else {
                ForEach(materials, id: \.materialId) { material in
                    HStack {
                        Text(material.label).font(SLFont.body).foregroundStyle(SLColor.ink)
                        Spacer()
                        Text("\(Int((material.confidence * 100).rounded()))% sure").font(SLFont.caption).foregroundStyle(SLColor.mutedText)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SLSpacing.x4)
        .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.largeCard))
        .slShadow()
    }

    @ViewBuilder
    private var actionButtons: some View {
        if case .detected(let materials) = store.phase {
            HStack(spacing: SLSpacing.x3) {
                Button("Try Another") { store.reset() }
                    .buttonStyle(.scrapLab(.secondary))
                if !materials.isEmpty {
                    NavigationLink(value: CreateRoute.results(materialIDs: materials.map(\.materialId), childAge: CreateAge.scanDefault)) {
                        Text("Find Builds")
                    }
                    .buttonStyle(.scrapLab())
                }
            }
        } else {
            HStack(spacing: SLSpacing.x3) {
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Text("Upload Photo")
                }
                .buttonStyle(.scrapLab(.secondary))
                Button("Use Camera") { isShowingCamera = true }
                    .buttonStyle(.scrapLab(.secondary))
            }
        }
    }
}
