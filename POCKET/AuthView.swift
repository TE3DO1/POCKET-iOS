import SwiftUI
import FirebaseAuth

struct AuthGateView: View {
    @State private var user: User?
    @State private var isLoading = true
    @State private var showProfile = false
    @State private var listener: AuthStateDidChangeListenerHandle?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Зареждане на POCKET...")
            } else if let user = user {
                VStack(spacing: 0) {
                    HStack {
                        Text("POCKET")
                            .font(.headline)
                        Spacer()
                        Button {
                            showProfile = true
                        } label: {
                            Image(systemName: "person.crop.circle")
                                .font(.title2)
                        }
                    }
                    .padding()

                    EmeraldDashboardView()
                }
                .sheet(isPresented: $showProfile) {
                    NavigationStack {
                        Form {
                            Section("Моят профил") {
                                LabeledContent(
                                    "Имейл",
                                    value: user.email ?? "Няма имейл"
                                )
                            }

                            Section {
                                Button("Изход от акаунта",
                                       role: .destructive) {
                                    try? Auth.auth().signOut()
                                    showProfile = false
                                }
                            }
                        }
                        .navigationTitle("Профил")
                        .toolbar {
                            Button("Готово") {
                                showProfile = false
                            }
                        }
                    }
                }
            } else {
                AuthView()
            }
        }
        .onAppear {
            if listener == nil {
                listener = Auth.auth()
                    .addStateDidChangeListener { _, newUser in
                        DispatchQueue.main.async {
                            user = newUser
                            isLoading = false
                        }
                    }
            }
        }
        .onDisappear {
            if let listener {
                Auth.auth().removeStateDidChangeListener(listener)
                self.listener = nil
            }
        }
    }
}

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var isBusy = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "wallet.pass.fill")
                        .font(.system(size: 65))
                        .foregroundStyle(.blue)

                    Text("POCKET")
                        .font(.largeTitle.bold())

                    Text(isRegistering
                         ? "Създай своя акаунт"
                         : "Добре дошъл отново")
                        .foregroundStyle(.secondary)

                    TextField("Имейл адрес", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                    SecureField("Парола", text: $password)
                        .textContentType(
                            isRegistering ? .newPassword : .password
                        )
                        .textFieldStyle(.roundedBorder)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }

                    Button {
                        Task { await authenticate() }
                    } label: {
                        HStack {
                            if isBusy {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isRegistering
                                 ? "Регистрация" : "Вход")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        isBusy || email.isEmpty || password.isEmpty
                    )

                    Button(isRegistering
                           ? "Имаш акаунт? Влез"
                           : "Нямаш акаунт? Регистрирай се") {
                        isRegistering.toggle()
                        errorMessage = ""
                    }
                }
                .padding(24)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
        }
    }

    @MainActor
    private func authenticate() async {
        isBusy = true
        errorMessage = ""
        defer { isBusy = false }

        do {
            let cleanEmail = email.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            if isRegistering {
                _ = try await Auth.auth().createUser(
                    withEmail: cleanEmail,
                    password: password
                )
            } else {
                _ = try await Auth.auth().signIn(
                    withEmail: cleanEmail,
                    password: password
                )
            }

            password = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
