//
//  PackagingScene.swift
//  
//
//  Created by Kyky on 04/07/26.
//

import SpriteKit

class PackagingScene: SKScene {
    
    var leafNode: SKSpriteNode!
    

    var foldStep = 0 
    let requiredFolds: [UISwipeGestureRecognizer.Direction] = [.right, .down, .left, .up]
    
    override func didMove(to view: SKView) {
        backgroundColor = .systemBrown
        setupUI()
        setupSwipeGestures(in: view)
    }
    
    func setupUI() {
        let foldedClothes = SKSpriteNode(color: .lightGray, size: CGSize(width: 150, height: 100))
        foldedClothes.position = CGPoint(x: frame.midX, y: frame.midY)
        foldedClothes.zPosition = 1
        addChild(foldedClothes)
        
        leafNode = SKSpriteNode(color: .green, size: CGSize(width: 400, height: 300))
        leafNode.position = CGPoint(x: frame.midX, y: frame.midY)
        leafNode.zPosition = 0
        addChild(leafNode)
        
        let instruction = SKLabelNode(text: "Swipe to fold the leaf!")
        instruction.position = CGPoint(x: frame.midX, y: frame.minY + 50)
        instruction.fontSize = 24
        addChild(instruction)
    }
    
    func setupSwipeGestures(in view: SKView) {
        let directions: [UISwipeGestureRecognizer.Direction] = [.right, .down, .left, .up]
        
        for direction in directions {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            swipe.direction = direction
            view.addGestureRecognizer(swipe)
        }
    }
    
    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        guard foldStep < requiredFolds.count else { return }
        
        let expectedDirection = requiredFolds[foldStep]
        
        if sender.direction == expectedDirection {
            foldStep += 1
            animateLeafFold(direction: sender.direction)
            
            if foldStep == requiredFolds.count {
                packagingComplete()
            }
        } else {
            print("Salah arah! Harusnya ke arah \(expectedDirection)")
        }
    }
    
    func animateLeafFold(direction: UISwipeGestureRecognizer.Direction) {
        let duration = 0.3
        var scaleAction: SKAction!
        
        switch direction {
        case .right:
            scaleAction = SKAction.scaleX(to: 0.75, duration: duration)
        case .down:
            scaleAction = SKAction.scaleY(to: 0.75, duration: duration)
        case .left:
            scaleAction = SKAction.scaleX(to: 0.5, duration: duration)
        case .up:
            scaleAction = SKAction.scaleY(to: 0.5, duration: duration)
        default:
            break
        }
        
        leafNode.run(scaleAction)
    }
    
    func packagingComplete() {
        print("Packaging Selesai! Baju siap diberikan ke Customer.")
        
        let wait = SKAction.wait(forDuration: 1.0)
        let transition = SKAction.run {
            // let validationScene = ValidationScene(size: self.size)
            // SceneManager.shared.transition(to: validationScene)
        }
        run(SKAction.sequence([wait, transition]))
    }
    
    override func willMove(from view: SKView) {
        if let gestures = view.gestureRecognizers {
            for gesture in gestures {
                view.removeGestureRecognizer(gesture)
            }
        }
    }
}
