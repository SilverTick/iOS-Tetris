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

let TESTING = false

class GameViewController: UIViewController {
    var gameRows: Int = 17
    var gameColumns: Int = 10
    var gameGrid: [[Square?]]?
    var topBottomInset: CGFloat = 5.0
    
    var squareSize: CGFloat = 0.0
    var gameBoard: UIView?
    
    // Squares that are currently dropping
    var squaresInPlay: [Square] = []
    var squaresInPlayCenter: (row: Int, column: Int)?
    
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
        gameBoard?.backgroundColor = .white
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
    
    func drawGameBoard() {
        if TESTING {
            let labels = gameBoard?.subviews.flatMap { $0 as? UILabel }
            if let labels = labels {
                for label in labels {
                    label.removeFromSuperview()
                }
            }
            
            for r in 0..<gameRows {
                for c in 0..<gameColumns {
                    if gameGrid?[r][c] != nil {
                        let label = UILabel(frame: CGRect(x: CGFloat(c) * squareSize,
                                                          y: CGFloat(r) * squareSize,
                                                          width: squareSize,
                                                          height: squareSize))
                        label.text = "T"
                        gameBoard?.addSubview(label)
                    }
                }
            }
        }
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
            squaresInPlayCenter = (row: 0, column: 1)
        case .t:
            newSquaresInPlay = [(row: 0, column: 0), (row: 0, column: 1), (row: 0, column: 2), (row: 1, column: 1)]
            squaresInPlayCenter = (row: 0, column: 1)
        case .l:
            newSquaresInPlay = [(row: 0, column: 0), (row: 0, column: 1), (row: 0, column: 2), (row: 1, column: 0)]
            squaresInPlayCenter = (row: 0, column: 1)
        case .j:
            newSquaresInPlay = [(row: 0, column: 0), (row: 0, column: 1), (row: 0, column: 2), (row: 1, column: 2)]
            squaresInPlayCenter = (row: 0, column: 1)
        case .s:
            newSquaresInPlay = [(row: 0, column: 1), (row: 0, column: 2), (row: 1, column: 0), (row: 1, column: 1)]
            squaresInPlayCenter = (row: 0, column: 1)
        case .z:
            newSquaresInPlay = [(row: 0, column: 0), (row: 0, column: 1), (row: 1, column: 1), (row: 1, column: 2)]
            squaresInPlayCenter = (row: 0, column: 1)
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
        
        for square in squaresInPlay.sorted(by: { $0.row > $1.row }) {
            if square.row == gameRows - 1
                || (gameGrid?[square.row + 1][square.column] != nil
                    && !squaresInPlay.contains((gameGrid?[square.row + 1][square.column])!)) {
                shapeCanDrop = false
            }
        }
        
        // Shape has reached the bottom
        if !shapeCanDrop {
            squaresInPlay = []
            fallTimer.invalidate()
            checkLines()
            newShape()
        }
            // Shape still can drop
        else { moveShapesInPlay(direction: .down) }
        
        drawGameBoard()
        semaphore.signal()
    }
    
    func checkLines() {
        var r = 0
        while r < gameRows {
            var rowFilled = true
            for c in 0..<gameColumns {
                if gameGrid?[r][c] == nil {
                    rowFilled = false
                    break
                }
            }
            
            if rowFilled {
                for c in 0..<gameColumns {
                    if let square = gameGrid?[r][c] {
                        square.removeFromSuperview()
                        gameGrid?[r][c] = nil
                    }
                }
                shiftAllLinesDown(fromRow: r)
            } else {
                r += 1
            }
        }
    }
    
    func shiftAllLinesDown(fromRow: Int) {
        for r in (1...fromRow).reversed() {
            for c in 0..<gameColumns {
                if let square = gameGrid?[r - 1][c], !squaresInPlay.contains(square) {
                    gameGrid?[r][c] = square
                    gameGrid?[r - 1][c] = nil
                    square.row += 1
                    square.frame.origin = CGPoint(x: CGFloat(square.column) * squareSize,
                                                  y: CGFloat(square.row) * squareSize)
                }
            }
        }
        
        drawGameBoard()
    }
    
