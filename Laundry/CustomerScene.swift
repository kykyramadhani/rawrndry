import SpriteKit

class CustomerScene: SKScene {
    
    // MARK: - Properties
    private var customerNode: SKSpriteNode!
    private var laundryBag: SKSpriteNode!
    private var speechBubble: SKSpriteNode!
    
    // Data customer yang sedang dilayani
    private var currentCustomer: CustomerModel?
    
    private let finalCustomerPosition = CGPoint(x: -0.28, y: -0.08)
    private let finalBagPosition = CGPoint(x: 0.32, y: -0.18)
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        // Ambil customer dari antrean hari ini
        currentCustomer = CustomerManager.shared.getNextCustomer()
        
        // (OPSIONAL UNTUK TESTING) Kalau datanya kosong, paksa generate customer baru
        if currentCustomer == nil {
            CustomerManager.shared.generateCustomers(forDay: 1)
            currentCustomer = CustomerManager.shared.getNextCustomer()
        }
        
        setupBackground()
        setupCustomer()
        setupForeground()
        setupLaundryBag()
        setupSpeechBubble()
        
        animateArrival()
    }
    
    // MARK: - Setup Methods
    
    private func setupBackground() {
        let background = SKSpriteNode(imageNamed: AssetName.Background.frontDesk)
        background.size = self.size
        background.position = CGPoint.zero
        background.zPosition = -10
        addChild(background)
    }
    
    private func setupCustomer() {
        // 👇 Gambar customer sekarang dinamis dari data CustomerManager
        let characterImage = currentCustomer?.characterImage ?? AssetName.Character.customer1
        
        customerNode = SKSpriteNode(imageNamed: characterImage)
        customerNode.setScale(0.22)
        
        // Mulai dari luar layar sebelah kiri (sembunyi dulu)
        customerNode.position = CGPoint(x: -self.size.width, y: -self.size.height * 0.08)
        customerNode.zPosition = 0
        addChild(customerNode)
    }
    
    private func setupForeground() {
        let foreground = SKSpriteNode(imageNamed: AssetName.Item.foregroundDesk)
        foreground.size = self.size
        foreground.position = CGPoint.zero
        foreground.zPosition = 10
        addChild(foreground)
    }
    
    private func setupLaundryBag() {
            laundryBag = SKSpriteNode(imageNamed: AssetName.Item.dirtyClothesBag)
            laundryBag.setScale(0.15)
            
            // 👇 PERBAIKAN: Hapus tanda minus (-) sebelum self.size.height
            laundryBag.position = CGPoint(x: self.size.width * finalBagPosition.x, y: self.size.height * finalBagPosition.y)
            
            laundryBag.zPosition = 20
            laundryBag.alpha = 0
            addChild(laundryBag)
            
            setupFlies()
        }
    
    private func setupFlies() {
        let fly1 = SKSpriteNode(imageNamed: AssetName.Item.fly1)
        fly1.setScale(0.3)
        fly1.position = CGPoint(x: -120, y: -20)
        fly1.zPosition = 1
        laundryBag.addChild(fly1)
        
        let fly2 = SKSpriteNode(imageNamed: AssetName.Item.fly2)
        fly2.setScale(0.3)
        fly2.position = CGPoint(x: 100, y: 80)
        fly2.zPosition = 1
        laundryBag.addChild(fly2)
        
        animateFly(fly: fly1, duration: 0.15, offset: 5)
        animateFly(fly: fly2, duration: 0.2, offset: -7)
    }
    
    private func setupSpeechBubble() {
        speechBubble = SKSpriteNode(imageNamed: AssetName.UI.speechBubble)
        speechBubble.setScale(0)
        speechBubble.position = CGPoint(x: 0, y: self.size.height * 0.25)
        speechBubble.zPosition = 30
        
        // 👇 Ambil teks dinamis dari data customer
        let text = currentCustomer?.orderText ?? "WASH PLS."
        
        let customFont = UIFont(name: AssetName.Font.comica, size: 55) ?? UIFont.systemFont(ofSize: 55, weight: .bold)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: customFont,
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -4.0
        ]
        
        let attrString = NSAttributedString(string: text, attributes: attributes)
        
        let textLabel = SKLabelNode(attributedText: attrString)
        textLabel.verticalAlignmentMode = .center
        textLabel.position = CGPoint(x: 0, y: 0)
        textLabel.zPosition = 1
        
        speechBubble.addChild(textLabel)
        addChild(speechBubble)
    }
    
    // MARK: - Animations
    
    // MARK: - Animations
        
        private func animateArrival() {
            // 1. Customer jalan masuk
            let walkIn = SKAction.moveTo(x: -self.size.width * 0.28, duration: 1.0)
            walkIn.timingMode = .easeOut
            
            // 2. Karung cucian muncul (efek dijatuhkan ke meja)
            let bagAppear = SKAction.fadeAlpha(to: 1.0, duration: 0.2)
            let bagDrop = SKAction.moveBy(x: 0, y: -20, duration: 0.2)
            let bagSpawn = SKAction.group([bagAppear, bagDrop])
            
            // 3. Bubble chat pop up membesar
            let popUp = SKAction.scale(to: 0.35, duration: 0.3)
            let popBounce = SKAction.scale(to: 0.3, duration: 0.1)
            let bubbleAnim = SKAction.sequence([popUp, popBounce])
            
            // 4. Sequence untuk customernya (hanya jalan masuk)
            let customerSequence = SKAction.sequence([
                walkIn
            ])
            customerNode.run(customerSequence)
            
            // 5. Sequence pengatur waktu untuk karung dan bubble
            // 👇 PERBAIKAN DI SINI: SKAction.run digunakan agar bagSpawn berjalan di laundryBag
            let sceneAnimations = SKAction.sequence([
                SKAction.wait(forDuration: 1.0), // Tunggu customer sampai ke meja
                SKAction.run { self.laundryBag.run(bagSpawn) }, // <- Eksekusi munculin karung
                SKAction.wait(forDuration: 0.3), // Jeda sebentar
                SKAction.run { self.speechBubble.run(bubbleAnim) } // <- Eksekusi munculin teks
            ])
            
            self.run(sceneAnimations)
        }
    
    private func animateFly(fly: SKSpriteNode, duration: TimeInterval, offset: CGFloat) {
        let moveUp = SKAction.moveBy(x: offset, y: offset, duration: duration)
        let moveDown = SKAction.moveBy(x: -offset, y: -offset, duration: duration)
        let sequence = SKAction.sequence([moveUp, moveDown])
        let hover = SKAction.repeatForever(sequence)
        
        fly.run(hover)
    }
    
    // MARK: - Touch Interaction
        
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Mengecek apakah area yang disentuh berada di dalam area karung cucian
        if laundryBag.contains(location) {
            
            // 1. Matikan interaksi sementara agar player tidak spam tap berkali-kali
            self.isUserInteractionEnabled = false
            
            // 2. Animasi membal (skala asli karung adalah 0.15, kita kecilkan sedikit lalu kembalikan)
            let scaleDown = SKAction.scale(to: 0.13, duration: 0.1)
            let scaleUp = SKAction.scale(to: 0.15, duration: 0.1)
            let bounce = SKAction.sequence([scaleDown, scaleUp])
            
            // 3. Jalankan animasi, dan jika sudah selesai, pindah scene
            laundryBag.run(bounce) {
                let washingScene = WashingScene(size: self.size)
                
                // Menggunakan SceneManager yang sudah kita buat sebelumnya
                SceneManager.shared.transition(to: washingScene, from: self.view)
            }
        }
    }
}
