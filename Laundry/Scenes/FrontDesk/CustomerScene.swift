import SpriteKit

class CustomerScene: SKScene {
    
    // Core Nodes
    private var customerNode: SKSpriteNode!
    private var laundryBag: SKSpriteNode!
    private var bubbleContainer: SKNode!
    private var bubbleBg: SKSpriteNode!
    
    // UI Nodes
    private var chevronBtn: SKSpriteNode!
    private var dayHud: SKSpriteNode!
    private var currencyHud: SKSpriteNode!
    private var instructionBtn: SKSpriteNode!
    
    private var currentCustomer: CustomerModel?
    
    private let finalCustomerPosition = CGPoint(x: -0.28, y: -0.22)
    private let finalBagPosition = CGPoint(x: 0.32, y: -0.18)
    
    private let plainTextColor = UIColor(red: 255.0/255.0, green: 247.0/255.0, blue: 234.0/255.0, alpha: 1.0)
    private let plainTextBrown = UIColor(red: 143.0/255.0, green: 43.0/255.0, blue: 18.0/255.0, alpha: 1.0)
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        currentCustomer = CustomerManager.shared.getNextCustomer()
        
        if currentCustomer == nil {
            CustomerManager.shared.generateCustomers(forDay: DayManager.shared.currentDay)
            currentCustomer = CustomerManager.shared.getNextCustomer()
        }
        
        setupBackground()
        setupUI()
        setupCustomer()
        setupForeground()
        setupLaundryBag()
        setupSpeechBubble()
        
        animateArrival()
        
