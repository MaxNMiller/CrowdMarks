import UIKit
import FirebaseFirestore

class DiscussionBoardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageInput: UITextField!

    private let db = Firestore.firestore()
    private var messages: [String] = [] // Store your messages here

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MessageTableViewCell.self, forCellReuseIdentifier: "MessageCell")
        
        loadMessages()
    }

    @IBAction func submitMessage(_ sender: UIButton) {
        guard let message = messageInput.text, !message.isEmpty else { return }
        
        // Save the message to Firestore
        db.collection("messages").addDocument(data: ["text": message, "timestamp": FieldValue.serverTimestamp()]) { error in
            if let error = error {
                print("Error adding message: \(error.localizedDescription)")
            } else {
                self.messageInput.text = ""
                self.loadMessages() // Reload messages after adding a new one
            }
        }
    }

    private func loadMessages() {
        db.collection("messages").order(by: "timestamp").getDocuments { snapshot, error in
            if let error = error {
                print("Error loading messages: \(error.localizedDescription)")
                return
            }
            
            self.messages = snapshot?.documents.compactMap { $0.data()["text"] as? String } ?? []
            self.tableView.reloadData()
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageTableViewCell
        
        // Configure the cell
        cell.messageLabel.text = messages[indexPath.row]
        cell.messageBackgroundView.backgroundColor = .systemBlue // Change to your desired color
        return cell
    }
    
    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension // Allows dynamic height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44 // Default height for estimation
    }
}

// Custom UITableViewCell for messages
class MessageTableViewCell: UITableViewCell {
    
    let messageBackgroundView = UIView()
    let messageLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // Setup messageBackgroundView
        messageBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        messageBackgroundView.layer.cornerRadius = 8
        messageBackgroundView.clipsToBounds = true
        contentView.addSubview(messageBackgroundView)
        
        // Setup messageLabel
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0 // Allows multiline text
        messageBackgroundView.addSubview(messageLabel)

        // Constraints
        NSLayoutConstraint.activate([
            messageBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            messageBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            messageBackgroundView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            messageBackgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            messageLabel.leadingAnchor.constraint(equalTo: messageBackgroundView.leadingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: messageBackgroundView.trailingAnchor, constant: -8),
            messageLabel.topAnchor.constraint(equalTo: messageBackgroundView.topAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: messageBackgroundView.bottomAnchor, constant: -8),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
