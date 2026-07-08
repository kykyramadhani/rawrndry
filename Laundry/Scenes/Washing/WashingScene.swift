import SpriteKit

class WashingScene: SKScene {
    
    private var leftBasket: SKSpriteNode!
    private var basketPiles: SKSpriteNode!
    private var pickedClothes: SKSpriteNode!
    private var spreadClothes: SKSpriteNode!
    private var rightBasket: SKSpriteNode!
    private var rightBasketPiles: SKSpriteNode!
    
    private var activeStains: [SKSpriteNode] = []

    var itemsToWash: [LaundryItem] = []
    private var currentItemIndex: Int = 0
    
    enum WashState {
        case idle, draggingDirty, washing, clean, draggingClean
    }
    
    private var currentState: WashState = .idle
    private var scrubAmount: CGFloat = 0.0
    private var requiredScrubAmount: CGFloat = 800.0
    private var lastTouchLocation: CGPoint?
    
    private let basketSize = CGSize(width: 120, height: 120)
    private let pickedClothesSize = CGSize(width: 90, height: 90)
    private let spreadClothesSize = CGSize(width: 250, height: 250)
    private let spreadClothesPosition = CGPoint(x: -0.02, y: -0.02)
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        setupBackground()
        setupLeftBasket()
        setupClothesOnSteps()
        setupSoaps()
        setupRightBasket()
        setupStationArrows()

        updateBasketPile()