        AudioManager.shared.stopRiverAmbience()
        AudioManager.shared.playThemeBGM()
    }
    
    private func setupBackground() {
        let background = SKSpriteNode(imageNamed: AssetName.Background.frontDesk)
        background.size = self.size
        background.position = CGPoint.zero
        background.zPosition = -10
        addChild(background)
    }
    
    // MARK: - Setup UI Elements
    private func setupUI() {
        let topY = self.size.height * 0.40
        var currentX = -self.size.width * 0.45
        let horizontalSpacing: CGFloat = 15
        
        // --- 1. Day Indicator ---
        dayHud = SKSpriteNode(imageNamed: AssetName.UI.hudIndicator)
        dayHud.position = CGPoint(x: currentX + dayHud.size.width / 2, y: topY)
        dayHud.zPosition = 100
        addChild(dayHud)
        
        let dayContent = SKNode()
        let sunIcon = SKSpriteNode(imageNamed: AssetName.UI.sunIcon)
        sunIcon.position = CGPoint.zero

        let dayLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        dayLabel.text = "DAY \(DayManager.shared.currentDay)"
        dayLabel.fontSize = 24
        dayLabel.fontColor = plainTextColor
        dayLabel.verticalAlignmentMode = .center
        dayLabel.horizontalAlignmentMode = .left
        dayLabel.position = CGPoint(x: sunIcon.size.width / 2 + 10, y: 0)
        
        dayContent.addChild(sunIcon)
        dayContent.addChild(dayLabel)
        
        let dayTotalWidth = (sunIcon.size.width / 2) + 10 + dayLabel.frame.width
        dayContent.position = CGPoint(x: -dayTotalWidth / 2, y: 0)
        dayContent.zPosition = 101
        dayHud.addChild(dayContent)
        
        currentX += dayHud.size.width + horizontalSpacing
        
        // --- 2. Currency Indicator ---
        currencyHud = SKSpriteNode(imageNamed: AssetName.UI.hudIndicator)
        currencyHud.position = CGPoint(x: currentX + currencyHud.size.width / 2, y: topY)
        currencyHud.zPosition = 100
        addChild(currencyHud)
        
        let currencyContent = SKNode()
        let gemIcon = SKSpriteNode(imageNamed: AssetName.UI.gemIcon)
        gemIcon.position = CGPoint.zero
        
        let currencyLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        currencyLabel.text = "\(CurrencyManager.shared.coins)"
        currencyLabel.fontSize = 24
        currencyLabel.fontColor = plainTextColor
        currencyLabel.verticalAlignmentMode = .center
        currencyLabel.horizontalAlignmentMode = .left
        currencyLabel.position = CGPoint(x: gemIcon.size.width / 2 + 10, y: 0)
        
        currencyContent.addChild(gemIcon)
        currencyContent.addChild(currencyLabel)
        
        let currencyTotalWidth = (gemIcon.size.width / 2) + 10 + currencyLabel.frame.width
        currencyContent.position = CGPoint(x: -currencyTotalWidth / 2, y: 0)
        currencyContent.zPosition = 101
        currencyHud.addChild(currencyContent)
        
        // --- 3. Instruction Button ---
        instructionBtn = SKSpriteNode(imageNamed: AssetName.UI.btnInstruction)
        instructionBtn.setScale(0.8)
        instructionBtn.position = CGPoint(x: self.size.width * 0.43, y: topY)
        instructionBtn.zPosition = 100
        addChild(instructionBtn)
        
        // --- 4. Chevron Button ---
        chevronBtn = SKSpriteNode(imageNamed: AssetName.UI.chevronRight)
        chevronBtn.setScale(0.8)
        chevronBtn.position = CGPoint(x: self.size.width * 0.43, y: 0)
        chevronBtn.zPosition = 100
        addChild(chevronBtn)
    }
    
    private func setupCustomer() {
        let characterImage = currentCustomer?.characterImage ?? AssetName.Character.customer1
        let texture = SKTexture(imageNamed: characterImage)
        customerNode = SKSpriteNode(texture: texture)
        
        let targetWidth: CGFloat = 290.0
        let scaleFactor = targetWidth / texture.size().width
        customerNode.setScale(scaleFactor)
        
        customerNode.position = CGPoint(x: -self.size.width, y: -self.size.height * 0.22)
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
        let bagTexture = SKTexture(imageNamed: AssetName.Item.dirtyClothesBag)
        laundryBag = SKSpriteNode(texture: bagTexture)
        
        let targetWidth: CGFloat = 250.0
        let bagScaleFactor = targetWidth / bagTexture.size().width
        laundryBag.setScale(bagScaleFactor)
        
        laundryBag.position = CGPoint(x: self.size.width * finalBagPosition.x, y: self.size.height * finalBagPosition.y)
        laundryBag.zPosition = 20
        laundryBag.alpha = 0
        addChild(laundryBag)
        
        setupFlies()
    }
        
    private func setupFlies() {
        let fly1 = SKSpriteNode(imageNamed: AssetName.Item.fly1)
        fly1.setScale(1)
        fly1.position = CGPoint(x: -90, y: -20)
        fly1.zPosition = 1
        laundryBag.addChild(fly1)
        
        let fly2 = SKSpriteNode(imageNamed: AssetName.Item.fly2)
        fly2.setScale(1)
        fly2.position = CGPoint(x: 50, y: 20)
        fly2.zPosition = 1
        laundryBag.addChild(fly2)
        
        animateFly(fly: fly1, duration: 0.15, offset: 5)
        animateFly(fly: fly2, duration: 0.2, offset: -7)
    }
    
    private func setupSpeechBubble() {
        bubbleContainer = SKNode()
        bubbleContainer.position = CGPoint(x: 100, y: 45)
        bubbleContainer.zPosition = 30
        bubbleContainer.setScale(0)
        
        bubbleBg = SKSpriteNode(imageNamed: AssetName.UI.speechBubble)
        bubbleBg.size = CGSize(width: 431, height: 81)
        bubbleBg.position = CGPoint.zero
        bubbleContainer.addChild(bubbleBg)
        
        let text = currentCustomer?.orderText ?? "WASH PLS."
        
        let textLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        textLabel.text = text.uppercased()
        textLabel.fontSize = 32
        textLabel.fontColor = plainTextBrown
        textLabel.verticalAlignmentMode = .center
        textLabel.horizontalAlignmentMode = .center
        textLabel.position = CGPoint.zero
        textLabel.zPosition = 1
        
        bubbleContainer.addChild(textLabel)
        addChild(bubbleContainer)
    }
    
    private func animateArrival() {
        let walkIn = SKAction.moveTo(x: self.size.width * finalCustomerPosition.x, duration: 1.0)
        walkIn.timingMode = .easeOut
        
        let bagAppear = SKAction.fadeAlpha(to: 1.0, duration: 0.2)
        let bagDrop = SKAction.moveBy(x: 0, y: -20, duration: 0.2)
        let bagSpawn = SKAction.group([bagAppear, bagDrop])
        
        let popUp = SKAction.scale(to: 1.0, duration: 0.3)
        let popBounce = SKAction.scale(to: 0.95, duration: 0.1)
        let bubbleAnim = SKAction.sequence([popUp, popBounce, SKAction.scale(to: 1.0, duration: 0.1)])
        
        customerNode.run(SKAction.sequence([walkIn]))
        
        let sceneAnimations = SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { self.laundryBag.run(bagSpawn) },
            SKAction.wait(forDuration: 0.3),
            SKAction.run { self.bubbleContainer.run(bubbleAnim) }
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
        
        if chevronBtn.contains(location) {
            self.isUserInteractionEnabled = false
            
            let scaleDown = SKAction.scale(to: 0.7, duration: 0.1)
            let scaleUp = SKAction.scale(to: 0.8, duration: 0.1)
            
            chevronBtn.run(SKAction.sequence([scaleDown, scaleUp])) {
                let washingScene = WashingScene(size: self.size)
                SceneManager.shared.transition(to: washingScene, from: self.view)
            }
        }
        
        if instructionBtn.contains(location) {
            let scaleDown = SKAction.scale(to: 0.7, duration: 0.1)
            let scaleUp = SKAction.scale(to: 0.8, duration: 0.1)
            instructionBtn.run(SKAction.sequence([scaleDown, scaleUp]))
        }
        
        if laundryBag.contains(location) {
            self.isUserInteractionEnabled = false
            
            let currentScale = laundryBag.xScale
            let scaleDown = SKAction.scale(to: currentScale * 0.9, duration: 0.1)
            let scaleUp = SKAction.scale(to: currentScale, duration: 0.1)
            let bounce = SKAction.sequence([scaleDown, scaleUp])
            
            laundryBag.run(bounce) {
                let washingScene = WashingScene(size: self.size)
                SceneManager.shared.transition(to: washingScene, from: self.view)
            }
        }
    }
}
