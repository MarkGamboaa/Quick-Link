//
//  ViewController.swift
//  QuickLink
//
//  Created by Juan Miguel G. Antonio on 11/20/25.
//

import UIKit

// MARK: - Model
struct LinkItem: Codable {
    var title: String
    var url: String
    var colorHex: String
}

// MARK: - UIColor Extension for Hex
extension UIColor {
    var toHex: String {
        var r:CGFloat=0, g:CGFloat=0, b:CGFloat=0, a:CGFloat=0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format:"#%02lX%02lX%02lX",
                      lroundf(Float(r*255)),
                      lroundf(Float(g*255)),
                      lroundf(Float(b*255)))
    }

    convenience init(hex: String) {
        var hexString = hex
        if hex.hasPrefix("#") { hexString = String(hex.dropFirst()) }
        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF)/255,
            green: CGFloat((rgb >> 8) & 0xFF)/255,
            blue: CGFloat(rgb & 0xFF)/255,
            alpha: 1.0
        )
    }
}

// MARK: - ViewController
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var links: [LinkItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "QuickLink"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        loadLinks()
    }
    
    // MARK: - Add Link
    @IBAction func addButtonPressed(_ sender: Any) {
        showAddEditLink(nil, index: nil)
    }
    
    // MARK: - Add/Edit Link Helper
    func showAddEditLink(_ link: LinkItem?, index: Int?) {
        let alert = UIAlertController(title: link == nil ? "Add Link" : "Edit Link",
                                      message: "Enter title and URL",
                                      preferredStyle: .alert)
        alert.addTextField { $0.text = link?.title; $0.placeholder = "Title" }
        alert.addTextField { $0.text = link?.url; $0.placeholder = "URL (https://...)" }
        
        alert.addAction(UIAlertAction(title: "Pick Color", style: .default, handler: { _ in
            self.showColorPicker { color in
                let titleText = alert.textFields?[0].text ?? "Untitled"
                let urlText = alert.textFields?[1].text ?? ""
                
                let newLink = LinkItem(title: titleText, url: urlText, colorHex: color.toHex)
                
                if let idx = index {
                    self.links[idx] = newLink
                } else {
                    self.links.append(newLink)
                }
                
                self.saveLinks()
                self.tableView.reloadData()
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Color Picker
    func showColorPicker(completion: @escaping (UIColor) -> Void) {
        let colors: [(String, UIColor)] = [
            ("Red", .systemRed),
            ("Blue", .systemBlue),
            ("Green", .systemGreen),
            ("Orange", .systemOrange),
            ("Purple", .systemPurple)
        ]
        
        let alert = UIAlertController(title: "Pick a Color", message: nil, preferredStyle: .actionSheet)
        
        for colorOption in colors {
            alert.addAction(UIAlertAction(title: colorOption.0, style: .default, handler: { _ in
                completion(colorOption.1)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return links.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let link = links[indexPath.row]

        // main title
        cell.textLabel?.text = link.title

        // subtitle
        cell.detailTextLabel?.text = link.url
        cell.detailTextLabel?.textColor = .secondaryLabel

        // colored dot
        cell.imageView?.image = UIImage(systemName: "circle.fill")?.withRenderingMode(.alwaysTemplate)
        cell.imageView?.tintColor = UIColor(hex: link.colorHex)

        cell.accessoryType = .disclosureIndicator
        return cell
    }

    
    // MARK: - Open URL
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let link = links[indexPath.row]
        if let url = URL(string: link.url) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Swipe Actions (Edit/Delete)
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        
        let link = links[indexPath.row]
        
        let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, done in
            self.links.remove(at: indexPath.row)
            self.saveLinks()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            done(true)
        }
        
        let edit = UIContextualAction(style: .normal, title: "Edit") { _, _, done in
            self.showAddEditLink(link, index: indexPath.row)
            done(true)
        }
        edit.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [delete, edit])
    }
    
    // MARK: - UserDefaults
    func saveLinks() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(links) {
            UserDefaults.standard.set(encoded, forKey: "links")
        }
    }
    
    func loadLinks() {
        if let data = UserDefaults.standard.data(forKey: "links"),
           let decoded = try? JSONDecoder().decode([LinkItem].self, from: data) {
            links = decoded
        }
    }
}
