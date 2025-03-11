//
//  GameScene.swift
//  ActionGame2025
//
//  Created by Kiefer Hay on 2025-03-10.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var sprite : SKSpriteNode!
    
    let spriteCategory1: UInt32 = 0b1
    let spriteCategory2: UInt32 = 0b10
    
    override func didMove(to view: SKView) {
        sprite = SKSpriteNode(imageNamed: "PlayerSprite") // Initialize the player sprite with the image "PlayerSprite"
        sprite.position = CGPoint(x: size.width / 2, y: size.height / 2) // Set the player's starting position to the center of the screen
        sprite.size = CGSize(width: 50, height: 50) // Set the player's size
        addChild(sprite) // Add the player sprite to the scene
        
        let opponentSprite = SKSpriteNode(imageNamed: "OpponentSprite")
        opponentSprite.position = CGPoint(x: size.width / 2, y: size.height / 2)
        opponentSprite.size = CGSize(width: 50, height: 50)
        addChild(opponentSprite)
        
        // Define a movement action to move the opponent down to the bottom of the screen
        let downMovement = SKAction.move(to: CGPoint(x: size.width / 2, y: 0), duration: 1.75)
        // Define a movement action to move the opponent back up to the top of the screen
        let upMovement = SKAction.move(to: CGPoint(x: size.width / 2, y: size.height), duration: 1.5)
        let movement = SKAction.sequence([downMovement, upMovement]) // Combine the two movement actions into a sequence
        // Run the movement action on the opponent sprite in an infinite loop
        opponentSprite.run(SKAction.repeatForever(movement))
        
        sprite.physicsBody = SKPhysicsBody(circleOfRadius: 50) // Set the player sprite's physics body to a circle with a radius of 50
        opponentSprite.physicsBody = SKPhysicsBody(circleOfRadius: 50) // Set the opponent sprite's physics body to a circle with a radius of 50
        
        sprite.physicsBody?.categoryBitMask = spriteCategory1
        sprite.physicsBody?.contactTestBitMask = spriteCategory1
        sprite.physicsBody?.collisionBitMask = spriteCategory1
        opponentSprite.physicsBody?.categoryBitMask = spriteCategory1
        opponentSprite.physicsBody?.contactTestBitMask = spriteCategory1
        opponentSprite.physicsBody?.collisionBitMask = spriteCategory1
        
        self.physicsWorld.contactDelegate = self
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        print("Contact detected")
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