    @IBAction func applyHorizontalMovement(_ sender: UISwipeGestureRecognizer) {
        var shapeCanMove = true
        if sender.direction == .left {
            let squaresInPlaySorted = squaresInPlay.sorted { $0.column < $1.column }
            for square in squaresInPlaySorted {
                if square.column == 0
                    || (gameGrid?[square.row][square.column - 1] != nil
                        && !squaresInPlay.contains((gameGrid?[square.row][square.column - 1])!)) {
                    shapeCanMove = false
                }
            }
            if shapeCanMove { moveShapesInPlay(direction: .left) }
        } else if sender.direction == .right {
            let squaresInPlaySorted = squaresInPlay.sorted { $0.column > $1.column }
            for square in squaresInPlaySorted {
                if square.column == gameColumns - 1
                    || (gameGrid?[square.row][square.column + 1] != nil
                        && !squaresInPlay.contains((gameGrid?[square.row][square.column + 1])!)) {
                    shapeCanMove = false
                }
            }
            if shapeCanMove { moveShapesInPlay(direction: .right) }
        }
    }
    
    @IBAction func applyRotation(_ sender: UITapGestureRecognizer) {
        semaphore.wait()
        
        // Try to rotate squares around the center point
        // Formula for clockwise rotation: (row, col) -> (col, -row)
        guard let center = squaresInPlayCenter else {
            semaphore.signal()
            return
        }
        
        var shapeCanRotate = true
        for r in center.row - 2...center.row + 2 {
            for c in center.column - 2...center.column + 2 {
                if r < 0 || r > gameRows - 1 || c < 0 || c > gameColumns - 1 { continue }
                if let squareHere = gameGrid?[r][c], squaresInPlay.contains(squareHere) {
                    let dr = squareHere.row - center.row, dc = squareHere.column - center.column
                    let newC = center.column - dr, newR = center.row + dc
                    
                    // Trying to rotate out of bounds
                    if newR < 0 || newR > gameRows - 1 || newC < 0 || newC > gameColumns - 1 {
                        shapeCanRotate = false
                        continue
                    }
                    
                    // Trying to rotate into existing square
                    if let newSquare = gameGrid?[newR][newC], !squaresInPlay.contains(newSquare) {
                        shapeCanRotate = false
                    }
                }
            }
        }
        
        if shapeCanRotate {
            // Make new array to hold rotated parts
            var rotatedGrid: [[Square?]] = []
            for r in 0..<5 {
                rotatedGrid.append([])
                for _ in 0..<5 {
                    rotatedGrid[r].append(nil)
                }
            }
            
            for r in center.row - 2...center.row + 2 {
                for c in center.column - 2...center.column + 2 {
                    if r < 0 || r > gameRows - 1 || c < 0 || c > gameColumns - 1 { continue }
                    if let squareHere = gameGrid?[r][c] {
                        if squaresInPlay.contains(squareHere) {
                            let dr = squareHere.row - center.row, dc = squareHere.column - center.column
                            let newC = center.column - dr, newR = center.row + dc
                            rotatedGrid[newR - center.row + 2][newC - center.column + 2] = gameGrid?[r][c]
                            
                            // Update square view display
                            squareHere.row = newR
                            squareHere.column = newC
                            squareHere.frame.origin = CGPoint(x: CGFloat(squareHere.column) * squareSize,
                                                              y: CGFloat(squareHere.row) * squareSize)
                        } else {
                            rotatedGrid[r - center.row + 2][c - center.column + 2] = gameGrid?[r][c]
                        }
                    }
                }
            }
            
            // Put back rotated parts into original game grid
            for r in center.row - 2...center.row + 2 {
                for c in center.column - 2...center.column + 2 {
                    if r < 0 || r > gameRows - 1 || c < 0 || c > gameColumns - 1 { continue }
                    gameGrid?[r][c] = rotatedGrid[r - center.row + 2][c - center.column + 2]
                }
            }
        }
        
        semaphore.signal()
    }
    
    @IBAction func applyForceDown(_ sender: UISwipeGestureRecognizer) {
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
        
        // Update center point
        squaresInPlayCenter?.row += dr
        squaresInPlayCenter?.column += dc
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
