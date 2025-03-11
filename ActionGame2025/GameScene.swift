//
//  GameScene.swift
//  ActionGame2025
//
//  Created by Kiefer Hay on 2025-03-10.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var sprite: SKSpriteNode! // Player sprite
    var opponentSprite: SKSpriteNode! // Opponent sprite (declared at the class level)
    var hitCounterLabel: SKLabelNode! // Label to track number of hits
    var hitCount: Int = 0 // Variable to store the number of hits
    
    let spriteCategory1: UInt32 = 0b1 // Category for player sprite
    let spriteCategory2: UInt32 = 0b10 // Category for opponent sprite
    
    override func didMove(to view: SKView) {
        sprite = SKSpriteNode(imageNamed: "PlayerSprite") // Initialize the player sprite
        sprite.position = CGPoint(x: size.width / 2, y: size.height / 2) // Set position
        sprite.size = CGSize(width: 200, height: 200) // Set size
        addChild(sprite) // Add to scene
        
        opponentSprite = SKSpriteNode(imageNamed: "OpponentSprite")
        opponentSprite.position = CGPoint(x: size.width / 2, y: size.height / 2)
        opponentSprite.size = CGSize(width: 100, height: 100)
        addChild(opponentSprite)

        moveOpponent() // Start opponent movement
        
        hitCounterLabel = SKLabelNode(fontNamed: "Arial")
        hitCounterLabel.text = "Hits: 0"
        hitCounterLabel.fontSize = 24
        hitCounterLabel.fontColor = SKColor.white
        hitCounterLabel.position = CGPoint(x: size.width / 2, y: size.height - 50)
        addChild(hitCounterLabel)

        sprite.physicsBody = SKPhysicsBody(circleOfRadius: 50) // Assign physics body
        opponentSprite.physicsBody = SKPhysicsBody(circleOfRadius: 50) // Assign physics body
        
        sprite.physicsBody?.categoryBitMask = spriteCategory1
        sprite.physicsBody?.contactTestBitMask = spriteCategory1
        sprite.physicsBody?.collisionBitMask = spriteCategory1

        opponentSprite.physicsBody?.categoryBitMask = spriteCategory1
        opponentSprite.physicsBody?.contactTestBitMask = spriteCategory1
        opponentSprite.physicsBody?.collisionBitMask = spriteCategory1
        
        self.physicsWorld.contactDelegate = self // Assign physics contact delegate
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Check if the player and opponent have collided
        if (contact.bodyA.categoryBitMask == spriteCategory1 && contact.bodyB.categoryBitMask == spriteCategory1) ||
           (contact.bodyB.categoryBitMask == spriteCategory1 && contact.bodyA.categoryBitMask == spriteCategory1) {
            hitCount += 1
            hitCounterLabel.text = "Hits: \(hitCount)"
            print("Hit detected! Total hits: \(hitCount)")
        }
    }
    
    
    func moveOpponent() {
        let randomX = GKRandomSource.sharedRandom().nextInt(upperBound: Int(size.width))
        let randomY = GKRandomSource.sharedRandom().nextInt(upperBound: Int(size.height))
        let movement = SKAction.move(to: CGPoint(x: randomX, y: randomY), duration: 1)
        
        // Move opponent and recursively call moveOpponent to keep moving
        opponentSprite.run(movement, completion: { [unowned self] in
            self.moveOpponent()
        })
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        // Something
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        // Something
    }
    
    func touchUp(atPoint pos : CGPoint) {
        sprite.run(SKAction.move(to: pos, duration: 0.1))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
