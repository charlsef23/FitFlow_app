import SwiftUI

struct BuscarView: View {
    @State private var searchText = ""
    @State private var seguidos: Set<String> = []

    let usuarios = ["gymbro", "entrena_con_lu", "ztrainer", "carlafit", "powerjuan", "carlosfit", "lauragym", "lucasstrong"]

    var usuariosFiltrados: [String] {
        searchText.isEmpty ? usuarios : usuarios.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 🔍 Barra de búsqueda
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Buscar usuarios", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)

                // 👤 Resultados
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(usuariosFiltrados, id: \.self) { usuario in
                            NavigationLink(destination: UserProfileView(username: usuario)) {
                                HStack(spacing: 14) {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 44, height: 44)
                                        .foregroundColor(.gray)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(usuario)
                                            .font(.headline)
                                        Text("Ver perfil")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()

                                    Button(action: {
                                        if seguidos.contains(usuario) {
                                            seguidos.remove(usuario)
                                        } else {
                                            seguidos.insert(usuario)
                                        }
                                    })  {
                                        Text(seguidos.contains(usuario) ? "Siguiendo" : "Seguir")
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 6)
                                            .background(seguidos.contains(usuario) ? Color(.systemGray5) : Color.black)
                                            .foregroundColor(seguidos.contains(usuario) ? .black : .white)
                                            .cornerRadius(20)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal)
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .padding(.leading, 72)
                        }
                    }
                }
            }
            .navigationTitle("Buscar")
        }
    }
}
