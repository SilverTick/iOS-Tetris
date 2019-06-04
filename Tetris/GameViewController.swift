//
//  GameViewController.swift
//  Tetris
//
//  Created by Elliot Tan on 3/6/19.
//  Copyright © 2019 Elliot Tan. All rights reserved.
//

import UIKit

enum Color: Int {
    case blue = 0, orange, purple, red, teal, yellow
}

enum Shape: Int {
    case square = 0, t, line, l, j, s, z
}

enum Direction {
    case left, right, down
}

class GameViewController: UIViewController {
    var gameRows: Int = 15
    var gameColumns: Int = 10
    var gameGrid: [[Square?]]?
    var topBottomInset: CGFloat = 5.0
    
    var squareSize: CGFloat = 0.0
    var gameBoard: UIView?
    
    // Squares that are currently dropping
    var squaresInPlay: [Square] = []
    
    var fallTimer = Timer()
    var fallTime = 0.5
    
    let semaphore = DispatchSemaphore(value: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func startGame(_ sender: UIButton) {
        initGame()
        sender.removeFromSuperview()
    }
}

private extension GameViewController {
    func initGame() {
        if let gameBoard = gameBoard { gameBoard.removeFromSuperview() }
        
        // Grid square sizes
        let newGameBoard = UIView(frame: view.safeAreaLayoutGuide.layoutFrame)
        squareSize = newGameBoard.frame.width / 10
        newGameBoard.frame.size.height = squareSize * CGFloat(gameRows) + topBottomInset * 2
        gameBoard = newGameBoard
        gameBoard?.backgroundColor = .gray
        view.addSubview(gameBoard!)
        
        // Initalize 20x10 game grid
        gameGrid = []
        for i in 0..<gameRows {
            gameGrid!.append([])
            for _ in 0..<gameColumns {
                gameGrid![i].append(nil)
            }
        }
        
        // Initialize gesture recognizers
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(applyHorizontalMovement(_:)))
        swipeLeft.direction = .left
        gameBoard?.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(applyHorizontalMovement(_:)))
        swipeRight.direction = .right
        gameBoard?.addGestureRecognizer(swipeRight)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(applyForceDown(_:)))
        swipeDown.direction = .down
        gameBoard?.addGestureRecognizer(swipeDown)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(applyRotation(_:)))
        gameBoard?.addGestureRecognizer(tap)
        
        // Start dropping tiles
        newShape()
    }
    
    func newShape() {
        // Choose color
        let color = chooseRandomColor()
        
        // Choose shape
        var newSquaresInPlay: [(row: Int, column: Int)] = []
        let shape = chooseRandomShape()
        
        switch shape {
        case .square:
            newSquaresInPlay = [(row: 0, column: 0), (row: 0, column: 1), (row: 1, column: 0), (row: 1, column: 1)]
        case .line:
            newSquaresInPlay = [(row: 0, column: 0), (row: 0, column: 1), (row: 0, column: 2), (row: 0, column: 3)]
        case .t:
            newSquaresInPlay = [(row: 0, column: 0), (row: 0, column: 1), (row: 0, column: 2), (row: 1, column: 1)]
        case .l:
            newSquaresInPlay = [(row: 0, column: 0), (row: 0, column: 1), (row: 0, column: 2), (row: 1, column: 0)]
        case .j:
            newSquaresInPlay = [(row: 0, column: 0), (row: 0, column: 1), (row: 0, column: 2), (row: 1, column: 2)]
        case .s:
            newSquaresInPlay = [(row: 0, column: 1), (row: 0, column: 2), (row: 1, column: 0), (row: 1, column: 1)]
        case .z:
            newSquaresInPlay = [(row: 0, column: 0), (row: 0, column: 1), (row: 1, column: 1), (row: 1, column: 2)]
        }
        
        // Add shape to gameboard view and game grid
        for square in newSquaresInPlay {
            let squareView = Square(color: color, size: squareSize)
            squareView.row = square.row
            squareView.column = square.column
            gameGrid![square.row][square.column] = squareView
            
            let x = CGFloat(square.column) * squareSize
            let y = CGFloat(square.row) * squareSize
            squareView.frame.origin = CGPoint(x: x, y: y)
            gameBoard?.addSubview(squareView)
            squaresInPlay.append(squareView)
        }
        
        // Start fall timer
        fallTimer.invalidate()
        fallTimer = Timer.scheduledTimer(withTimeInterval: fallTime, repeats: true, block: { _ in self.applyGravity() })
    }
    
    func applyGravity() {
        semaphore.wait()
        
        var shapeCanDrop = true
        var bottomRowOfShape: Int?
        
        for square in squaresInPlay.sorted(by: { $0.row > $1.row }) {
            if bottomRowOfShape == nil || square.row == bottomRowOfShape {
                if square.row == gameRows - 1 || gameGrid?[square.row + 1][square.column] != nil {
                    shapeCanDrop = false
                }
                bottomRowOfShape = square.row
            }
        }
        
        // Shape has reached the bottom
        if !shapeCanDrop {
            squaresInPlay = []
            fallTimer.invalidate()
            newShape()
        }
        // Shape still can drop
        else { moveShapesInPlay(direction: .down)}
        
        semaphore.signal()
    }
    
    @objc func applyHorizontalMovement(_ sender: UISwipeGestureRecognizer) {
        var shapeCanMove = true
        if sender.direction == .left {
            var leftColOfShape: Int?
            
            let squaresInPlaySorted = squaresInPlay.sorted { $0.column < $1.column }
            for square in squaresInPlaySorted {
                if leftColOfShape == nil || square.column == leftColOfShape {
                    if square.column == 0 || gameGrid?[square.row][square.column - 1] != nil {
                        shapeCanMove = false
                    }
                    leftColOfShape = square.column
                }
            }
            if shapeCanMove { moveShapesInPlay(direction: .left) }
        } else if sender.direction == .right {
            var rightColOfShape: Int?
            
            let squaresInPlaySorted = squaresInPlay.sorted { $0.column > $1.column }
            for square in squaresInPlaySorted {
                if rightColOfShape == nil || square.column == rightColOfShape {
                    if square.column == gameColumns - 1 || gameGrid?[square.row][square.column + 1] != nil {
                        shapeCanMove = false
                    }
                    rightColOfShape = square.column
                }
            }
            if shapeCanMove { moveShapesInPlay(direction: .right) }
        }
    }
    
    @objc func applyRotation(_ sender: UITapGestureRecognizer) {
        // Find current positions of shape
//        for c in 0..<gameColumns {
//            for r in 0..<gameRows {
//                if let squareHere = gameGrid?[r][c], squaresInPlay.contains(squareHere) {
//                    leftRowOfShape = c
//                    if c == 0 || gameGrid?[r][c - 1] != nil {
//                        shapeCanMove = false
//                    }
//                }
//            }
//
//            if leftRowOfShape != nil { break }
//        }
    }
    
    @objc func applyForceDown(_ sender: UISwipeGestureRecognizer) {
        applyGravity()
    }
    
    func moveShapesInPlay(direction: Direction) {
        var squaresInPlaySorted = squaresInPlay
        var dr = 0
        var dc = 0
        
        switch direction {
        case .down:
            squaresInPlaySorted = squaresInPlay.sorted { $0.row > $1.row }
            dr = 1
        case .left:
            squaresInPlaySorted = squaresInPlay.sorted { $0.column < $1.column }
            dc = -1
        case .right:
            squaresInPlaySorted = squaresInPlay.sorted { $0.column > $1.column }
            dc = 1
        }
        
        for square in squaresInPlaySorted {
            gameGrid?[square.row][square.column] = nil
            square.row += dr
            square.column += dc
            gameGrid?[square.row][square.column] = square
            square.frame.origin = CGPoint(x: CGFloat(square.column) * squareSize,
                                          y: CGFloat(square.row) * squareSize)
        }
    }
    
    func chooseRandomShape() -> Shape {
        guard let shape = Shape(rawValue: Int.random(in: 0..<7)) else {
            fatalError("Unable to choose a shape")
        }
        return shape
    }
    
    func chooseRandomColor() -> Color {
        guard let color = Color(rawValue: Int.random(in: 0..<6)) else {
            fatalError("Unable to choose a color")
        }
        return color
    }
}
