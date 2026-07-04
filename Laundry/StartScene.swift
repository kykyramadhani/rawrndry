import SpriteKit

class StartScene: SKScene {
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        setupBackground()
        setupStartButton()
    }
    
    private func setupBackground() {
        let background = SKSpriteNode(imageNamed: "startBackground")
        background.size = self.size
        background.position = CGPoint.zero
        background.zPosition = -1
        addChild(background)
    }
    
    private func setupStartButton() {
        let button = SKSpriteNode(imageNamed: "btnMain")
        button.name = "startButton"
        // Skala 1 berarti ukuran asli gambar btnMain kamu
        button.setScale(1.0)
        button.position = CGPoint(x: 0, y: -self.size.height * 0.3)
        button.zPosition = 1
        
        let startLabel = SKLabelNode(text: "START")
        startLabel.fontName = "ValdursansComicaNo1-Regular"
        
        // 👇 Ukuran font dikecilkan agar muat di dalam button
        startLabel.fontSize = 35
        startLabel.fontColor = .white
        startLabel.verticalAlignmentMode = .center
        startLabel.position = CGPoint(x: 0, y: 0)
        startLabel.zPosition = 2
        
        button.addChild(startLabel)
        addChild(button)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = self.nodes(at: location)
        
        for node in nodes {
            // 👇 Logika diperbaiki agar SELALU menganimasi button utamanya
            if node.name == "startButton" {
                // Kena background tombolnya
                animateButtonThenStart(node: node)
                break
            } else if node.parent?.name == "startButton" {
                // Kena teksnya, maka yang dianimasikan adalah parent-nya (tombolnya)
                animateButtonThenStart(node: node.parent!)
                break
            }
        }
    }
    
    private func animateButtonThenStart(node: SKNode) {
        // 👇 Animasi diperbaiki: mengecil 10% (0.9) lalu kembali ke ukuran asli (1.0)
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        
        node.run(SKAction.sequence([scaleDown, scaleUp])) {
            self.goToGameScene()
        }
    }
    
    private func goToGameScene() {
        // Transisi ke CustomerScene sesuai flow asli kodinganmu
        let gameScene = CustomerScene(size: self.size)
        gameScene.scaleMode = .aspectFit // Samakan dengan pengaturan di GameViewController
        
        let transition = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(gameScene, transition: transition)
    }
}
