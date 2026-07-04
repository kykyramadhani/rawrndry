//
//  PackagingScene.swift
//  
//
//  Created by Kyky on 04/07/26.
//


//
//  PackagingScene.swift
//  TrialRawrndry
//
//  Created by Kyky on 01/07/26.
//


import SpriteKit

class PackagingScene: SKScene {
    
    var leafNode: SKSpriteNode!
    
    // Melacak urutan lipatan (Kiri -> Bawah -> Kanan -> Atas)
    // Sesuai instruksi: Kiri ke kanan (Right), Atas ke bawah (Down), Kanan ke kiri (Left), Bawah ke atas (Up)
    var foldStep = 0 
    let requiredFolds: [UISwipeGestureRecognizer.Direction] = [.right, .down, .left, .up]
    
    override func didMove(to view: SKView) {
        backgroundColor = .systemBrown // Warna meja kayu
        setupUI()
        setupSwipeGestures(in: view)
    }
    
    func setupUI() {
        // Tumpukan baju kering di tengah
        let foldedClothes = SKSpriteNode(color: .lightGray, size: CGSize(width: 150, height: 100))
        foldedClothes.position = CGPoint(x: frame.midX, y: frame.midY)
        foldedClothes.zPosition = 1 // Di atas daun
        addChild(foldedClothes)
        
        // Daun pembungkus (di bawah baju)
        leafNode = SKSpriteNode(color: .green, size: CGSize(width: 400, height: 300))
        leafNode.position = CGPoint(x: frame.midX, y: frame.midY)
        leafNode.zPosition = 0
        addChild(leafNode)
        
        // Label Instruksi
        let instruction = SKLabelNode(text: "Swipe to fold the leaf!")
        instruction.position = CGPoint(x: frame.midX, y: frame.minY + 50)
        instruction.fontSize = 24
        addChild(instruction)
    }
    
    func setupSwipeGestures(in view: SKView) {
        // Mendaftarkan 4 arah swipe
        let directions: [UISwipeGestureRecognizer.Direction] = [.right, .down, .left, .up]
        
        for direction in directions {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            swipe.direction = direction
            view.addGestureRecognizer(swipe)
        }
    }
    
    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        // Pastikan urutan lipatannya belum selesai
        guard foldStep < requiredFolds.count else { return }
        
        let expectedDirection = requiredFolds[foldStep]
        
        // Jika arah swipe pemain BENAR sesuai urutan
        if sender.direction == expectedDirection {
            foldStep += 1
            animateLeafFold(direction: sender.direction)
            
            // TODO: Tambahkan AudioManager untuk SFX folding leaves
            // AudioManager.shared.playSFX(AudioName.foldingLeaves, on: self)
            
            if foldStep == requiredFolds.count {
                packagingComplete()
            }
        } else {
            print("Salah arah! Harusnya ke arah \(expectedDirection)")
            // Bisa tambahkan animasi daun bergetar sebagai feedback salah
        }
    }
    
    func animateLeafFold(direction: UISwipeGestureRecognizer.Direction) {
        // Animasi visual mengubah ukuran daun agar terlihat seperti terlipat
        // Ini adalah versi sederhana (mengubah skala)
        let duration = 0.3
        var scaleAction: SKAction!
        
        switch direction {
        case .right:
            // Sisi kiri melipat ke kanan (lebar berkurang)
            scaleAction = SKAction.scaleX(to: 0.75, duration: duration)
        case .down:
            // Sisi atas melipat ke bawah (tinggi berkurang)
            scaleAction = SKAction.scaleY(to: 0.75, duration: duration)
        case .left:
            // Sisi kanan melipat ke kiri
            scaleAction = SKAction.scaleX(to: 0.5, duration: duration)
        case .up:
            // Sisi bawah melipat ke atas
            scaleAction = SKAction.scaleY(to: 0.5, duration: duration)
        default:
            break
        }
        
        leafNode.run(scaleAction)
    }
    
    func packagingComplete() {
        print("Packaging Selesai! Baju siap diberikan ke Customer.")
        
        // TODO: Tambahkan AudioManager untuk suara sukses
        // AudioManager.shared.playSFX(AudioName.completeTask, on: self)
        
        // Jeda sejenak lalu pindah ke CompletedScene (Validation)
        let wait = SKAction.wait(forDuration: 1.0)
        let transition = SKAction.run {
            // let validationScene = ValidationScene(size: self.size)
            // SceneManager.shared.transition(to: validationScene)
        }
        run(SKAction.sequence([wait, transition]))
    }
    
    // Penting: Hapus gesture saat pindah scene agar tidak memory leak
    override func willMove(from view: SKView) {
        if let gestures = view.gestureRecognizers {
            for gesture in gestures {
                view.removeGestureRecognizer(gesture)
            }
        }
    }
}
