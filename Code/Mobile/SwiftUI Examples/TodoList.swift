//
//  ContentView.swift
//  TestingMoreSwiftUI
//
//  Created by Chris Eidhof on 04.06.19.
//  Copyright © 2019 Chris Eidhof. All rights reserved.
//

import SwiftUI
import Combine

var newListCounter = 1

extension Array {
    mutating func remove(atOffsets indices: IndexSet) {
        for i in indices.reversed() {
            remove(at: i)
        }
    }
    
    subscript(safe index: Int) -> Element? {
        get {
            guard (startIndex..<endIndex).contains(index) else { return nil }
            return self[index]
        }
        set {
            guard (startIndex..<endIndex).contains(index) else { return }
            if let v = newValue {
                self[index] = v
            }
        }
    }
}

/// Similar to a `Binding`, but this is also observable/dynamic.
@propertyDelegate
@dynamicMemberLookup
final class Derived<A>: BindableObject {
    let didChange = PassthroughSubject<A, Never>()
    fileprivate var cancellables: [AnyCancellable] = []
    private let get: () -> (A)
    private let mutate: ((inout A) -> ()) -> ()
    init(get: @escaping () -> A, mutate: @escaping ((inout A) -> ()) -> ()) {
        self.get = get
        self.mutate = mutate
    }
    var value: A {
        get { get() }
        set { mutate { $0 = newValue } }
    }
    subscript<U>(dynamicMember keyPath: WritableKeyPath<A, U>) -> Derived<U> {
        let result = Derived<U>(get: {
            let value = self.get()[keyPath: keyPath]
            return value
        }, mutate: { f in
            self.mutate { (a: inout A) in
                f(&a[keyPath: keyPath])
            }
        })
        var c: AnyCancellable! = nil
        c = AnyCancellable(didChange.sink { [weak result] in
            // todo cancel the subscription as well
            result?.didChange.send($0[keyPath: keyPath])
            
        })
        cancellables.append(c)
        return result
    }
    
    var binding: Binding<A> {
        return Binding<A>(getValue: { self.value }, setValue: { self.value = $0 })
    }
    
    deinit {
        for c in cancellables {
            c.cancel()
        }
    }
}

final class SimpleStore<A>: BindableObject {
    let didChange = 
        PassthroughSubject<A, Never>()
    init(_ value: A) { self.value = value }
    var value: A {
        didSet {
            didChange.send(value)
        }
    }
    
    var bindable: Derived<A> {
        let result = Derived<A>(get: {
            self.value
        }, mutate: { f in
            f(&self.value)
        })
        let c = self.didChange.sink { [weak result] value in
            result?.didChange.send(value)
        }
        result.cancellables.append(AnyCancellable(c))
        return result
    }
}



struct TodoList: Codable, Equatable, Hashable {
    var items: [Todo] = []
    var name = "Todos"
}
struct Todo: Codable, Equatable, Hashable {
    var text: String
    var done: Bool = false
}

struct MyState: Codable, Equatable, Hashable {
    var lists: [TodoList] = [
        TodoList(items: [
            Todo(text: "Buy Milk"),
            Todo(text: "Clean")
        ])
    ]
}

struct ItemRow: View {
    @Binding var item: Todo?
    var body: some View {
        return Button(action: { self.item!.done.toggle() }) {
            HStack {
                Text(item!.text)
                Spacer()
                if item!.done {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

struct ListRow: View {
    @ObjectBinding var item: Derived<TodoList>
    var body: some View {
        NavigationButton(destination: TodoListView(list: item)) {
            HStack {
                Text(item.value.name)
                Spacer()
            }
        }
    }
}

struct TodoListView: View {
    @ObjectBinding var list: Derived<TodoList>
    var body: some View {
        List {
            ForEach((0..<list.value.items.count)) { index in
                ItemRow(item: self.list.items[safe: index].binding)
            }.onDelete { indices in
                // this crashes...
                self.list.value.items.remove(atOffsets: indices)
            }
        }
        .navigationBarTitle(Text("\(list.value.name) - \(list.value.items.count) items"))
            .navigationBarItems(leading:
                EditButton(),
                trailing: Button(action: { self.list.value.items.append(Todo(text: "New Todo")) }) { Image(systemName: "plus.circle")}
        )
    }
}

struct AllListsView: View {
    @ObjectBinding var theState: Derived<MyState>
    var body: some View {
        List {
            ForEach(0..<theState.value.lists.count) { (index: Int) in
                ListRow(item: self.theState.lists[index])
            }
        }
        .navigationBarTitle(Text("All Lists"))
        .navigationBarItems(trailing:
            Button(action: {
                newListCounter += 1
                self.theState.value.lists.append(TodoList(items: [], name: "New List \(newListCounter)"))
            }) { Image(systemName: "plus.circle")}
        )
    }
}

struct ContentView : View {
    @ObjectBinding var store: Derived<MyState>
    var body: some View {
        NavigationView {
            AllListsView(theState: store)
        }
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView(store: SimpleStore(MyState()).bindable)
    }
}
#endif
