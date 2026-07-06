import SpriteKit

class WashingScene: SKScene {
    
    private var leftBasket: SKSpriteNode!
    private var basketPiles: SKSpriteNode!
    private var pickedClothes: SKSpriteNode!
    private var spreadClothes: SKSpriteNode!
    private var dirtStain: SKSpriteNode!
    private var rightBasket: SKSpriteNode!
    
    enum WashState {
        case idle
        case draggingDirty
        case washing
        case clean
        case draggingClean
    }
    
    private var currentState: WashState = .idle
    private var scrubAmount: CGFloat = 0.0
    private let requiredScrubAmount: CGFloat = 800.0
    private var lastTouchLocation: CGPoint?
    
    private let spreadClothesPosition = CGPoint(x: -0.02, y: -0.02)
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        setupBackground()
        setupLeftBasket()
        setupClothesOnSteps()
        setupSoaps()
        setupRightBasket()
        
        // Tukar Audio
        AudioManager.shared.stopThemeBGM()
        AudioManager.shared.playRiverAmbience()
    }
    
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
        basketPiles.name = "basketPiles"
        basketPiles.setScale(0.15)
        basketPiles.position = CGPoint(x: leftBasket.position.x, y: leftBasket.position.y + 10)
        basketPiles.zPosition = 11
        addChild(basketPiles)
    }
    
    private func setupClothesOnSteps() {
        pickedClothes = SKSpriteNode(imageNamed: "washingPickedClothes1.jpg")
        pickedClothes.setScale(0.18)
        pickedClothes.zPosition = 20
        pickedClothes.isHidden = true
        addChild(pickedClothes)
        
        spreadClothes = SKSpriteNode(imageNamed: "washingClothes1.jpg")
        spreadClothes.name = "spreadClothes"
        spreadClothes.setScale(0.22)
        spreadClothes.position = CGPoint(x: self.size.width * spreadClothesPosition.x,
                                         y: self.size.height * spreadClothesPosition.y)
        spreadClothes.zPosition = 4
        spreadClothes.isHidden = true
        addChild(spreadClothes)
        
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        switch currentState {
        case .idle:
            if basketPiles.contains(location) {
                currentState = .draggingDirty
                pickedClothes.position = location
                pickedClothes.isHidden = false
            }
        case .washing:
            if spreadClothes.contains(location) {
                lastTouchLocation = location
            }
        case .clean:
            if spreadClothes.contains(location) {
                currentState = .draggingClean
                spreadClothes.isHidden = true
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
                pickedClothes.position = location
                
            case .washing:
                if let lastTouch = lastTouchLocation, spreadClothes.contains(location) {
                    let distance = hypot(location.x - lastTouch.x, location.y - lastTouch.y)
                    scrubAmount += distance
                    lastTouchLocation = location
                    
                    let progress = min(1.0, scrubAmount / requiredScrubAmount)
                    dirtStain.alpha = 1.0 - progress
                    
                    AudioManager.shared.playScrubbing()
                    
                    if progress >= 1.0 {
                        currentState = .clean
                        dirtStain.isHidden = true
                        
                        AudioManager.shared.stopScrubbing()
                    }
                }
                
            case .draggingClean:
                pickedClothes.position = location
                spreadClothes.isHidden = true
                
            default:
                break
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
                    
                    spreadClothes.isHidden = false
                    dirtStain.isHidden = false
                    dirtStain.alpha = 1.0
                    scrubAmount = 0.0
                } else {
                    pickedClothes.isHidden = true
                    currentState = .idle
                }
                
            case .washing:
                lastTouchLocation = nil
                
            case .draggingClean:
                if rightBasket.contains(pickedClothes.position) {
                    pickedClothes.isHidden = true
                    currentState = .idle
                    
                    spreadClothes.position = CGPoint(x: self.size.width * spreadClothesPosition.x,
                                                     y: self.size.height * spreadClothesPosition.y)
                    spreadClothes.zPosition = 4
                    
                } else {
                    pickedClothes.isHidden = true
                    spreadClothes.isHidden = false
                    
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
