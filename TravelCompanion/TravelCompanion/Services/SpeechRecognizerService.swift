import Foundation
import Speech
import AVFoundation

/// Protocollo delegato per gli eventi del riconoscimento vocale
protocol SpeechRecognizerDelegate: AnyObject {
    func speechRecognizer(_ service: SpeechRecognizerService, didReceivePartialResult text: String)
    func speechRecognizer(_ service: SpeechRecognizerService, didReceiveFinalResult text: String)
    func speechRecognizer(_ service: SpeechRecognizerService, didFailWithError error: SpeechRecognizerError)
    func speechRecognizerDidStartListening(_ service: SpeechRecognizerService)
    func speechRecognizerDidStopListening(_ service: SpeechRecognizerService)
}

/// Errori del servizio di riconoscimento vocale
enum SpeechRecognizerError: LocalizedError {
    case notAuthorized
    case notAvailable
    case audioEngineError
    case recognitionFailed
    case noMicrophoneAccess
    case alreadyRecording
    case notRecording
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Autorizzazione al riconoscimento vocale negata"
        case .notAvailable:
            return "Riconoscimento vocale non disponibile"
        case .audioEngineError:
            return "Errore nel motore audio"
        case .recognitionFailed:
            return "Riconoscimento vocale fallito"
        case .noMicrophoneAccess:
            return "Accesso al microfono negato"
        case .alreadyRecording:
            return "Registrazione gia in corso"
        case .notRecording:
            return "Nessuna registrazione attiva"
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    var userMessage: String {
        switch self {
        case .notAuthorized:
            return "Per usare le note vocali, autorizza il riconoscimento vocale nelle Impostazioni."
        case .notAvailable:
            return "Il riconoscimento vocale non e disponibile su questo dispositivo."
        case .audioEngineError:
            return "Si e verificato un problema con il microfono. Riprova."
        case .recognitionFailed:
            return "Non sono riuscito a capire. Parla piu chiaramente e riprova."
        case .noMicrophoneAccess:
            return "Per usare le note vocali, autorizza l'accesso al microfono nelle Impostazioni."
        case .alreadyRecording:
            return "Una registrazione e gia in corso."
        case .notRecording:
            return "Nessuna registrazione attiva."
        case .unknown:
            return "Si e verificato un errore. Riprova."
        }
    }
}

/// Stato dell'autorizzazione vocale
enum SpeechAuthorizationStatus {
    case authorized
    case denied
    case restricted
    case notDetermined
}

/// Servizio per il riconoscimento vocale usando SFSpeechRecognizer
final class SpeechRecognizerService: NSObject {

    // MARK: - Singleton

    static let shared = SpeechRecognizerService()

    // MARK: - Properties

    weak var delegate: SpeechRecognizerDelegate?

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private var isListening = false
    private var lastTranscription = ""

    /// Indica se il servizio sta ascoltando
    var isRecording: Bool {
        return isListening
    }

    /// Verifica se il riconoscimento vocale e disponibile
    var isAvailable: Bool {
        return speechRecognizer?.isAvailable ?? false
    }

