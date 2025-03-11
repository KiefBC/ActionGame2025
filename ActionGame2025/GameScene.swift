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
    private let opponentYOffset: CGFloat = -40
    private var opponentNormalTexture: SKTexture!
    private var opponentDeadTexture: SKTexture!
    
    var isGamePaused = false
    var pauseButton: SKLabelNode!
    var resumeButton: SKLabelNode?
    var pauseOverlay: SKShapeNode?
    
    override func didMove(to view: SKView) {
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
        
        // Position player at the bottom with padding
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
        
        setupPauseButton()
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
        
        // Stop all actions immediately
        opponentSprite.removeAllActions()
        
        // Add a visual feedback for collision
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
    
    func setupPauseButton() {
        pauseButton = SKLabelNode(fontNamed: "Arial")
        pauseButton.text = "PAUSE"
        pauseButton.fontSize = 24
        pauseButton.fontColor = SKColor.white
        
        // Position it in the middle top of the screen
        pauseButton.position = CGPoint(
            x: size.width / 2,
            y: size.height - 100
        )
        pauseButton.verticalAlignmentMode = .center
        pauseButton.horizontalAlignmentMode = .center
        
        // Get the approximate text size
        let textWidth = pauseButton.frame.width
        let textHeight = pauseButton.frame.height
        
        // Add padding
        let horizontalPadding: CGFloat = 30 // 15 points on each side
        let verticalPadding: CGFloat = 20   // 10 points on top and bottom
        
        // Create background with padding
        let backgroundWidth = textWidth + horizontalPadding
        let backgroundHeight = textHeight + verticalPadding
        
        let background = SKShapeNode(rectOf: CGSize(width: backgroundWidth, height: backgroundHeight), cornerRadius: 10)
        background.fillColor = SKColor.darkGray
        background.alpha = 0.7
        background.position = pauseButton.position
        background.zPosition = 10
        background.name = "pauseButtonBackground"
        
        // Make sure the text is on top of the background
        pauseButton.zPosition = 11
        pauseButton.name = "pauseButton"
        
        addChild(background)
        addChild(pauseButton)
    }
    
    func togglePause() {
        isGamePaused = !isGamePaused
        
        if isGamePaused {
            // Pause the game
            self.speed = 0
            
            // Create semi-transparent overlay
            let overlay = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
            overlay.fillColor = SKColor.black
            overlay.alpha = 0.5
            overlay.position = CGPoint(x: size.width/2, y: size.height/2)
            overlay.zPosition = 100
            overlay.name = "pauseOverlay"
            addChild(overlay)
            pauseOverlay = overlay
            
            // Create resume button
            let resume = SKLabelNode(fontNamed: "Arial")
            resume.text = "Resume"
            resume.fontSize = 30
            resume.fontColor = SKColor.white
            resume.position = CGPoint(x: size.width/2, y: size.height/2)
            resume.zPosition = 101
            resume.name = "resumeButton"
            addChild(resume)
            resumeButton = resume
        } else {
            // Resume the game
            self.speed = 1
            
            // Remove overlay and resume button
            pauseOverlay?.removeFromParent()
            pauseOverlay = nil
            resumeButton?.removeFromParent()
            resumeButton = nil
        }
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
        
        // Handle pause and resume button touches
        for t in touches {
            let location = t.location(in: self)
            
            // Check if pause button was tapped
            if !isGamePaused && pauseButton.contains(location) {
                togglePause()
                return
            }
            
            // Check if resume button was tapped
            if isGamePaused, let resumeButton = resumeButton, resumeButton.contains(location) {
                togglePause()
                return
            }
        }
        
        // Only process gameplay touches if not paused
        if !isGamePaused {
            for t in touches { self.touchDown(atPoint: t.location(in: self)) }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Only process gameplay touches if not paused
        if !isPaused {
            for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Only process gameplay touches if not paused
        if !isGamePaused {
            for t in touches { self.touchUp(atPoint: t.location(in: self)) }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Only process gameplay touches if not paused
        if !isGamePaused {
            for t in touches { self.touchUp(atPoint: t.location(in: self)) }
        }
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
        playerState = newState
        
        // Apply the appropriate texture/animation based on state
        switch playerState {
        case .idle:
            sprite.removeAllActions()
            sprite.texture = playerIdleTexture
        case .moving:
            sprite.run(playerMovingAnimation, withKey: "movingAnimation")
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if isGameOver || isPaused { return }
        
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
