import SpriteKit

class CustomerScene: SKScene {
    
    private var customerNode: SKSpriteNode!
    private var laundryBag: SKSpriteNode!
    private var speechBubble: SKSpriteNode!
    
    private var currentCustomer: CustomerModel?
    
    private let finalCustomerPosition = CGPoint(x: -0.28, y: -0.08)
    private let finalBagPosition = CGPoint(x: 0.32, y: -0.18)
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        currentCustomer = CustomerManager.shared.getNextCustomer()
        
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
    
    private func setupBackground() {
        let background = SKSpriteNode(imageNamed: AssetName.Background.frontDesk)
        background.size = self.size
        background.position = CGPoint.zero
        background.zPosition = -10
        addChild(background)
    }
    
    private func setupCustomer() {
        let characterImage = currentCustomer?.characterImage ?? AssetName.Character.customer1
        
        customerNode = SKSpriteNode(imageNamed: characterImage)
        customerNode.setScale(0.22)
        
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
        
        let text = currentCustomer?.orderText ?? "WASH PLS."
        
        let customFont = UIFont(name: AssetName.Font.comica, size: 33) ?? UIFont.systemFont(ofSize: 55, weight: .bold)
        
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
    
    private func animateArrival() {
        let walkIn = SKAction.moveTo(x: -self.size.width * 0.28, duration: 1.0)
        walkIn.timingMode = .easeOut
        
        let bagAppear = SKAction.fadeAlpha(to: 1.0, duration: 0.2)
        let bagDrop = SKAction.moveBy(x: 0, y: -20, duration: 0.2)
        let bagSpawn = SKAction.group([bagAppear, bagDrop])
        
        let popUp = SKAction.scale(to: 0.50, duration: 0.3)
        let popBounce = SKAction.scale(to: 0.45, duration: 0.1)
        let bubbleAnim = SKAction.sequence([popUp, popBounce])
        
        let customerSequence = SKAction.sequence([
            walkIn
        ])
        customerNode.run(customerSequence)
        
        let sceneAnimations = SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { self.laundryBag.run(bagSpawn) },
            SKAction.wait(forDuration: 0.3),
            SKAction.run { self.speechBubble.run(bubbleAnim) }
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if laundryBag.contains(location) {
            
            self.isUserInteractionEnabled = false
            
            let scaleDown = SKAction.scale(to: 0.13, duration: 0.1)
            let scaleUp = SKAction.scale(to: 0.15, duration: 0.1)
            let bounce = SKAction.sequence([scaleDown, scaleUp])
            
            laundryBag.run(bounce) {
                let washingScene = WashingScene(size: self.size)
                
                SceneManager.shared.transition(to: washingScene, from: self.view)
            }
        }
    }
}
