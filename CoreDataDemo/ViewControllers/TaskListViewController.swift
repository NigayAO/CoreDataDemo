//
//  TaskListViewController.swift
//  CoreDataDemo
//
//  Created by Alexey Efimov on 06.12.2021.
//

import UIKit

class TaskListViewController: UITableViewController {
    
    private let context = StorageManager.shared
    
    private var taskList: [Task] = []
    private let cellID = "task"

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        view.backgroundColor = .white
        setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchData()
        tableView.reloadData()
    }

    private func setupNavigationBar() {
        title = "Task List"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navBarAppearance.backgroundColor = UIColor(
            red: 21/255,
            green: 101/255,
            blue: 192/255,
            alpha: 194/255
        )
        
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewTask)
        )
        
        navigationController?.navigationBar.tintColor = .white
    }
    
    @objc private func addNewTask() {
        showSaveAlert(with: "New task", and: "What do you want to do?")
    }
    
    private func fetchData() {
        let fetchRequest = Task.fetchRequest()
        
        do {
            taskList = try context.persistentContainer.viewContext.fetch(fetchRequest)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func showSaveAlert(with title: String, and message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let task = alert.textFields?.first?.text, !task.isEmpty else { return }
            self.save(task)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        alert.addTextField { textField in
            textField.placeholder = "New Task"
        }
        present(alert, animated: true)
    }
    
    private func showEditAlert(with title: String, and message: String, indexPath: IndexPath) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let task = alert.textFields?.first?.text, !task.isEmpty else { return }
            self.edit(task, indexPath)
            self.tableView.reloadData()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        alert.addTextField { textField in
            let task = self.taskList[indexPath.row]
            textField.text = task.title
        }
        present(alert, animated: true)
    }
    
    private func save(_ taskName: String) {
        let task = Task(context: context.persistentContainer.viewContext)
        task.title = taskName
        taskList.append(task)
        
        let cellIndex = IndexPath(row: taskList.count - 1, section: 0)
        tableView.insertRows(at: [cellIndex], with: .automatic)
        
        if context.persistentContainer.viewContext.hasChanges {
            do {
                try context.persistentContainer.viewContext.save()
            } catch let error {
                print(error)
            }
        }
    }
    
    private func edit(_ taskName: String, _ indexPath: IndexPath) {
        let task = taskList[indexPath.row]
        task.title = taskName
        if context.persistentContainer.viewContext.hasChanges {
            do {
                try context.persistentContainer.viewContext.save()
            } catch let error {
                print(error)
            }
        }
    }
}

extension TaskListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        taskList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let task = taskList[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = task.title
        cell.contentConfiguration = content
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showEditAlert(with: "Change task", and: "Plans changed", indexPath: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let task = taskList[indexPath.row]
        taskList.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        context.persistentContainer.viewContext.delete(task)
        context.saveContext()
    }
}
