//
//  ViewController.swift
//  MVCBasic
//
//  Created by Jamie Chu on 5/1/21.
//

import UIKit

class ViewController: UIViewController {

    private var root: NewsRoot? {
        didSet {
            self.statusLabel.text = root?.status
            print("-=- did set triggered.. reloadData() \(root?.articles.count)")
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self)

//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)


        tableView.delegate = self
        tableView.dataSource = self

        print("-=- requestNews")
        viewModel.requestNews { [weak self] result in
            switch result {
            case .failure:
                self?.statusLabel.text = "Failed to retrieve news"
            case .success(let root):
                self?.root = root
            }
        }


        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(statusLabel)
        view.addSubview(tableView)


        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .yellow


        statusLabel.text = "vjsnenjksnjknk"

        tableView.backgroundColor = .orange

        NSLayoutConstraint.activate([
            statusLabel.safeAreaLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            tableView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        ])

    }

    let statusLabel = UILabel()
    let tableView = UITableView()



    init(viewModel: ViewControllerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    private let viewModel: ViewControllerViewModel



    required init?(coder aDecoder: NSCoder) {
        fatalError("Storyboard are a pain")
    }

}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        (root?.articles ?? []).count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell: UITableViewCell! = tableView.dequeue()


//        cell.textLabel?.text = "cdsjnfksdjnjk"
        if let articles = root?.articles {
            cell.textLabel?.text = "SourceId: \(articles[indexPath.row].source.id ?? "null") SourceName: \(articles[indexPath.row].source.name)"

        }
        print("-=- \(indexPath)")

        return cell
    }


}

extension UITableViewCell {
    static var className: String {
        "\(Self.self)"
    }
}

extension UITableView {
    func register<T: UITableViewCell>(_ type: T.Type) {
        register(type, forCellReuseIdentifier: type.className)
    }

    func dequeue<T: UITableViewCell>() -> T? {
        dequeueReusableCell(withIdentifier: T.className) as? T
    }
}
