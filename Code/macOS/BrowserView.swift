import AppKit
import UIToolz
import UIObserver
import SwiftObserver
import SwiftyToolz

class BrowserView: LayerBackedView, Observer
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        constrainListLayoutGuides()
        
        for index in 0 ..< browser.numberOfLists
        {
            guard let list = browser[index] else { continue }

            pushListView(for: list)
        }
        
        observeBrowser()
        
        observe(Font.baseSize)
        {
            [weak self] _ in self?.fontSizeDidChange()
        }
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopAllObserving() }
    
    // MARK: - Adapt to Font Size Changes
    
    private func fontSizeDidChange()
    {
        TextView.fontSizeDidChange()
        
        updateSpacings()
        
        moveToFocusedListAfterNextLayout = true
        
        for listView in listViews
        {
            listView.fontSizeDidChange()
        }
    }
    
    override func layout()
    {
        super.layout()
        
        if moveToFocusedListAfterNextLayout
        {
            moveToFocusedList(animated: false)
            moveToFocusedListAfterNextLayout = false
        }
    }
    
    private var moveToFocusedListAfterNextLayout = false
    
    // MARK: - Browser
    
    private func observeBrowser()
    {
        observe(browser)
        {
            [unowned self] event in self.did(receive: event)
        }
    }
    
    private func did(receive event: Browser.Event)
    {
        switch event
        {
        case .didNothing: break
            
        case .didPush(let newList):
            pushListView(for: newList)
            
        case .didMove:
            browserDidMove()
            
        case .listDidChangeSelection(let listIndex, let selectionIndexes):
            selectionDidChangeInList(at: listIndex,
                                     selectionIndexes: selectionIndexes)
        }
    }
    
    private func browserDidMove()
    {
        moveToFocusedList()
    }
    
    private let browser = Browser()
    
    // MARK: - Resizing
    
    func didResize()
    {
        moveToFocusedList(animated: false)
    }
    
    func didEndResizing()
    {
        for listView in listViews
        {
            listView.didEndResizing()
        }
    }
    
    // MARK: - List Views
    
    private func selectionDidChangeInList(at index: Int,
                                          selectionIndexes: [Int])
    {
        guard listViews.isValid(index: index) else
        {
            log(error: "Selection changed in list view at invalid index \(index).")
            return
        }
        
        let table = listViews[index].scrollTable.table
        
        table.listDidChangeSelection(at: selectionIndexes)
    }
    
    private func pushListView(for list: SelectableList)
    {
        let newListView = addForAutoLayout(SelectableListView())
        
        newListView.configure(with: list)
        
        listViews.append(newListView)
        
        constrainLastListView()
        
        observe(listView: newListView)
    }
    
    private func observe(listView: SelectableListView)
    {
        observe(listView, select: .didReceiveUserInput)
        {
            [weak listView, weak self] in
            
            guard let listView = listView else { return }
            
            self?.listViewReceivedUserInput(listView)
        }
    }
    
    private func listViewReceivedUserInput(_ listView: SelectableListView)
    {
        guard let listIndex = listViews.index(where: { $0 === listView }) else
        {
            log(error: "Couldn't get index of list view that received user input")
            return
        }
        
        browser.move(to: listIndex)
    }
    
    private func constrainLastListView()
    {
        guard let listView = listViews.last else { return }
        
        let gap = TaskView.spacing
        
        if listViews.count == 1
        {
            listView.constrainCenterX(to: self)
        }
        else
        {
            let leftView = listViews[listViews.count - 2]
            rememberSpacing(listView.constrain(toTheRightOf: leftView, offset: gap))
        }
        
        listView.constrainWidth(to: listLayoutGuides[0])
        
        rememberSpacing(listView.constrainTop(to: self, offset: gap))
        rememberSpacing(listView.constrainBottom(to: self, offset: -gap))
    }
    
    private func moveToFocusedList(animated: Bool = true)
    {
        guard listViews.isValid(index: browser.focusedListIndex) else { return }
        
        let focusedListView = listViews[browser.focusedListIndex]
        let listOffset = focusedListView.frame.size.width + 2 * TaskView.spacing
        let targetPosition = focusedListView.frame.origin.x - listOffset
        
        if animated
        {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 0.3
            
            animator().bounds.origin.x = targetPosition
            
            NSAnimationContext.endGrouping()
        }
        else
        {
            bounds.origin.x = targetPosition
        }
    }
    
    private var listViews = [SelectableListView]()
    
    // MARK: - Layout Guides For List Width
    
    private func constrainListLayoutGuides()
    {
        for guide in listLayoutGuides
        {
            rememberSpacing(guide.constrainTop(to: self, offset: TaskView.spacing))
            rememberSpacing(guide.constrainBottom(to: self, offset: -TaskView.spacing))
        }
        
        listLayoutGuides[0].constrainWidth(toMinimum: 150)
        
        constraintsWithSpacingConstant.append(contentsOf:
        [
            listLayoutGuides[0].constrainLeft(to: self, offset: TaskView.spacing),
            listLayoutGuides[1].constrain(toTheRightOf: listLayoutGuides[0],
                                          offset: TaskView.spacing),
            listLayoutGuides[2].constrain(toTheRightOf: listLayoutGuides[1],
                                          offset: TaskView.spacing),
            listLayoutGuides[2].constrainRight(to: self, offset: -TaskView.spacing)
        ])
        
        listLayoutGuides[1].constrainWidth(to: listLayoutGuides[0])
        listLayoutGuides[2].constrainWidth(to: listLayoutGuides[0])
    }
    
    private lazy var listLayoutGuides: [NSLayoutGuide] = addLayoutGuides(3)
    
    // MARK: - Dynamic Spacings
    
    private func updateSpacings()
    {
        let spacing = TaskView.spacing
        
        for constraint in constraintsWithSpacingConstant
        {
            constraint.constant = constraint.constant < 0 ? -spacing : spacing
        }
    }
    
    private func rememberSpacing(_ constraint: NSLayoutConstraint)
    {
        constraintsWithSpacingConstant.append(constraint)
    }
    
    private var constraintsWithSpacingConstant = [NSLayoutConstraint]()
}
