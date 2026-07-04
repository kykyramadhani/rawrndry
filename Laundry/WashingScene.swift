import SpriteKit

class WashingScene: SKScene {
    
    // MARK: - Properties
    private var leftBasket: SKSpriteNode!
    private var basketPiles: SKSpriteNode!
    private var pickedClothes: SKSpriteNode!
    private var spreadClothes: SKSpriteNode!
    private var dirtStain: SKSpriteNode!
    private var rightBasket: SKSpriteNode!
    
    // State machine untuk melacak progress cucian
    enum WashState {
        case idle           // Menunggu tumpukan baju di-drag
        case draggingDirty  // Sedang mendrag baju kotor ke batu
        case washing        // Baju di atas batu, siap di-scrub
        case clean          // Baju sudah bersih
        case draggingClean  // Sedang mendrag baju bersih ke keranjang kanan
    }
    
    private var currentState: WashState = .idle
    private var scrubAmount: CGFloat = 0.0
    private let requiredScrubAmount: CGFloat = 800.0 // Total jarak usapan jari sampai bersih (bisa di-tweak)
    private var lastTouchLocation: CGPoint?
    
    // Titik default baju saat dibentangkan
    private let spreadClothesPosition = CGPoint(x: -0.02, y: -0.02)
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        setupBackground()
        setupLeftBasket()
        setupClothesOnSteps()
        setupSoaps()
        setupRightBasket()
    }
    
    // MARK: - Setup Methods
    
    private func setupBackground() {
        let background = SKSpriteNode(imageNamed: "washingBackground.jpg")
        background.size = self.size
        background.position = CGPoint.zero
        background.zPosition = -1
        addChild(background)
    }
    
    private func setupLeftBasket() {
        leftBasket = SKSpriteNode(imageNamed: "washingBasket.jpg")
        leftBasket.setScale(0.15)
        leftBasket.position = CGPoint(x: -self.size.width * 0.35, y: -self.size.height * 0.35)
        leftBasket.zPosition = 10
        addChild(leftBasket)
        
        basketPiles = SKSpriteNode(imageNamed: "washingBasketPiles.png")
        basketPiles.name = "basketPiles" // Beri nama agar mudah dideteksi saat disentuh
        basketPiles.setScale(0.15)
        basketPiles.position = CGPoint(x: leftBasket.position.x, y: leftBasket.position.y + 10)
        basketPiles.zPosition = 11
        addChild(basketPiles)
    }
    
    private func setupClothesOnSteps() {
        // Baju yang ditarik (Awalnya disembunyikan)
        pickedClothes = SKSpriteNode(imageNamed: "washingPickedClothes1.jpg")
        pickedClothes.setScale(0.18)
        pickedClothes.zPosition = 20 // Paling depan saat di-drag
        pickedClothes.isHidden = true
        addChild(pickedClothes)
        
        // Baju yang dibentangkan (Awalnya disembunyikan)
        spreadClothes = SKSpriteNode(imageNamed: "washingClothes1.jpg")
        spreadClothes.name = "spreadClothes"
        spreadClothes.setScale(0.22)
        spreadClothes.position = CGPoint(x: self.size.width * spreadClothesPosition.x,
                                         y: self.size.height * spreadClothesPosition.y)
        spreadClothes.zPosition = 4
        spreadClothes.isHidden = true
        addChild(spreadClothes)
        
        // Noda Kotoran
        dirtStain = SKSpriteNode(imageNamed: "washingStain.PNG")
        dirtStain.setScale(0.5)
        dirtStain.position = CGPoint(x: 5, y: -5)
        dirtStain.zPosition = 1
        spreadClothes.addChild(dirtStain)
    }
    
    private func setupSoaps() {
        let soap1 = SKSpriteNode(imageNamed: "washingSoap.jpg")
        soap1.setScale(0.08)
        soap1.position = CGPoint(x: self.size.width * 0.12, y: -self.size.height * 0.28)
        soap1.zPosition = 15
        addChild(soap1)
        
        let soap2 = SKSpriteNode(imageNamed: "washingSoap.jpg")
        soap2.setScale(0.08)
        soap2.position = CGPoint(x: self.size.width * 0.20, y: -self.size.height * 0.27)
        soap2.zPosition = 15
        addChild(soap2)
    }
    
    private func setupRightBasket() {
        rightBasket = SKSpriteNode(imageNamed: "washingBasket.jpg")
        rightBasket.setScale(0.15)
        rightBasket.position = CGPoint(x: self.size.width * 0.35, y: -self.size.height * 0.35)
        rightBasket.zPosition = 10
        addChild(rightBasket)
    }
    
    // MARK: - Touch Handling (Interaksi)
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        switch currentState {
        case .idle:
            // Jika user menyentuh tumpukan baju kotor
            if basketPiles.contains(location) {
                currentState = .draggingDirty
                pickedClothes.position = location
                pickedClothes.isHidden = false
                
                // Opsional: Sembunyikan tumpukan keranjang kiri kalau bajunya cuma 1
                // basketPiles.isHidden = true
            }
        case .washing:
            // Mulai nyikat / scrubbing
            if spreadClothes.contains(location) {
                lastTouchLocation = location
            }
        case .clean:
            // Mulai drag baju yang sudah bersih
            if spreadClothes.contains(location) {
                currentState = .draggingClean
                spreadClothes.isHidden = true // Sembunyikan spreadClothes di sini
                pickedClothes.position = location
                pickedClothes.isHidden = false
            }
        default:
            break
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        switch currentState {
        case .draggingDirty:
            // Baju kotor mengikuti jari
            pickedClothes.position = location
            
        case .washing:
            // Logika Scrubbing (Menggosok)
            if let lastTouch = lastTouchLocation, spreadClothes.contains(location) {
                // Hitung jarak jari bergerak dari titik sebelumnya
                let distance = hypot(location.x - lastTouch.x, location.y - lastTouch.y)
                scrubAmount += distance
                lastTouchLocation = location
                
                // Kurangi opacity/alpha noda kotoran
                let progress = min(1.0, scrubAmount / requiredScrubAmount)
                dirtStain.alpha = 1.0 - progress
                
                // Jika noda sudah hilang sempurna
                if progress >= 1.0 {
                    currentState = .clean
                    dirtStain.isHidden = true
                    // Baju sudah bersih, siap didrag ke kanan
                }
            }
            
        case .draggingClean:
            // Baju bersih mengikuti jari
            pickedClothes.position = location
            spreadClothes.isHidden = true
            pickedClothes.position = location
            
        default:
            break
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch currentState {
        case .draggingDirty:
            // Area hitbox batu tengah untuk meletakkan cucian
            let rockArea = CGRect(x: -self.size.width * 0.15, y: -self.size.height * 0.15,
                                  width: self.size.width * 0.3, height: self.size.height * 0.3)
            
            if rockArea.contains(pickedClothes.position) {
                // Berhasil ditaruh di batu
                currentState = .washing
                pickedClothes.isHidden = true
                
                spreadClothes.isHidden = false
                dirtStain.isHidden = false
                dirtStain.alpha = 1.0
                scrubAmount = 0.0 // Reset hitungan gosokan
            } else {
                // Batal ditaruh di batu, kembalikan state
                pickedClothes.isHidden = true
                currentState = .idle
                // basketPiles.isHidden = false // Munculkan lagi kalau tadi disembunyikan
            }
            
        case .washing:
            lastTouchLocation = nil
            
        case .draggingClean:
            // Cek apakah baju bersih didrag masuk ke area keranjang kanan
            if rightBasket.contains(pickedClothes.position) {
                // Berhasil masuk keranjang kanan
                pickedClothes.isHidden = true
                currentState = .idle
                
                // Reset posisi spreadClothes ke tengah batu untuk cucian berikutnya (jika ada)
                spreadClothes.position = CGPoint(x: self.size.width * spreadClothesPosition.x,
                                                 y: self.size.height * spreadClothesPosition.y)
                spreadClothes.zPosition = 4
                
                print("Cucian selesai 1 baju!")
                // Di sini kamu bisa tambahkan kode memunculkan sprite tumpukan baju bersih di keranjang kanan
            } else {
                // Gagal masuk keranjang, kembalikan ke atas batu
                pickedClothes.isHidden = true // <-- Tambahkan ini
                spreadClothes.isHidden = false // <-- Tambahkan ini
                
                spreadClothes.position = CGPoint(x: self.size.width * spreadClothesPosition.x,
                                                 y: self.size.height * spreadClothesPosition.y)
                spreadClothes.zPosition = 4
                currentState = .clean
            }
            
        default:
            break
        }
        
        lastTouchLocation = nil
    }
}
