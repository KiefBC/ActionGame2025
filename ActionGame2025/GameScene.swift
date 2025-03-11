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
    
    var isGameOver = false
    var gameOverLabel: SKLabelNode?
    var restartButton: SKLabelNode?
    
    let playerCategory: UInt32 = 0x1 << 0 // Category for player sprite (1)
    let opponentCategory: UInt32 = 0x1 << 1 // Category for opponent sprite (2)
    
    // Player sprite states
    enum PlayerState {
        case idle
        case moving
    }
    
    // Current state of the player
    private var playerState: PlayerState = .idle
    
    // Player sprite textures
    private var playerIdleTexture: SKTexture!
    private var playerMovingTextures: [SKTexture] = []
    private var playerMovingAnimation: SKAction!
    
    // Target X position for player movement
    private var targetX: CGFloat?
    private var lastUpdateTime: TimeInterval = 0
    private let playerMaxSpeed: CGFloat = 800.0  // Speed in points per second
    private let playerAcceleration: CGFloat = 1500.0 // Acceleration in points per second²
    private let playerDeceleration: CGFloat = 2000.0 // Deceleration in points per second²
    private var playerVelocity: CGFloat = 0.0
    
    // Bottom padding value used for player positioning
    private let bottomPadding: CGFloat = 20
        
    // Offset between opponent stop position and player position
    // Positive values make the opponent stop above the player level
    // Negative values make the opponent go slightly below player level
    private let opponentYOffset: CGFloat = -40    // Opponent sprites
    private var opponentNormalTexture: SKTexture!
    private var opponentDeadTexture: SKTexture!//
    
    override func didMove(to view: SKView) {
        // Disable gravity as we're manually controlling movement
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        // Load player textures
        playerIdleTexture = SKTexture(imageNamed: "PlayerSprite")
        playerMovingTextures = [
            SKTexture(imageNamed: "PlayerSprite_Moving"),
            SKTexture(imageNamed: "PlayerSprite_Moving2")
        ]
        
        // Load opponent textures
        opponentNormalTexture = SKTexture(imageNamed: "OpponentSprite")
        opponentDeadTexture = SKTexture(imageNamed: "OpponentSprite_Dead")
        
        // Create animation for moving state
        playerMovingAnimation = SKAction.repeatForever(
            SKAction.animate(with: playerMovingTextures,
                             timePerFrame: 0.2, // Adjust speed as needed
                             resize: false,
                             restore: true)
        )
        
        // Initialize the player sprite with idle texture
        sprite = SKSpriteNode(texture: playerIdleTexture)
        sprite.size = CGSize(width: 200, height: 200)
        // Position at bottom with padding
        sprite.position = CGPoint(
            x: size.width / 2,
            y: sprite.size.height/2 + bottomPadding
        )
        sprite.name = "player"
        
        // Setup physics for player sprite
        sprite.physicsBody = SKPhysicsBody(
            circleOfRadius: sprite.size.width / 2 - 10
        )
        sprite.physicsBody?.isDynamic = true
        sprite.physicsBody?.affectedByGravity = false
        sprite.physicsBody?.categoryBitMask = playerCategory
        sprite.physicsBody?.contactTestBitMask = opponentCategory
        sprite.physicsBody?.collisionBitMask = 0 // No physical collisions
        addChild(sprite)
        
        // Initialize the opponent sprite
        opponentSprite = SKSpriteNode(texture: opponentNormalTexture)
        opponentSprite.size = CGSize(width: 100, height: 100)
        opponentSprite.name = "opponent"
        
        // Setup physics for opponent sprite
        opponentSprite.physicsBody = SKPhysicsBody(
            circleOfRadius: opponentSprite.size.width / 2 - 10
        )
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
        hitCounterLabel.position = CGPoint(
            x: size.width / 2,
            y: size.height - 50
        )
        addChild(hitCounterLabel)
    }
    
    func startOpponentMovement() {
        // Ensure the opponent has the normal texture
        opponentSprite.texture = opponentNormalTexture
        
        // Reset position to top with random X coordinate
        let randomX = CGFloat.random(in: 50...(size.width - 50))
        opponentSprite.position = CGPoint(
            x: randomX,
            y: size.height + opponentSprite.size.height
        )
        
        // Choose a random falling duration between 1.5 and 4 seconds
        let duration = Double.random(in: 1.5...4.0)
        print("Opponent falling for \(duration) seconds...")
        
        // Get the player's Y position to stop the opponent at that level
        let playerY = sprite.size.height/2 + bottomPadding
        
        // Apply the offset to determine where the opponent stops
        let opponentStopY = playerY + opponentYOffset
        
        // Create an action to move the opponent down to the player's level (with offset)
        let moveDown = SKAction.moveTo(y: opponentStopY, duration: duration)
        
        // After reaching the bottom, show dead sprite and flash before resetting
        let reachedBottomAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.handleOpponentReachedBottom()
        }
        
        let sequence = SKAction.sequence([moveDown, reachedBottomAction])
        opponentSprite.run(sequence, withKey: "fallingMovement")
    }
    
    func handleOpponentReachedBottom() {
        print("Opponent reached the bottom")
        
        // Change to dead texture
        opponentSprite.texture = opponentDeadTexture
        
        // Create flashing animation
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        
        // Repeat the flash a few times
        let flashRepeat = SKAction.repeat(flash, count: 3)
        
        // Update the score
        hitCount -= 1
        hitCounterLabel.text = "Score: \(hitCount)"
        
        // After flashing is complete, check for game over
        let checkGameOver = SKAction.run { [weak self] in
            guard let self = self else { return }
            if self.hitCount < 0 {
                self.gameOver()
            } else {
                // Only start new movement if the game isn't over
                self.startOpponentMovement()
            }
        }
        
        // Run the sequence: first flash, then check for game over
        let completeSequence = SKAction.sequence([flashRepeat, checkGameOver])
        opponentSprite.run(completeSequence)
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
        
        if hitCount < 0 {
            gameOver()
            return
        }
        
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
    
    func gameOver() {
        isGameOver = true
        // Stop opponent movement
        opponentSprite.removeAllActions()
        
        // Create and show 'Game Over' label
        gameOverLabel = SKLabelNode(text: "Game Over")
        gameOverLabel?.fontName = "Arial"
        gameOverLabel?.fontSize = 40
        gameOverLabel?.fontColor = SKColor.red
        gameOverLabel?.position = CGPoint(x: size.width / 2, y: size.height / 2 + 20)
        if let gameOverLabel = gameOverLabel {
            addChild(gameOverLabel)
        }
        
        // Create and show 'Restart' button underneath the Game Over label
        restartButton = SKLabelNode(text: "Restart")
        restartButton?.fontName = "Arial"
        restartButton?.fontSize = 30
        restartButton?.fontColor = SKColor.white
        restartButton?.position = CGPoint(x: size.width / 2, y: size.height / 2 - 40)
        if let restartButton = restartButton {
            addChild(restartButton)
        }
    }
    
    func restartGame() {
        // Create a new instance of the game scene and present it
        let newScene = GameScene(size: self.size)
        newScene.scaleMode = self.scaleMode
        self.view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 1.0))
    }
    
    func touchDown(atPoint pos: CGPoint) {
        // Not used in this implementation
    }
    
    func touchMoved(toPoint pos: CGPoint) {
        // Get the target position (just the X value)
        let targetX = pos.x
        movePlayerWithVelocity(to: targetX)
    }
    
    func touchUp(atPoint pos: CGPoint) {
        // Get the target position (just the X value)
        let targetX = pos.x
        movePlayerWithVelocity(to: targetX)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            for t in touches {
                let location = t.location(in: self)
                if let restartButton = restartButton, restartButton.contains(location) {
                    restartGame()
                }
            }
            return
        }
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    func movePlayerWithVelocity(to xPosition: CGFloat) {
        // Set the target X position
        targetX = xPosition
        
        // Change to moving state
        updatePlayerState(.moving)
    }
    
    func updatePlayerState(_ newState: PlayerState) {
        // Only update if the state is changing
        guard newState != playerState else { return }
        
        // Update the state
        playerState = newState
        
        // Apply the appropriate texture/animation based on state
        switch playerState {
        case .idle:
            // Stop any running animations
            sprite.removeAllActions()
            sprite.texture = playerIdleTexture
        case .moving:
            // Start the moving animation
            sprite.run(playerMovingAnimation, withKey: "movingAnimation")
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if isGameOver { return }
        
        // Calculate delta time
        let dt: TimeInterval
        if lastUpdateTime == 0 {
            dt = 0
        } else {
            dt = currentTime - lastUpdateTime
        }
        lastUpdateTime = currentTime
        
        // Apply velocity-based movement
        if let targetX = targetX {
            // Calculate distance to target
            let distanceToTarget = targetX - sprite.position.x
            let distanceSign = distanceToTarget > 0 ? 1.0 : -1.0
            
            // Flip sprite based on movement direction
            if distanceToTarget > 0 {
                // Moving right - normal orientation (no flip)
                sprite.xScale = abs(sprite.xScale)
            } else if distanceToTarget < 0 {
                // Moving left - flip horizontally
                sprite.xScale = -abs(sprite.xScale)
            }
            
            // If we're very close to the target, just snap to it and stop
            if abs(distanceToTarget) < 5.0 {
                sprite.position = CGPoint(
                    x: targetX,
                    y: sprite.size.height/2 + bottomPadding
                )
                playerVelocity = 0
                self.targetX = nil
                
                // Change to idle state when we've reached the target
                updatePlayerState(.idle)
                return
            }
            
            // Make sure we're in moving state while moving
            if playerState != .moving && abs(playerVelocity) > 10 {
                updatePlayerState(.moving)
            }
            
            // Calculate desired acceleration based on distance
            let desiredAccel = distanceSign * playerAcceleration * CGFloat(dt)
            
            // Apply acceleration to velocity
            playerVelocity += desiredAccel
            
            // Cap velocity at max speed
            playerVelocity = min(
                max(-playerMaxSpeed, playerVelocity),
                playerMaxSpeed
            )
            
            // Calculate stopping distance at current velocity
            let stoppingDistance = (playerVelocity * playerVelocity) / (
                2 * playerDeceleration
            )
            
            // If we're going to overshoot, apply deceleration
            if abs(distanceToTarget) <= stoppingDistance &&
                (distanceToTarget > 0) == (playerVelocity > 0) {
                let deceleration = -distanceSign * playerDeceleration * CGFloat(
                    dt
                )
                playerVelocity += deceleration
                
                // If velocity changes direction, we've overdecelerated, just stop
                if (playerVelocity > 0) != (distanceToTarget > 0) {
                    playerVelocity = 0
                }
            }
            
            // Apply velocity to position
            let newX = sprite.position.x + playerVelocity * CGFloat(dt)
            sprite.position = CGPoint(
                x: newX,
                y: sprite.size.height/2 + bottomPadding
            )
        } else {
            // No target means we're idle
            if playerState != .idle && abs(playerVelocity) < 10 {
                updatePlayerState(.idle)
            }
        }
    }
}
