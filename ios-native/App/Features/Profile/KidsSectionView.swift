import ScrapLabModels
import SwiftUI

struct KidsSectionView: View {
    @Bindable var store: ChildProfilesStore
    let isAtLimit: Bool
    @State private var editingProfile: ChildProfile?
    @State private var isAddingNew = false

    var body: some View {
        VStack(alignment: .leading, spacing: SLSpacing.x3) {
            HStack {
                Text("Kid Profiles").font(SLFont.headline).foregroundStyle(SLColor.ink)
                Spacer()
                if isAtLimit {
                    MetadataChip(label: "Upgrade for more", systemImage: "sparkles")
                } else {
                    Button {
                        isAddingNew = true
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                    .font(SLFont.callout.weight(.semibold))
                    .foregroundStyle(SLColor.primaryPressed)
                }
            }

            if let actionError = store.actionError {
                Text(actionError).font(SLFont.caption).foregroundStyle(SLColor.coralText)
            }

            if store.childProfiles.isEmpty {
                Text("Add a profile so recommendations match your child's age.")
                    .font(SLFont.callout)
                    .foregroundStyle(SLColor.bodyText)
            } else {
                ForEach(store.childProfiles, id: \.id) { profile in
                    Button {
                        editingProfile = profile
                    } label: {
                        row(for: profile)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(SLSpacing.x4)
        .background(SLColor.surface, in: RoundedRectangle(cornerRadius: SLRadius.largeCard))
        .slShadow()
        .sheet(isPresented: $isAddingNew) {
            ChildProfileFormView(profile: nil) { name, age in
                await store.add(name: name, age: age)
            }
        }
        .sheet(item: $editingProfile) { profile in
            ChildProfileFormView(profile: profile, onDelete: {
                Task { await store.delete(profile) }
            }) { name, age in
                await store.update(profile, name: name, age: age)
            }
        }
    }

    private func row(for profile: ChildProfile) -> some View {
        HStack {
            Circle().fill(SLColor.cream100).frame(width: 36, height: 36)
                .overlay(Text((profile.name?.first).map(String.init) ?? "?").font(SLFont.headline))
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name ?? "Unnamed").font(SLFont.body).foregroundStyle(SLColor.ink)
                Text("\(profile.age) years old").font(SLFont.caption).foregroundStyle(SLColor.bodyText)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(SLColor.mutedText)
        }
    }
}

extension ChildProfile: Identifiable {}

private struct ChildProfileFormView: View {
    let profile: ChildProfile?
    var onDelete: (() -> Void)?
    let onSave: (String?, Int) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var age: Int
    @State private var isConfirmingDelete = false

    init(profile: ChildProfile?, onDelete: (() -> Void)? = nil, onSave: @escaping (String?, Int) async -> Void) {
        self.profile = profile
        self.onDelete = onDelete
        self.onSave = onSave
        _name = State(initialValue: profile?.name ?? "")
        _age = State(initialValue: profile?.age ?? 6)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name (optional)") {
                    TextField("First name", text: $name)
                }
                Section("Age") {
                    Picker("Age", selection: $age) {
                        ForEach(OnboardingChildProfileBuilder.allowedAgeRange, id: \.self) { value in
                            Text("\(value) years").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                if profile != nil {
                    Section {
                        if isConfirmingDelete {
                            HStack {
                                Text("Remove \(name.isEmpty ? "this profile" : name)?")
                                Spacer()
                                Button("Yes") {
                                    onDelete?()
                                    dismiss()
                                }
                                .foregroundStyle(SLColor.coralText)
                                Button("No") { isConfirmingDelete = false }
                            }
                        } else {
                            Button("Remove profile", role: .destructive) { isConfirmingDelete = true }
                        }
                    }
                }
            }
            .navigationTitle(profile == nil ? "Add Kid Profile" : "Edit Kid Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await onSave(name.isEmpty ? nil : name, age)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
