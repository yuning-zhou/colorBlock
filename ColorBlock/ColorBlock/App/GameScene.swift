//
//  GameScene.swift
//  ColorBlock
//
//  Created by Zhou Yuning on 5/3/20.
//  Copyright © 2020 Zhou Yuning. All rights reserved.
//

import SpriteKit


class GameScene: SKScene {
    var block: SKSpriteNode!
    var matrix = [[SKSpriteNode?]](repeating: [SKSpriteNode?](repeating: nil, count: 14), count: 6)
    var column: Int!
    
    enum colorSchemes{
        static let colors = [
            UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1.0),
            UIColor(red: 241/255, green: 196/255, blue: 15/255, alpha: 1.0),
            UIColor(red: 52/255, green: 152/255, blue: 219/255, alpha: 1.0)
        ]
    }
    
    override func didMove(to view: SKView) {
        setPhysics()
        layoutScene()
        
        let swipeLeft : UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.swipeLeft))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
        
        let swipeRight : UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.swipeRight))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }
    
    @objc
    func swipeLeft(sender: UISwipeGestureRecognizer) {
        if (block.position.x - block.size.width*1.5 >= frame.minX){
            block.position.x -= block.size.width
            column -= 1
        }
    }
    
    @objc
    func swipeRight(sender: UISwipeGestureRecognizer) {
        if (block.position.x + block.size.width*1.5 <= frame.maxX){
            block.position.x += block.size.width
            column += 1
        }
    }
    
    func setPhysics(){
        physicsWorld.gravity = CGVector(dx: 0, dy: -1)
        physicsWorld.contactDelegate = self
    }
   
    func layoutScene(){
        backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 189/255, alpha: 1.0)
        spawnBlocks()
    }
    
    func spawnBlocks(){
        let blockColor = Int.random(in: 0 ..< 3)
        
        let factor = CGFloat(7)
        block = SKSpriteNode(texture: SKTexture(imageNamed: "block"), color: colorSchemes.colors[blockColor], size:CGSize(width: self.frame.size.width/factor, height: self.frame.size.width/factor))
        block.colorBlendFactor = 1.0
        block.name = "block"
        let storeInfo = NSMutableDictionary()
        storeInfo["color"] = blockColor
        block.userData = storeInfo
        
        
        // randomize x-position of spawn
        let index = Int.random(in: 0 ..< 6)
        column = index + 1
        let top = frame.maxY - block.size.width*2
        let xValue = frame.minX + CGFloat(Double(index) + 0.8) * block.size.width
        
        
        block.position = CGPoint(x: xValue, y: top)
        block.physicsBody = SKPhysicsBody(circleOfRadius: block.size.width/2)
        
     
        block.physicsBody?.friction = 0.0
        block.physicsBody?.restitution = 0.0
        //block.physicsBody?.usesPreciseCollisionDetection = true
        
        //block.physicsBody?.velocity = CGVector(dx: 0, dy: -3)
        
        
        let edgeFrame = CGRect(origin: CGPoint(x: frame.minX, y: frame.minY), size: CGSize(width: (self.view?.frame.width)!, height: (self.view?.frame.height)!))
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: edgeFrame)
        self.physicsBody?.restitution = 0.0
        
        
        
        let blockCategory:UInt32 = 0x1
        let frameCategory:UInt32 = 0x1 << 1
        self.physicsBody?.categoryBitMask = frameCategory
    
        block.physicsBody?.categoryBitMask = blockCategory
        block.physicsBody?.contactTestBitMask = blockCategory | frameCategory
        block.physicsBody?.collisionBitMask = blockCategory | frameCategory
    
        let xRange = SKRange(lowerLimit:0,upperLimit:size.width)
        let yRange = SKRange(lowerLimit:-20,upperLimit:size.height)
        block.constraints = [SKConstraint.positionX(xRange,y:yRange)]
        
        addChild(block)
    }
}

extension GameScene: SKPhysicsContactDelegate{
    
