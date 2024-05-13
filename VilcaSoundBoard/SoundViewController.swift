import UIKit
import AVFoundation

class SoundViewController: UIViewController, AVAudioRecorderDelegate {
    
    @IBOutlet weak var grabarButton: UIButton!
    @IBOutlet weak var reproducirButton: UIButton!
    @IBOutlet weak var nombreTextField: UITextField!
    @IBOutlet weak var agregarButton: UIButton!
    @IBOutlet weak var duracionLabel: UILabel!
    @IBOutlet weak var volumenSlider: UISlider!
    
    var grabarAudio: AVAudioRecorder?
    var reproducirAudio: AVAudioPlayer?
    var audioURL: URL?
    var timer: Timer?
    var tiempoGrabacion: TimeInterval = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configurarGrabacion()
        reproducirButton.isEnabled = false
        agregarButton.isEnabled = false
    }
    
    func configurarGrabacion() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: [])
            try session.overrideOutputAudioPort(.speaker)
            try session.setActive(true)
            
            let basePath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let pathComponents = [basePath, "audio.m4a"]
            audioURL = NSURL.fileURL(withPathComponents: pathComponents)!
            
            var settings: [String: AnyObject] = [:]
            settings[AVFormatIDKey] = Int(kAudioFormatMPEG4AAC) as AnyObject?
            settings[AVSampleRateKey] = 44100.0 as AnyObject?
            settings[AVNumberOfChannelsKey] = 2 as AnyObject?
            
            grabarAudio = try AVAudioRecorder(url: audioURL!, settings: settings)
            grabarAudio?.delegate = self
            grabarAudio?.prepareToRecord()
        } catch let error as NSError {
            print("Error al configurar la grabación: \(error.localizedDescription)")
        }
    }
    
    @IBAction func grabarTapped(_ sender: Any) {
        if grabarAudio!.isRecording {
            grabarAudio?.stop()
            grabarButton.setTitle("GRABAR", for: .normal)
            reproducirButton.isEnabled = true
            agregarButton.isEnabled = true
            detenerTimer()
        } else {
            grabarAudio?.record()
            grabarButton.setTitle("DETENER", for: .normal)
            reproducirButton.isEnabled = false
            iniciarTimer()
        }
    }
    
    @IBAction func reproducirTapped(_ sender: Any) {
        do {
            try reproducirAudio = AVAudioPlayer(contentsOf: audioURL!)
            reproducirAudio?.play()
        } catch {
            print("Error al reproducir el audio grabado: \(error.localizedDescription)")
        }
    }
    
    @IBAction func agregarTapped(_ sender: Any) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let grabacion = Grabacion(context: context)
        grabacion.nombre = nombreTextField.text
        grabacion.audio = NSData(contentsOf: audioURL!)! as Data
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        navigationController!.popViewController(animated: true)
    }
    
    func iniciarTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            self?.tiempoGrabacion += 1
            self?.actualizarDuracionLabel()
        }
    }
    
    func detenerTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func actualizarDuracionLabel() {
        let minutos = Int(tiempoGrabacion) / 60
        let segundos = Int(tiempoGrabacion) % 60
        duracionLabel.text = String(format: "%02d:%02d", minutos, segundos)
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        detenerTimer()
        resetearTiempoGrabacion()
    }
    
    func resetearTiempoGrabacion() {
        tiempoGrabacion = 0
        actualizarDuracionLabel()
    }
    
    @IBAction func ajustarVolumen(_ sender: UISlider) {
        reproducirAudio?.volume = sender.value
    }
}