        AudioManager.shared.stopThemeBGM()
        AudioManager.shared.playRiverAmbience()
    }
    
    private func setupBackground() {
        let background = SKSpriteNode(imageNamed: AssetName.Background.washing)
        background.size = self.size
        background.zPosition = -1
        addChild(background)
    }
    
    private func setupLeftBasket() {
        leftBasket = SKSpriteNode(imageNamed: AssetName.Item.washingBasketEmpty)
        leftBasket.size = basketSize
        leftBasket.position = CGPoint(x: -self.size.width * 0.35, y: -self.size.height * 0.35)
        leftBasket.zPosition = 10
        addChild(leftBasket)
        
        basketPiles = SKSpriteNode()
        basketPiles.name = "basketPiles"
        basketPiles.size = basketSize
        basketPiles.position = leftBasket.position
        basketPiles.zPosition = 11
        addChild(basketPiles)
    }
    
    private func setupRightBasket() {
        rightBasket = SKSpriteNode(imageNamed: AssetName.Item.washingBasketEmpty)
        // Gunakan size langsung
        rightBasket.size = basketSize
        rightBasket.position = CGPoint(x: self.size.width * 0.35, y: -self.size.height * 0.35)
        rightBasket.zPosition = 10
        addChild(rightBasket)
        
        rightBasketPiles = SKSpriteNode()
        rightBasketPiles.name = "rightBasketPiles"
        rightBasketPiles.size = basketSize
        rightBasketPiles.position = rightBasket.position
        rightBasketPiles.zPosition = 11
        rightBasketPiles.isHidden = true
        addChild(rightBasketPiles)
    }
    
    private func setupClothesOnSteps() {
            pickedClothes = SKSpriteNode()
            pickedClothes.size = pickedClothesSize
            pickedClothes.zPosition = 20
            pickedClothes.isHidden = true
            addChild(pickedClothes)
            
            spreadClothes = SKSpriteNode()
            spreadClothes.name = "spreadClothes"
            spreadClothes.size = spreadClothesSize
            spreadClothes.position = CGPoint(x: self.size.width * spreadClothesPosition.x, y: self.size.height * spreadClothesPosition.y)
            spreadClothes.zPosition = 4
            spreadClothes.isHidden = true
            addChild(spreadClothes)
        }
    
    private func setupSoaps() {
        let soap1 = SKSpriteNode(imageNamed: AssetName.Item.washingSoap(id: 1))
        soap1.setScale(0.08)
        soap1.position = CGPoint(x: self.size.width * 0.12, y: -self.size.height * 0.28)
        soap1.zPosition = 15
        addChild(soap1)
        
        let soap2 = SKSpriteNode(imageNamed: AssetName.Item.washingSoap(id: 2))
        soap2.setScale(0.08)
        soap2.position = CGPoint(x: self.size.width * 0.20, y: -self.size.height * 0.27)
        soap2.zPosition = 15
        addChild(soap2)
    }
    
    private func updateBasketPile() {
            if currentItemIndex < itemsToWash.count {
                let currentItem = itemsToWash[currentItemIndex]
                
                basketPiles.texture = SKTexture(imageNamed: AssetName.Item.washingBasketPile(patternID: currentItem.patternID))
                basketPiles.isHidden = false
                
                pickedClothes.texture = SKTexture(imageNamed: AssetName.Item.washingPickedClothes(patternID: currentItem.patternID))
                pickedClothes.size = pickedClothesSize
                
            } else {
                basketPiles.isHidden = true
            }
        }
    
    private func setupStains(for item: LaundryItem) {
            activeStains.forEach { $0.removeFromParent() }
            activeStains.removeAll()
            
            requiredScrubAmount = (item.stain == .hard) ? 1200.0 : 600.0
            scrubAmount = 0.0
            
            let randomStainID = Int.random(in: 1...4)
            let stain = SKSpriteNode(imageNamed: AssetName.Item.washingStain(id: randomStainID))
            
            stain.size = CGSize(width: 60, height: 60)
            stain.zRotation = CGFloat.random(in: 0...(2 * .pi))

            let safeAreaWidth = spreadClothesSize.width * 0.1
            let safeAreaHeight = spreadClothesSize.height * 0.1
            
            let randomX = CGFloat.random(in: -safeAreaWidth...safeAreaWidth)
            let randomY = CGFloat.random(in: -safeAreaHeight...safeAreaHeight)
            
            stain.position = CGPoint(x: randomX, y: randomY)
            stain.zPosition = 1
            
            spreadClothes.addChild(stain)
            activeStains.append(stain)
        }
    

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        switch currentState {
        case .idle:
            if basketPiles.contains(location) && currentItemIndex < itemsToWash.count {
                currentState = .draggingDirty
                pickedClothes.position = location
                pickedClothes.isHidden = false
            }
        case .washing:
            if spreadClothes.contains(location) { lastTouchLocation = location }
        case .clean:
            if spreadClothes.contains(location) {
                currentState = .draggingClean
                spreadClothes.isHidden = true
                pickedClothes.position = location
                pickedClothes.isHidden = false
            }
        default: break
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        switch currentState {
        case .draggingDirty, .draggingClean:
            pickedClothes.position = location
            
        case .washing:
            if let lastTouch = lastTouchLocation, spreadClothes.contains(location) {
                let distance = hypot(location.x - lastTouch.x, location.y - lastTouch.y)
                scrubAmount += distance
                lastTouchLocation = location
                
                let progress = min(1.0, scrubAmount / requiredScrubAmount)
                for stain in activeStains { stain.alpha = 1.0 - progress }
                AudioManager.shared.playScrubbing()
                
                if progress >= 1.0 {
                    currentState = .clean
                    activeStains.forEach { $0.isHidden = true }
                    AudioManager.shared.stopScrubbing()
                }
            }
        default: break
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        AudioManager.shared.stopScrubbing()
        
        switch currentState {
        case .draggingDirty:
                let rockArea = CGRect(x: -self.size.width * 0.15, y: -self.size.height * 0.15,
                                      width: self.size.width * 0.3, height: self.size.height * 0.3)
                
                if rockArea.contains(pickedClothes.position) {
                    currentState = .washing
                    pickedClothes.isHidden = true
                    
                    if currentItemIndex < itemsToWash.count {
                        let currentItem = itemsToWash[currentItemIndex]
                        spreadClothes.texture = SKTexture(imageNamed: currentItem.imageName)
                        spreadClothes.size = spreadClothesSize
                        setupStains(for: currentItem)
                    }
                    
                    spreadClothes.isHidden = false
                    activeStains.forEach { $0.isHidden = false; $0.alpha = 1.0 }
                    scrubAmount = 0.0
                } else {
                    pickedClothes.isHidden = true
                    currentState = .idle
                }
            
        case .draggingClean:
            if rightBasket.contains(pickedClothes.position) {
                pickedClothes.isHidden = true
                currentState = .idle
                

                let washedItem = itemsToWash[currentItemIndex]
                rightBasketPiles.texture = SKTexture(imageNamed: AssetName.Item.washingBasketPile(patternID: washedItem.patternID))
                rightBasketPiles.isHidden = false
                
                spreadClothes.position = CGPoint(x: self.size.width * spreadClothesPosition.x,
                                                 y: self.size.height * spreadClothesPosition.y)
                spreadClothes.zPosition = 4
                
                // Maju ke baju berikutnya (FIFO)
                currentItemIndex += 1
                updateBasketPile()
                
                if currentItemIndex >= itemsToWash.count {
                    print("✅ Cucian Selesai Semua!")
                }
                
            } else {
                pickedClothes.isHidden = true
                spreadClothes.isHidden = false
                currentState = .clean
            }
            
        default: break
        }
        
        lastTouchLocation = nil
    }
    
    private func setupStationArrows() {
            makeButton(
                imageNamed: "arrow-left",
                position: CGPoint(x: -self.size.width * 0.46, y: 0),
                scale: 0.02,
                nodeName: "stationLeft"
            )
            makeButton(
                imageNamed: "arrow-right",
                position: CGPoint(x: self.size.width * 0.46, y: 0),
                scale: 0.02,
                nodeName: "stationRight"
            )
        }
}