    /// Verifica se supporta il riconoscimento offline
    var supportsOfflineRecognition: Bool {
        if #available(iOS 13.0, *) {
            return speechRecognizer?.supportsOnDeviceRecognition ?? false
        }
        return false
    }

    // MARK: - Initialization

    private override init() {
        // Usa italiano come lingua primaria
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "it-IT"))
        super.init()

        speechRecognizer?.delegate = self
    }

    // MARK: - Authorization

    /// Verifica lo stato dell'autorizzazione
    func checkAuthorizationStatus() -> SpeechAuthorizationStatus {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    /// Richiede l'autorizzazione per il riconoscimento vocale
    func requestAuthorization(completion: @escaping (SpeechAuthorizationStatus) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    completion(.authorized)
                case .denied:
                    completion(.denied)
                case .restricted:
                    completion(.restricted)
                case .notDetermined:
                    completion(.notDetermined)
                @unknown default:
                    completion(.notDetermined)
                }
            }
        }
    }

    /// Verifica l'autorizzazione al microfono
    func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }

    /// Richiede tutte le autorizzazioni necessarie
    func requestAllPermissions(completion: @escaping (Bool, SpeechRecognizerError?) -> Void) {
        // Prima richiedi l'autorizzazione al microfono
        checkMicrophonePermission { [weak self] micGranted in
            guard micGranted else {
                completion(false, .noMicrophoneAccess)
                return
            }

            // Poi richiedi l'autorizzazione al riconoscimento vocale
            self?.requestAuthorization { status in
                switch status {
                case .authorized:
                    completion(true, nil)
                case .denied, .restricted:
                    completion(false, .notAuthorized)
                case .notDetermined:
                    completion(false, .notAuthorized)
                }
            }
        }
    }

    // MARK: - Recording

    /// Avvia la registrazione e il riconoscimento vocale
    func startListening() throws {
        // Verifica autorizzazione
        guard checkAuthorizationStatus() == .authorized else {
            throw SpeechRecognizerError.notAuthorized
        }

        // Verifica disponibilita
        guard isAvailable else {
            throw SpeechRecognizerError.notAvailable
        }

        // Verifica che non sia gia in ascolto
        guard !isListening else {
            throw SpeechRecognizerError.alreadyRecording
        }

        // Cancella task precedente
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }

        // Configura sessione audio
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Crea richiesta di riconoscimento
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognizerError.audioEngineError
        }

        // Configura per risultati parziali
        recognitionRequest.shouldReportPartialResults = true

        // Usa riconoscimento on-device se disponibile
        if #available(iOS 13.0, *), supportsOfflineRecognition {
            recognitionRequest.requiresOnDeviceRecognition = true
        }

        // Configura input node
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        // Avvia task di riconoscimento
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            var isFinal = false

            if let result = result {
                let transcription = result.bestTranscription.formattedString
                self.lastTranscription = transcription
                isFinal = result.isFinal

                DispatchQueue.main.async {
                    if isFinal {
                        self.delegate?.speechRecognizer(self, didReceiveFinalResult: transcription)
                    } else {
                        self.delegate?.speechRecognizer(self, didReceivePartialResult: transcription)
                    }
                }
            }

            if error != nil || isFinal {
                self.stopAudioEngine()

                if let error = error, !isFinal {
                    DispatchQueue.main.async {
                        self.delegate?.speechRecognizer(self, didFailWithError: .unknown(error))
                    }
                }
            }
        }

        // Avvia audio engine
        audioEngine.prepare()
        try audioEngine.start()

        isListening = true
        lastTranscription = ""

        DispatchQueue.main.async {
            self.delegate?.speechRecognizerDidStartListening(self)
        }
    }

    /// Ferma la registrazione e il riconoscimento
    func stopListening() {
        guard isListening else { return }

        stopAudioEngine()

        // Se abbiamo una trascrizione finale, notifica
        if !lastTranscription.isEmpty {
            DispatchQueue.main.async {
                self.delegate?.speechRecognizer(self, didReceiveFinalResult: self.lastTranscription)
            }
        }
    }

    /// Ferma forzatamente senza notificare risultato finale
    func cancelListening() {
        guard isListening else { return }

        recognitionTask?.cancel()
        stopAudioEngine()
    }

    // MARK: - Private Methods

    private func stopAudioEngine() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil

        isListening = false

        // Disattiva sessione audio
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        DispatchQueue.main.async {
            self.delegate?.speechRecognizerDidStopListening(self)
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension SpeechRecognizerService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        #if DEBUG
        print("SpeechRecognizerService: Availability changed to \(available)")
        #endif

        if !available && isListening {
            stopListening()
            DispatchQueue.main.async {
                self.delegate?.speechRecognizer(self, didFailWithError: .notAvailable)
            }
        }
    }
}
