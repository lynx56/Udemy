//
//  SudokuViewController.swift
//  Sudoku
//
//  Created by lynx on 20/05/2018.
//  Copyright © 2018 Gulnaz. All rights reserved.
//

import UIKit

class SudokuViewController: UIViewController {
  
    var cells: [DrawableImageView] = []
    var previewCells: [UILabel] = []
    var grid: UIView!
    var results: [Int: Int?] = [:]
    var puzzle: Puzzle!
    var master: ImageRecognitionMaster3!
    var generator = SudokuGenerator()
    var buttonView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        master = ImageRecognitionMaster3()
        
        puzzle = generator.generate(PuzzleDifficultyEasy)!
        
        createGrid(puzzle.grid)
        
        buttonView = UIView(frame: CGRect(x: 0, y: grid.frame.maxY + 20, width: self.view.bounds.width/3, height: self.view.bounds.width/3))
        
        self.addButtonsPanel(to: buttonView)
        
        self.view.addSubview(buttonView)
    }
    
    func createGrid(_ solution: Solution){
        var size = min(self.view.bounds.width, self.view.bounds.height)
        
        let origin = CGPoint(x: self.view.safeAreaInsets.left, y: self.view.safeAreaInsets.top + UIApplication.shared.statusBarFrame.height + CGFloat(self.navigationController?.navigationBar.frame.height ?? 0.0))
        grid = UIView(frame: CGRect(origin: origin, size: CGSize(width: size, height: size)))
        let sizeOfSquares = (grid.bounds.width - 2.0) / 9.0
        
        for bigViewRow in 0..<3{
            for bigRowColumn in 0..<3{
                let bigViewFrame = CGRect(x: CGFloat(bigRowColumn) * sizeOfSquares * 3, y: CGFloat(bigViewRow) * sizeOfSquares * 3, width: sizeOfSquares*3 + 2.0, height: sizeOfSquares*3 + 2.0)
                
                let bigView = UIView(frame: bigViewFrame)
                for i in 0..<3{
                    for j in 0..<3{
                        var label = UIView()
                        
                        let globalPosition = i * 9 + j + bigRowColumn * 3 + bigViewRow * 27
                        
                        let pos = solution.getAtX(UInt(j + bigRowColumn * 3), y: UInt(i + bigViewRow * 3))!
                        
                        let frame = CGRect(x: CGFloat(j) * sizeOfSquares, y: CGFloat(i) * sizeOfSquares, width: sizeOfSquares + 2.0, height: sizeOfSquares + 2.0)
                        
                        label.tag = globalPosition
                        
                        let subviewFrame = CGRect(origin: .zero, size: frame.size)
                        let subview = (pos.value.intValue != 0 && !pos.temporary) ? createTextViewOn(frame: subviewFrame, andText: pos.value.stringValue) : createDrawingView(on: subviewFrame, andTag: label.tag)
                    
                        label.addSubview(subview)
                        label.frame = frame
                        label.layer.borderColor = UIColor.lightGray.cgColor
                        label.layer.borderWidth = 2
                        
                        bigView.addSubview(label)
                    }
                }
                bigView.layer.borderColor = UIColor.darkGray.cgColor
                bigView.layer.borderWidth = 2
                grid.addSubview(bigView)
            }
        }
        
        self.view.addSubview(grid)
    }
    
    func createTextViewOn(frame: CGRect, andText text: String)->UILabel{
        let textLabel = UILabel(frame: frame)
        textLabel.text = text
        textLabel.textAlignment = NSTextAlignment.center
        textLabel.font = UIFont.systemFont(ofSize: 27)

        return textLabel
    }
    
    func createDrawingView(on frame: CGRect, andTag tag: Int)->DrawableImageView{
        let drawView = DrawableImageView(frame: frame)
        drawView.isUserInteractionEnabled = true
        drawView.valueChanged = { (newValue) in
            self.puzzle.grid.position(at: UInt(tag)).value = NSNumber(value: newValue ?? 0)
        }
        
        drawView.endDrawing = { (view) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                view.alpha = 0.5
                self.process(image: view.image!) { (result, error) in
                    view.value = result
                    let label = UILabel(frame: view.frame)
                    label.text = "\(result!)"
                    label.font = UIFont.boldSystemFont(ofSize: 40)
                    label.textAlignment = NSTextAlignment.center
                
                    UIView.animate(withDuration: 2, animations: {
                        view.alpha = 0
                    })
        
                    view.superview!.addSubview(label)
                }
            }
        }
        
        return drawView
    }
    
    func addButtonsPanel(to buttonView: UIView){
        let sizeOfSquares = (buttonView.bounds.width - 2.0) / 5.0
       
        for i in 0..<2{
            for j in 0..<5{
                let frame = CGRect(x: CGFloat(j) * sizeOfSquares, y: CGFloat(i) * sizeOfSquares, width: sizeOfSquares + 2.0, height: sizeOfSquares + 2.0)
               
                let tag = i * 5 + j + 1
                
                let draggableView: DraggableView = numeroView(with: frame, and: tag)
                draggableView.releaseOnLocation = numeroRelease
                let backView: UIView = numeroView(with: frame, and: tag)
                draggableView.layer.borderColor = UIColor.clear.cgColor
                
                buttonView.addSubview(backView)
                buttonView.addSubview(draggableView)
            }
        }
    }
    
    func numeroRelease(view2: DraggableView, on location: CGPoint){
        let p = buttonView.convert(view2.frame.origin, to: self.view)
     
        print(p)
        
        //let point = self.view.convert(buttonView.convert(view2.center, to: self.buttonView), to: self.view)
        //print(location)
    }
    
    func numeroView<T: UIView>(with frame: CGRect, and tag: Int)->T{
        let view = T(frame: frame)
        view.tag = tag
        let textLabel = UILabel(frame: CGRect(origin: .zero, size: frame.size))
        textLabel.text = tag == 10 ? "X": tag.description
        textLabel.textAlignment = NSTextAlignment.center
        textLabel.font = UIFont.systemFont(ofSize: 27)
        textLabel.tag = tag
        view.tag = tag
        view.addSubview(textLabel)
        
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.layer.borderWidth = 2
        
        view.isUserInteractionEnabled = true
        
        return view
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func check(_ sender: Any) {
        if let drawableCells = (grid.findSubviewsOfType(DrawableImageView.self) as? [DrawableImageView])?.filter({$0.image != nil && $0.value == nil}){
            let group = DispatchGroup()
            for cell in drawableCells{
                group.enter()
                process(image: cell.image!) { (result, error) in
                    cell.value = result
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                self.validate()
            }
        }
    }
    
    @IBAction func newPuzzle(_ sender: UIBarButtonItem) {
        let optionsController = PuzzleDifficultOptionsTableViewController(style: .plain)
        optionsController.options = [ (value: PuzzleDifficultyEasy, title: "Easy"),
                                      (value: PuzzleDifficultyMedium, title: "Medium"),
                                      (value: PuzzleDifficultyHard, title: "Hard") ]
        
        optionsController.optionSelected = { (option) in
            self.puzzle = self.generator.generate(option.value)
            self.grid.removeFromSuperview()
            self.createGrid(self.puzzle.grid)
            self.title = option.title
        }
        
        optionsController.modalPresentationStyle = .popover
        
        optionsController.popoverPresentationController?.barButtonItem = sender
        optionsController.preferredContentSize = CGSize(width: 200, height: 120)
      //  optionsController.titleForSection = "Сhoose complexity"
       
        self.present(optionsController, animated: true, completion: nil)
    }
    
    func validate(){
        for userEditedView in (self.grid.findSubviewsOfType(DrawableImageView.self) as? [DrawableImageView])!{
                let tag = UInt(userEditedView.tag)
                
                let isValid = puzzle.grid.position(at: tag).value.intValue == puzzle.solution.position(at: tag).value.intValue || userEditedView.value == nil
                
                let color = isValid ? UIColor.white : UIColor.red
                userEditedView.backgroundColor = color
        }
    }
    
    
    func process(image: UIImage, completion: @escaping (Int?, ImageRecognitionError?)->Void){
        master.recognize(image: image, completion:completion)
    }
}
