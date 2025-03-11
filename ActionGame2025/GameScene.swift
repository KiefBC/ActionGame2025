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
    var opponentSprite: SKSpriteNode! // Opponent sprite
    var hitCounterLabel: SKLabelNode! // Label to track number of hits
    var hitCount: Int = 0 // Variable to store the number of hits
    
    let playerCategory: UInt32 = 0x1 << 0 // Category for player sprite (1)
    let opponentCategory: UInt32 = 0x1 << 1 // Category for opponent sprite (2)
    
    override func didMove(to view: SKView) {
        // Disable gravity as we're manually controlling movement
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        // Initialize the player sprite
        sprite = SKSpriteNode(imageNamed: "PlayerSprite")
        sprite.size = CGSize(width: 200, height: 200)
        // Position at bottom with padding
        let bottomPadding: CGFloat = 20
        sprite.position = CGPoint(x: size.width / 2, y: sprite.size.height/2 + bottomPadding)
        sprite.name = "player"
        
        // Setup physics for player sprite
        sprite.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2 - 10)
        sprite.physicsBody?.isDynamic = true
        sprite.physicsBody?.affectedByGravity = false
        sprite.physicsBody?.categoryBitMask = playerCategory
        sprite.physicsBody?.contactTestBitMask = opponentCategory
        sprite.physicsBody?.collisionBitMask = 0 // No physical collisions
        addChild(sprite)
        
        // Initialize the opponent sprite
        opponentSprite = SKSpriteNode(imageNamed: "OpponentSprite")
        opponentSprite.size = CGSize(width: 100, height: 100)
        opponentSprite.name = "opponent"
        
        // Setup physics for opponent sprite
        opponentSprite.physicsBody = SKPhysicsBody(circleOfRadius: opponentSprite.size.width / 2 - 10)
        opponentSprite.physicsBody?.isDynamic = true
        opponentSprite.physicsBody?.affectedByGravity = false
        opponentSprite.physicsBody?.categoryBitMask = opponentCategory
        opponentSprite.physicsBody?.contactTestBitMask = playerCategory
        opponentSprite.physicsBody?.collisionBitMask = 0 // No physical collisions
        addChild(opponentSprite)
        
        // Start opponent movement
        startOpponentMovement()
        
        // Create a label to display the Score Count
        hitCounterLabel = SKLabelNode(fontNamed: "Arial")
        hitCounterLabel.text = "Score: 0"
        hitCounterLabel.fontSize = 24
        hitCounterLabel.fontColor = SKColor.white
        hitCounterLabel.position = CGPoint(x: size.width / 2, y: size.height - 50)
        addChild(hitCounterLabel)
    }
    
    func startOpponentMovement() {
        // Reset position to top with random X coordinate
        let randomX = CGFloat.random(in: 50...(size.width - 50))
        opponentSprite.position = CGPoint(x: randomX, y: size.height + opponentSprite.size.height)
        
        // Choose a random falling duration between 1.5 and 4 seconds
        let duration = Double.random(in: 1.5...4.0)
        print("Opponent falling for \(duration) seconds...")
        
        // Create an action to move the opponent down to below the bottom of the screen
        let moveDown = SKAction.moveTo(y: -opponentSprite.size.height, duration: duration)
        
        // After reaching the bottom, reposition and start falling again
        let resetAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.startOpponentMovement()
            print("Opponent reached the bottom and reset.")
        }
        
        let sequence = SKAction.sequence([moveDown, resetAction])
        opponentSprite.run(sequence, withKey: "fallingMovement")
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Determine which body is which
        let firstBody: SKPhysicsBody
        let secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // Player hit opponent
        if firstBody.categoryBitMask == playerCategory && secondBody.categoryBitMask == opponentCategory {
            handleCollision()
        }
    }
    
    func handleCollision() {
        hitCount += 1
        hitCounterLabel.text = "Score: \(hitCount)"
        print("Hit detected! Total Score: \(hitCount)")
        
        // Important: Stop all actions immediately
        opponentSprite.removeAllActions()
        
        // Add a visual feedback for collision (optional)
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        opponentSprite.run(flash)
        
        // Reset the opponent's position and movement with a slight delay
        // This ensures all previous actions are completely cleared
        let resetDelay = SKAction.wait(forDuration: 0.2)
        let resetAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.startOpponentMovement()
            print("Opponent reset after collision")
        }
        
        opponentSprite.run(SKAction.sequence([resetDelay, resetAction]))
    }
    
    func touchDown(atPoint pos: CGPoint) {
        // Not used in this implementation
    }
    
    func touchMoved(toPoint pos: CGPoint) {
        // Update player position immediately when touch moves (horizontally only)
        // Keep the fixed y position at the bottom
        let bottomPadding: CGFloat = 20
        sprite.position = CGPoint(x: pos.x, y: sprite.size.height/2 + bottomPadding)
    }
    
    func touchUp(atPoint pos: CGPoint) {
        // Move the player to the touch position (horizontally only)
        // Maintain the fixed y position at the bottom
        let bottomPadding: CGFloat = 20
        let newPosition = CGPoint(x: pos.x, y: sprite.size.height/2 + bottomPadding)
        sprite.run(SKAction.move(to: newPosition, duration: 0.1))
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
