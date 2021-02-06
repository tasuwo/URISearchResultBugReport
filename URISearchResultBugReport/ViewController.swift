//
//  ViewController.swift
//  URISearchResultBugReport
//
//  Created by Tasuku Tozawa on 2021/02/06.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    enum Section {
        case main
    }

    private var container: NSPersistentContainer {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer
    }
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, NSManagedObjectID>!
    private var controller: NSFetchedResultsController<Item>!

    override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()
        configureController()
        configureNavigationBar()
    }

    private func configureCollectionView() {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment -> NSCollectionLayoutSection? in
            var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
            configuration.backgroundColor = UIColor.systemBackground
            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        }

        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.systemBackground
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.addSubview(collectionView)

        let registration: UICollectionView.CellRegistration<UICollectionViewListCell, NSManagedObjectID> = .init { [unowned self] cell, indexPath, id in
            let Item = self.container.viewContext.object(with: id) as! Item
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.text = Item.title
            contentConfiguration.secondaryText = Item.url?.absoluteString
            cell.contentConfiguration = contentConfiguration
        }
        dataSource = .init(collectionView: collectionView) { collectionView, indexPath, Item in
            return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: Item)
        }
        collectionView.dataSource = dataSource
    }

    private func configureController() {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.title, ascending: true)]
        controller = NSFetchedResultsController(fetchRequest: request,
                                                managedObjectContext: container.viewContext,
                                                sectionNameKeyPath: nil,
                                                cacheName: nil)
        controller.delegate = self
        try! controller.performFetch()
    }

    private func configureNavigationBar() {
        let addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd(_:)))
        navigationItem.leftBarButtonItem = addItem
    }

    @objc
    func didTapAdd(_ sender: UIBarButtonItem) {
        let generateTitle = { () -> String in
            let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            var title: String = ""
            for _ in 0 ..< 10 {
                let offset = Int(arc4random_uniform(UInt32(base.count)))
                title += String(base[base.index(base.startIndex, offsetBy: offset)])
            }
            return title
        }

        let generateUrl = { () -> URL in
            let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            var path: String = ""
            for _ in 0 ..< 5 {
                let offset = Int(arc4random_uniform(UInt32(base.count)))
                path += String(base[base.index(base.startIndex, offsetBy: offset)])
            }
            return URL(string: "https://localhost/\(path)")!
        }

        let item = Item(context: container.viewContext)
        item.id = UUID()
        item.title = generateTitle()
        item.url = generateUrl()
        try! container.viewContext.save()
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {
    // MARK: - NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        dataSource.apply(snapshot as NSDiffableDataSourceSnapshot<Section, NSManagedObjectID>)
    }
}
