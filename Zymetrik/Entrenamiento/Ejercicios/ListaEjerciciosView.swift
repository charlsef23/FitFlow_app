import SwiftUI

struct ListaEjerciciosView: View {
    let fecha: Date
    var onGuardar: ([Ejercicio]) -> Void
    
    @Binding var isPresented: Bool  // <- Aquí el cambio importante

    @State private var ejercicios: [Ejercicio] = []
    @State private var tipoSeleccionado: String = "Gimnasio"
    @State private var seleccionados: Set<UUID> = []

    private let tipos = ["Gimnasio", "Cardio", "Funcional"]
    @Namespace private var tipoAnimacion

    var ejerciciosFiltradosPorTipo: [String: [Ejercicio]] {
        Dictionary(grouping: ejercicios.filter { $0.tipo == tipoSeleccionado }) { $0.categoria }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Selector de tipo
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(tipos, id: \.self) { tipo in
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        tipoSeleccionado = tipo
                                    }
                                }) {
                                    ZStack {
                                        if tipoSeleccionado == tipo {
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(tipoGradient(for: tipo))
                                                .matchedGeometryEffect(id: "selector", in: tipoAnimacion)
                                                .frame(height: 38)
                                        } else {
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                                .background(Color(.systemGray6).cornerRadius(20))
                                                .frame(height: 38)
                                        }

                                        Text(tipo)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(tipoSeleccionado == tipo ? .white : .black)
                                            .padding(.horizontal, 20)
                                            .frame(height: 38)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Lista de ejercicios agrupada
                    LazyVStack(alignment: .leading, spacing: 32) {
                        ForEach(ejerciciosFiltradosPorTipo.sorted(by: { $0.key < $1.key }), id: \.key) { categoria, items in
                            VStack(alignment: .leading, spacing: 16) {
                                Text(categoria)
                                    .font(.title2.bold())
                                    .padding(.horizontal)

                                ForEach(items.sorted(by: { $0.nombre.localizedCaseInsensitiveCompare($1.nombre) == .orderedAscending })) { ejercicio in
                                    Button(action: {
                                        if seleccionados.contains(ejercicio.id) {
                                            seleccionados.remove(ejercicio.id)
                                        } else {
                                            seleccionados.insert(ejercicio.id)
                                        }
                                    }) {
                                        HStack(spacing: 16) {
                                            AsyncImage(url: URL(string: ejercicio.imagen_url ?? "")) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                        .frame(width: 70, height: 70)
                                                case .success(let image):
                                                    image.resizable()
                                                        .scaledToFill()
                                                case .failure:
                                                    Image(systemName: "photo")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .padding(20)
                                                        .foregroundColor(.gray)
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                            .frame(width: 70, height: 70)
                                            .background(Color.gray.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                            )

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(ejercicio.nombre)
                                                    .font(.headline)
                                                    .foregroundColor(.black)
                                                Text(ejercicio.descripcion)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(2)
                                            }

                                            Spacer()

                                            if seleccionados.contains(ejercicio.id) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding()
                                        .background(fondoTarjeta(for: tipoSeleccionado))
                                        .cornerRadius(20)
                                        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 3)
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Seleccionar ejercicios")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        let elegidos = ejercicios.filter { seleccionados.contains($0.id) }

                        guard !elegidos.isEmpty else {
                            print("⚠️ Nada seleccionado")
                            return
                        }

                        // Primero: actualiza la vista padre
                        onGuardar(elegidos)

                        // Segundo: cierra la hoja inmediatamente
                        isPresented = false

                        // Tercero: intenta guardar en Supabase (esto puede fallar y no afecta la interfaz)
                        Task {
                            do {
                                try await SupabaseService.shared.guardarEntrenamiento(fecha: fecha, ejercicios: elegidos)
                                print("✅ Entrenamiento guardado en Supabase")
                            } catch {
                                print("❌ Error Supabase (NO bloquea la vista):", error)
                            }
                        }
                    } label: {
                        Text("añadir")
                            .foregroundColor(.black) // ← TEXTO NEGRO
                    }
                }
            }
        }
        .onAppear {
            fetchEjercicios()
        }
    }

    func tipoGradient(for tipo: String) -> LinearGradient {
        switch tipo {
        case "Gimnasio":
            return LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
        case "Cardio":
            return LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange]), startPoint: .topLeading, endPoint: .bottomTrailing)
        case "Funcional":
            return LinearGradient(gradient: Gradient(colors: [Color.green, Color.teal]), startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(gradient: Gradient(colors: [.gray, .gray.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    func fondoTarjeta(for tipo: String) -> Color {
        switch tipo {
        case "Gimnasio":
            return Color.blue.opacity(0.1)
        case "Cardio":
            return Color.red.opacity(0.1)
        case "Funcional":
            return Color.green.opacity(0.1)
        default:
            return Color.gray.opacity(0.1)
        }
    }

    func fetchEjercicios() {
        Task {
            do {
                let response: [Ejercicio] = try await SupabaseManager.shared.client
                    .from("ejercicios")
                    .select()
                    .execute()
                    .value
                ejercicios = response
            } catch {
                print("❌ Error al cargar ejercicios:", error)
            }
        }
    }
}

