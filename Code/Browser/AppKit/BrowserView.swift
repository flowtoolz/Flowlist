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
        listViews.forEach { $0.fontSizeDidChange() }
    }
    
    // MARK: - Browser
    
    open override func performKeyEquivalent(with event: NSEvent) -> Bool
    {
        guard event.type == .keyDown else
        {
            return super.performKeyEquivalent(with: event)
        }
        
        switch event.key
        {
        case .esc:
            if !browser.canMove(.left)
            {
                return super.performKeyEquivalent(with: event)
            }
            browser.move(.left)
        case .tab: browser.move(.right)
        case .space:
            if !reachedItemNumberLimit
            {
                browser.focusedList.create(at: 0)
            }
        default: return super.performKeyEquivalent(with: event)
        }
        
        return true
    }
    
    private func observeBrowser()
    {
        observe(browser)
        {
            [unowned self] event in self.did(receive: event)
        }
        
        observe(browser.focusedIndexVariable)
        {
            [unowned self] indexUpdate in
            
            self.moveToFocusedList(from: indexUpdate.old,
                                   to: indexUpdate.new,
                                   animated: true)
        }
    }
    
    private func did(receive event: Browser.Event)
    {
        if case .didPush(let newList) = event
        {
            pushListView(for: newList)
        }
    }
    
    // MARK: - Resizing
    
    func didResize()
    {
        moveToFocusedList(animated: false)
    }
    
    func didEndResizing()
    {
        listViews.forEach { $0.didEndResizing() }
    }
    
    // MARK: - List Views
    
    private func pushListView(for list: List)
    {
        let newListView = addForAutoLayout(ListView())
        
        newListView.configure(with: list)
        
        listViews.append(newListView)
        
        constrainLastListView()
        
        observe(listView: newListView)
    }
    
    private func observe(listView: ListView)
    {
        observe(listView, select: .didReceiveUserInput)
        {
            [weak listView, weak self] in
            
            guard let listView = listView else { return }
            
            self?.listViewReceivedUserInput(listView)
        }
    }
    
    private func listViewReceivedUserInput(_ listView: ListView)
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
        
        let gap = Float.listGap.cgFloat
        
        let index = listViews.count - 1
        
        if index == 0
        {
            listView.constrainCenterXToParent()
        }
        else
        {
            let leftView = listViews[index - 1]
            listView.constrain(toTheRightOf: leftView, gap: gap)
        }
        
        listView.constrainWidth(to: listLayoutGuides[index % 3])
        
        listView.constrainTopToParent(inset: gap)
        listView.constrainBottomToParent()
    }
    
    private func moveToFocusedList(from: Int? = nil,
                                   to: Int? = nil,
                                   animated: Bool = true)
    {
        let newIndex = to ?? browser.focusedIndex
        
        guard listViews.isValid(index: newIndex) else { return }
        
        var targetPosition: CGFloat = 0
        
        if newIndex > 0
        {
            let leftListPosition = listViews[newIndex - 1].frame.origin.x
            
            targetPosition = leftListPosition - Float.listGap.cgFloat
        }
        
        guard animated else
        {
            bounds.origin.x = targetPosition
            return
        }
        
        if listViews.isValid(index: newIndex - 1)
        {
            listViews[newIndex - 1].set(visibleForAnimation: true)
        }
        
        if listViews.isValid(index: newIndex + 1)
        {
            listViews[newIndex + 1].set(visibleForAnimation: true)
        }
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0.3
        NSAnimationContext.current.completionHandler =
        {
            self.animatioDidEnd()
        }
        
        animator().bounds.origin.x = targetPosition
        
        NSAnimationContext.endGrouping()
        
        ongoingAnimations += 1
    }
    
    private func animatioDidEnd()
    {
        ongoingAnimations -= 1
        
        guard ongoingAnimations == 0 else { return }
        
        listViews.forEachIndex
        {
            let visible = abs(browser.focusedIndex - $1) < 2
            
            $0.set(visibleForAnimation: visible)
        }
    }
    
    private var ongoingAnimations = 0
    
    private var listViews = [ListView]()
    
    // MARK: - Layout Guides For List Width
    
    private func constrainListLayoutGuides()
    {
        let gap = Float.listGap.cgFloat
        
        listLayoutGuides.forEach
        {
            $0.constrainTop(to: self, offset: gap)
            $0.constrainBottom(to: self)
        }
        
        listLayoutGuides[0].constrainWidth(toMinimum: 150)
        listLayoutGuides[0].constrainLeft(to: self, offset: gap)
        
        listLayoutGuides[1].constrain(toTheRightOf: listLayoutGuides[0],
                                      gap: gap)
        listLayoutGuides[1].constrainWidth(to: listLayoutGuides[0])
        
        listLayoutGuides[2].constrain(toTheRightOf: listLayoutGuides[1],
                                      gap: gap)
        listLayoutGuides[2].constrainRight(to: self, offset: -gap)
        listLayoutGuides[2].constrainWidth(to: listLayoutGuides[0])
    }
    
    private lazy var listLayoutGuides = addLayoutGuides(3)
}
