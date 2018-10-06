import SwiftObserver
import SwiftyToolz

extension Task.TaskData.Tag
{
    var string: String
    {
        switch self
        {
        case .red: return "Red"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .blue: return "Blue"
        case .purple: return "Purple"
        }
    }
}

final class Task: NewTree<Task.TaskData>, Codable, Observable, Tree
{
    // MARK: - Life Cycle
    
    convenience init(_ title: String? = nil,
                     state: TaskState? = nil,
                     tag: Task.TaskData.Tag? = nil,
                     root: Task? = nil,
                     numberOfLeafs: Int = 1)
    {
        self.init()
        
        data?.title = Var(title)
        data?.state = Var(state)
        data?.tag = Var(tag)
        self.root = root
        self.numberOfLeafs = numberOfLeafs
    }
    
    override init()
    {
        super.init()
        
        data = TaskData()
    }
    
    deinit { removeObservers() }
    
    // MARK: - Coding
    
    init(from decoder: Decoder) throws
    {
        super.init()
        
        data = TaskData()
        
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else
        {
            return
        }
        
        if let titleString = try? container.decode(String.self, forKey: .title)
        {
            data?.title <- titleString
        }
        else if let title = try? container.decode(Var<String>.self, forKey: .title)
        {
            data?.title = title
        }
        
        if let integer = try? container.decode(Int.self, forKey: .state)
        {
            data?.state <- TaskState(rawValue: integer)
        }
        else if let state = try? container.decode(Var<TaskState>.self,
                                                  forKey: .state)
        {
            data?.state = state
        }
        
        if let integer = try? container.decode(Int.self, forKey: .tag)
        {
            data?.tag <- Task.TaskData.Tag(rawValue: integer)
        }
        else if let tag = try? container.decode(Var<Task.TaskData.Tag>.self, forKey: .tag)
        {
            data?.tag = tag
        }
        
        if let branches = try? container.decode([Task].self, forKey: .branches)
        {
            self.branches = branches
        }
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let titleString = data?.title.value
        {
            try? container.encode(titleString, forKey: .title)
        }
        
        if let stateInteger = data?.state.value?.rawValue
        {
            try? container.encode(stateInteger, forKey: .state)
        }
        
        if let tagInteger = data?.tag.value?.rawValue
        {
            try? container.encode(tagInteger, forKey: .tag)
        }
        
        if !branches.isEmpty
        {
            try? container.encode(branches, forKey: .branches)
        }
    }

    enum CodingKeys: String, CodingKey
    {
        case title, state, tag, branches = "subtasks"
    }
    
    // MARK: - Data
    
    //let data: TaskData? = TaskData()
    
    class TaskData
    {
        var title = Var<String>()
        var state = Var<TaskState>()
        var tag = Var<Tag>()
        
        enum Tag: Int, Codable
        {
            case red, orange, yellow, green, blue, purple
        }
    }
    
    // MARK: - Group
    
    @discardableResult
    func groupSubtasks(at indexes: [Int]) -> Task?
    {
        guard let groupIndex = indexes.min() else
        {
            log(warning: "Tried to group tasks at no indexes.")
            return nil
        }
        
        let group = Task(state: highestPriorityState(at: indexes))
        
        guard let merged = mergeBranches(at: indexes,
                                         as: group,
                                         at: groupIndex) else { return nil }
        
        group.numberOfLeafs = group.numberOfLeafsRecursively()

        send(.did(.remove(subtasks: merged, from: indexes)))
        send(.did(.create(at: groupIndex)))
        
        let insertedIndexesInGroup = Array(0 ..< group.numberOfBranches)
        group.send(.did(.insert(at: insertedIndexesInGroup)))
        
        return group
    }
    
    private func highestPriorityState(at indexes: [Int]) -> TaskState?
    {
        var highestPriorityState: TaskState? = .trashed
        
        for index in indexes
        {
            guard let subtask = self[index] else { continue }
            
            let subtaskState = subtask.data?.state.value
            let subtaskPriority = TaskState.priority(of: subtaskState)
            let highestPriority = TaskState.priority(of: highestPriorityState)
            
            if subtaskPriority < highestPriority
            {
                highestPriorityState = subtaskState
            }
        }
        
        return highestPriorityState
    }
    
