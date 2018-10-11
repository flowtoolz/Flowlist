import SwiftObserver
import SwiftyToolz

// MARK: - Tags

extension SelectableList
{
    func set(tag: ItemData.Tag?)
    {
        let selected = selectedIndexes
        
        guard !selected.isEmpty else { return }
        
        if selected.count == 1
        {
            if let data = self[selected[0]]?.data
            {
                data.tag <- data.tag.value != tag ? tag : nil
            }
        }
        else
        {
            for selectedindex in selected
            {
                self[selectedindex]?.data?.tag <- tag
            }
        }
    }
}

// MARK: -

class SelectableList: List
{
    // MARK: - Create
    
    func createTask()
    {
        if selectedIndexes.count < 2
        {
            createBelowSelection()
        }
        else
        {
            groupSelectedTasks()
        }
    }
    
    func groupSelectedTasks()
    {
        let indexes = selectedIndexes
        
        guard indexes.count > 1 else
        {
            log(warning: "Tried to group less than 2 selected tasks.")
            return
        }
        
        let groupState = root?.highestPriorityState(at: indexes)
        
        if let groupIndex = indexes.first,
            let group = root?.groupNodes(at: indexes)
        {
            setSelectionWithTasksListed(at: [groupIndex])
            
            let data = ItemData()
            data.state <- groupState
            group.data = data
            group.data?.send(.wantTextInput)
        }
    }
    
    func createBelowSelection()
    {
        create(at: newIndexBelowSelection)
    }
    
    func create(at index: Int)
    {
        guard let _ = root?.createSubitem(at: index) else { return }
        
        setSelectionWithTasksListed(at: [index])
    }
    
    // MARK: - Paste
    
    func paste(_ tasks: [Item])
    {
        let index = newIndexBelowSelection
        
        guard root?.insert(tasks, at: index) ?? false else { return }
        
        let pastedIndexes = Array(index ..< index + tasks.count)
        
        setSelectionWithTasksListed(at: pastedIndexes)
    }
    
    // MARK: - Remove
    
    @discardableResult
    func removeSelectedTasks() -> Bool
    {
        let indexes = selectedIndexes
        
        guard let root = root,
            let firstSelectedIndex = indexes.first,
            let removedTasks = root.removeNodes(from: indexes),
            removedTasks.count > 0
        else
        {
            return false
        }
        
        selectAfterRemoval(from: firstSelectedIndex)
        
        return true
    }
    
    func selectAfterRemoval(from index: Int)
    {
        guard !(root?.isLeaf ?? true) else { return }
        
        setSelectionWithTasksListed(at: [max(index - 1, 0)])
    }
    
    func undoLastRemoval()
    {
        guard let tasks = root?.lastRemoved.copiesOfStoredObjects else
        {
            return
        }
        
        paste(tasks)
        
        root?.lastRemoved.removeAll()
    }
    
    var newIndexBelowSelection: Int
    {
        return (selectedIndexes.last ?? -1) + 1
    }
    
    // MARK: - Toggle States
    
    func toggleInProgressStateOfFirstSelectedTask()
    {
        let indexes = selectedIndexes
        
        guard let firstSelectedIndex = indexes.first,
            let task = self[firstSelectedIndex]
        else { return }
        
        if indexes.count > 1
        {
            deselectItems(at: [firstSelectedIndex])
        }
        
        task.data?.state <- !task.isInProgress ? .inProgress : nil
    }
    
    func toggleDoneStateOfFirstSelectedTask()
    {
        let indexes = selectedIndexes
        
        guard let firstSelectedIndex = indexes.first,
            let task = self[firstSelectedIndex]
        else
        {
            return
        }
        
        let newSelectedIndex = nextSelectedIndexAfterCheckingOff(at: firstSelectedIndex)
        
        let newState: ItemData.State? = !task.isDone ? .done : nil
        
        if indexes.count == 1,
            newState == .done,
            let newSelectedIndex = newSelectedIndex
        {
            setSelectionWithTasksListed(at: [newSelectedIndex])
        }
        else if indexes.count > 1
        {
            deselectItems(at: [firstSelectedIndex])
        }
        
        task.data?.state <- newState
    }
    
    private func nextSelectedIndexAfterCheckingOff(at index: Int) -> Int?
    {
        for i in index + 1 ..< count
        {
            guard let task = self[i] else { continue }
            
            if task.isOpen { return i }
        }
        
        for i in (0 ..< index).reversed()
        {
            guard let task = self[i] else { continue }
            
            if task.isOpen { return i }
        }
        
        return nil
    }
    
    // MARK: - Move
    
    func canMoveItems(up: Bool) -> Bool
    {
        let indexes = selectedIndexes
        
        guard indexes.count == 1, let selected = indexes.first else
        {
            return false
        }
        
        if up && selected == 0 { return false }
        
        if !up && selected == count - 1 { return false }
        
        return true
    }
    
    @discardableResult
    func moveSelectedTask(_ positions: Int) -> Bool
    {
        let indexes = selectedIndexes
        
        guard positions != 0, let root = root, indexes.count == 1 else
        {
            return false
        }
        
        let selectedIndex = indexes[0]
        
        return root.moveNode(from: selectedIndex,
                                to: selectedIndex + positions)
    }
    
    // MARK: - Edit Title
    
    func editTitle()
    {
        guard let index = selectedIndexes.first else { return }
        
        editTitle(at: index)
    }
    
    
    
    
}