    func didBegin(_ contact: SKPhysicsContact) {
        // bottom || on top of other blocks
        
    
        let blockBottom = CGPoint(x: block.frame.origin.x + block.frame.width/2, y: block.frame.origin.y)
        
        let xDist = (contact.contactPoint.x - blockBottom.x)
        let yDist = (contact.contactPoint.y - blockBottom.y)
        let test = CGFloat(sqrt((xDist * xDist) + (yDist * yDist)))
        
        if (test < block.size.width/3){
            block.physicsBody?.pinned = true
            
            //let temp = SKSpriteNode.init()
            //temp.name = "temp"
            // add to matrix
            matrix[column - 1].append(block)
            
            //implement merging logic
            // check vertically
            //checkVertical()
            
            // check horizontally
            checkHorizontal()
            
            
            
            // call the next block
            self.spawnBlocks()
        }
        
    }
    func checkVertical(){
        let current = matrix[column - 1]
        if (current.count >= 3){
            // valid for a check
            let color1 = current[current.count - 1]?.userData?.value(forKey: "color")
            let color2 = current[current.count - 2]?.userData?.value(forKey: "color")
            let color3 = current[current.count - 3]?.userData?.value(forKey: "color")
            
            
            if (isEqual(type: Int.self, a: color1, b: color2) && isEqual(type: Int.self, a: color2, b: color3)){
                // remove blocks
                current[current.count - 3]?.removeFromParent()
                matrix[column - 1].remove(at: matrix[column - 1].count - 3)
                print("removed")
                
                current[current.count - 2]?.removeFromParent()
                matrix[column - 1].remove(at: matrix[column - 1].count - 2)
                print("removed")
                
                current[current.count - 1]?.removeFromParent()
                matrix[column - 1].remove(at: matrix[column - 1].count - 1)
                print("removed")
            }
            //print(current)
        }
    }
    
    func checkHorizontal(){
        let current = matrix[column - 1]
        if (column == 1){
            // leftmost column
            
            if (matrix[1].count >= current.count && matrix[2].count >= current.count){
                // valid for a check
                let color1 = current[current.count - 1]?.userData?.value(forKey: "color")
                let color2 = matrix[1][current.count - 1]?.userData?.value(forKey: "color")
                let color3 = matrix[2][current.count - 1]?.userData?.value(forKey: "color")
                
                
                if (isEqual(type: Int.self, a: color1, b: color2) && isEqual(type: Int.self, a: color2, b: color3)){
                    // cancel blocks
                    let index = current.count - 1
                    current[index]?.removeFromParent()
                    matrix[column - 1].remove(at: index)
                    print("removed")
                    
                    matrix[1][index]?.removeFromParent()
                    matrix[1].remove(at: index)
                    print("removed")
                    // shift down blocks
                    
                    matrix[2][index]?.removeFromParent()
                    matrix[2].remove(at: index)
                    print("removed")
                    // shift down blocks
                }
            }
            
            
        }
        
        else if (column == 6){
            // rightmost column
            
            if (matrix[4].count >= current.count && matrix[3].count >= current.count){
                // valid for a check
                let color1 = current[current.count - 1]?.userData?.value(forKey: "color")
                let color2 = matrix[4][current.count - 1]?.userData?.value(forKey: "color")
                let color3 = matrix[5][current.count - 1]?.userData?.value(forKey: "color")
                
                
                if (isEqual(type: Int.self, a: color1, b: color2) && isEqual(type: Int.self, a: color2, b: color3)){
                    // cancel blocks
                    let index = current.count - 1
                    current[index]?.removeFromParent()
                    matrix[column - 1].remove(at: index)
                    print("removed")
                    
                    matrix[4][index]?.removeFromParent()
                    matrix[4].remove(at: index)
                    print("removed")
                    // shift down blocks
                    
                    matrix[5][index]?.removeFromParent()
                    matrix[5].remove(at: index)
                    print("removed")
                    // shift down blocks
                }
            }
            
        } else {
            // middle columns
            switch(column){
                case 2:
                    // test for rightside
                    if (matrix[2].count >= current.count){
                        // valid for a check
                        // test for both 123 and 234
                        if (matrix[0].count >= current.count){
                             // case 123
                            
                        }
                       
                        
                }
                
                
                
                
                
                
                case 3:
                    leftCol = array2
                    rightCol = array4
                case 4:
                    leftCol = array3
                    rightCol = array5
                case 5:
                    leftCol = array4
                default:
                    break
            }
            
            if (leftCol.count >= current.count && rightCol.count >= current.count){
                // valid for a check
                print("leftcol: ")
                print(leftCol.count)
                print("rightcol: ")
                print(rightCol.count)
                print(current.count)
                let color1 = current[current.count - 1].userData?.value(forKey: "color")
                let color2 = leftCol[current.count - 1].userData?.value(forKey: "color")
                let color3 = rightCol[current.count - 1].userData?.value(forKey: "color")
                
                
                if (isEqual(type: Int.self, a: color1, b: color2) && isEqual(type: Int.self, a: color2, b: color3)){
                    // cancel blocks
                    removeBlock(array: &current, index: current.count - 1);
                    removeBlock(array: &leftCol, index: current.count - 1);
                    removeBlock(array: &rightCol, index: current.count - 1);
                }
            }
        }*/
    }
    
 
 
    // compare Any type, code snipet from https://stackoverflow.com/questions/34778950/how-to-compare-any-value-types
    func isEqual<T: Equatable>(type: T.Type, a: Any, b: Any) -> Bool {
        guard let a = a as? T, let b = b as? T else { return false }

        return a == b
    }
    
}
