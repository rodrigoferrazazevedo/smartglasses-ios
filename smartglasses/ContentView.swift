import SwiftUI
import Vision
import PhotosUI

struct ContentView: View {
    @State private var inputImage: UIImage?
    @State private var recognizedText: String = "Nenhuma imagem selecionada."
    @State private var isShowingPhotoPicker = false
    @State private var isShowingCamera = false
    @State private var ocrHistory: [String] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let image = inputImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                        .cornerRadius(16)
                        .shadow(radius: 10)
                        .padding(.horizontal)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 200)
                        .overlay(Text("Nenhuma imagem").foregroundColor(.gray))
                        .padding(.horizontal)
                }

                HStack(spacing: 16) {
                    Button(action: { isShowingCamera = true }) {
                        Label("Câmera", systemImage: "camera")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Button(action: { isShowingPhotoPicker = true }) {
                        Label("Galeria", systemImage: "photo.on.rectangle")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                Button(action: {
                    if let image = inputImage {
                        recognizeText(from: image)
                    }
                }) {
                    Label("Fazer OCR", systemImage: "doc.text.viewfinder")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                ScrollView {
                    Text(recognizedText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding()
                }

                VStack(alignment: .leading) {
                    Text("Histórico de OCR")
                        .font(.headline)
                        .padding(.horizontal)

                    if ocrHistory.isEmpty {
                        Text("Nenhum histórico disponível.")
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    } else {
                        ForEach(ocrHistory.indices, id: \.self) { index in
                            Text(ocrHistory[index])
                                .padding()
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("Leitor OCR")
            .sheet(isPresented: $isShowingPhotoPicker) {
                PhotoPickerView(image: $inputImage)
            }
            .sheet(isPresented: $isShowingCamera) {
                CameraPickerView(image: $inputImage)
            }
        }
    }

    func recognizeText(from image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }

            let strings = observations.compactMap { $0.topCandidates(1).first?.string }
            DispatchQueue.main.async {
                ocrHistory.insert(strings.joined(separator: "\n"), at: 0)
                recognizedText = strings.joined(separator: "\n")
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}