    // MARK: - Remove
    
    @discardableResult
    func removeSubtasks(at indexes: [Int]) -> [Task]?
    {
        guard let removedSubtasks = removeBranches(at: indexes) else
        {
            log(warning: "Couldn't remove branches at \(indexes).")
            return nil
        }
        
        updateNumberOfLeafs()
        
        send(.did(.remove(subtasks: removedSubtasks, from: indexes)))
        
        lastRemoved.storeCopies(of: removedSubtasks)
        
        return removedSubtasks
    }
    
    var numberOfRemovedSubtasks: Int { return lastRemoved.count }

    let lastRemoved = Clipboard<Task>()
    
    // MARK: - Insert
    
    func add(_ task: Task)
    {
        insert(task, at: numberOfBranches)
    }
    
    @discardableResult
    func insert(_ subtask: Task, at index: Int) -> Task?
    {
        guard insert(branch: subtask, at: index) else { return nil }
        
        updateNumberOfLeafs()
        
        send(.did(.insert(at: [index])))

        return subtask
    }
    
    @discardableResult
    func insert(_ subtasks: [Task], at index: Int) -> Bool
    {
        guard insert(branches: subtasks, at: index) else { return false }
        
        updateNumberOfLeafs()
        
        if !subtasks.isEmpty
        {
            let insertedIndexes = Array(index ..< index + subtasks.count)
        
            send(.did(.insert(at: insertedIndexes)))
        }
        
        return true
    }
    
    // MARK: - Create
    
    @discardableResult
    func create(at index: Int) -> Task?
    {
        let taskBelowIsInProgress: Bool =
        {
            guard branches.isValid(index: index) else { return false }
            return self[index]?.isInProgress ?? false
        }()
        
        let taskAboveIsInProgress: Bool =
        {
            guard index > 0 else { return true }
            
            return self[index - 1]?.isInProgress ?? false
        }()
        
        let shouldBeInProgress = taskBelowIsInProgress && taskAboveIsInProgress
        
        let newSubtask = Task(state: shouldBeInProgress ? .inProgress : nil)
        
        guard insert(branch: newSubtask, at: index) else { return nil }
        
        updateNumberOfLeafs()
        
        send(.did(.create(at: index)))
        
        return newSubtask
    }
    
    // MARK: - Move
    
    @discardableResult
    func moveSubtask(from: Int, to: Int) -> Bool
    {
        guard moveBranch(from: from, to: to) else { return false }
        
        send(.did(.move(from: from, to: to)))
        
        return true
    }
    
    // MARK: - Counting Leafs
    
    @discardableResult
    func recoverNumberOfLeafs() -> Int
    {
        if isLeaf
        {
            numberOfLeafs = 1
            return numberOfLeafs
        }
        
        var subtaskLeafs = 0
        
        for subtask in branches
        {
            subtaskLeafs += subtask.recoverNumberOfLeafs()
        }
        
        numberOfLeafs = subtaskLeafs
        
        return numberOfLeafs
    }
    
    private func updateNumberOfLeafs()
    {
        let newNumber = numberOfLeafsRecursively()
        
        guard newNumber != numberOfLeafs else { return }
        
        numberOfLeafs = newNumber
        root?.updateNumberOfLeafs()
        
        send(.didChange(numberOfLeafs: numberOfLeafs))
    }
    
    private func numberOfLeafsRecursively() -> Int
    {
        if isLeaf { return 1 }
        
        var subtaskLeafs = 0
        
        for subtask in branches
        {
            subtaskLeafs += subtask.numberOfLeafs
        }
        
        return subtaskLeafs
    }
    
    // TODO: this tree metric should be moved to ListItem, the Event value can then be removed
    private(set) var numberOfLeafs = 1
    
    // MARK: - Tree
    
    weak var root: Task? = nil
    {
        // TODO: this property oberver won't be needed when Lists have ListItems instead of Tasks
        didSet
        {
            guard oldValue !== root else { return }
            
            send(.did(.changeRoot(from: oldValue, to: root)))
        }
    }
    
    var branches = [Task]()
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }

    enum Event { case didNothing, did(Edit), didChange(numberOfLeafs: Int) }
}
