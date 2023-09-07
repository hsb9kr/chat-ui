//
//  ViewModel.swift
//  ChatUI
//
//  Created by red on 2023/09/05.
//

import SwiftUI
import Alamofire
import Starscream
import Combine

@MainActor
class TherapySessionViewModel: NSObject, ObservableObject {

	private var cancellables: Set<AnyCancellable> = []
	private let manager = Session()
	private let uuid: String = UUID().uuidString
	private let userId: String = "Le4wAfoAepRGvYa755WcSUk8Zg82"
	private var socket: WebSocket?
	private var isConnected: Bool = false
	private var queue: [MessageItemViewModel] = []
	var scrollViewProxy: ScrollViewProxy?
	@Published var items: [MessageItemViewModel] = []
	@Published var text: String = ""
	@Published var height: CGFloat = 0
	@Published var isTyping: Bool = false
	@Published var emotionStatus: EmotionStatus = .happiness
	
	override init() {
		super.init()
		Task {
			await onStart()
		}
		
		$text
			.filter { [weak self] _ in
				guard let `self` = self else { return false }
				return !queue.isEmpty
			}
			.debounce(for: 1, scheduler: RunLoop.main)
			.sink { [weak self] _ in
				guard let `self` = self else { return }
				self.send()
			}
			.store(in: &cancellables)
	}
	
	func onSubmit() {
		let item: MessageItemViewModel = .init(isOwn: true, text: text)
		queue.append(item)
		add(item: item)
		text = ""
		isTyping = true
		scrollViewProxy?.scrollTo("typing")
	}
	
	func send() {
		guard let socket = socket, isConnected, !queue.isEmpty else {
			return
		}
		
		let message: String = queue.map { $0.text }.joined(separator: "\n")
		queue.removeAll()
		do {
			let message: SendMessageData = .init(dialog_id: uuid, user_id: userId, message: message)
			let data: Data = try JSONEncoder().encode(message)
			socket.write(stringData: data) {
				debugPrint("send success")
			}
		} catch {
			debugPrint(error)
		}
	}
	
	func add(item: MessageItemViewModel) {
		items.append(item)
	}
	
	func onStart() async {

		let result = await manager
			.request(
				"https://momory-chatbot.azurewebsites.net/mu/start-counceling",
				method: .post,
				parameters: [
					"dialog_id" : uuid,
					"user_id" : userId,
					"user_name" : "Fsdfsa",
					"language_code" : "kor",
					"latitude" : "37.532600",
					"longitude" : "127.024612"
				],
				encoder: JSONParameterEncoder.default
			)
			.serializingDecodable(DataWrapper.self)
			.response
		
		
		switch result.result {
			case .success(let data):
				debugPrint(data)
				connect()
			case .failure(let error):
				debugPrint(error)
		}
	}
	
	func connect() {
		if isConnected, let _ = socket {
			disconnect()
		}
		var request = URLRequest(url: URL(string: "wss://momory-chatbot.azurewebsites.net/mu/realtime-chat")!)
		request.timeoutInterval = 5
		socket = WebSocket(request: request)
		socket!.delegate = self
		socket!.connect()
	}
	
	func disconnect() {
		guard let socket = socket, isConnected else {
			return
		}
		
		socket.disconnect()
	}
}


extension TherapySessionViewModel: UITextViewDelegate {
	
	public func sizeToFit(textView: UITextView) {
		let fixedWidth = textView.frame.size.width
		let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
		debugPrint("height: \(height) new height: \(newSize.height)")
		if height != newSize.height {
			DispatchQueue.main.async {
				self.height = newSize.height
			}
		}
	}
	
	public func textViewDidChange(_ textView: UITextView) {
		self.text = textView.text
		sizeToFit(textView: textView)
	}
	
	public func textViewDidBeginEditing(_ textView: UITextView) {
		sizeToFit(textView: textView)
	}
	
	public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
		sizeToFit(textView: textView)
		return true
	}
}

extension TherapySessionViewModel: WebSocketDelegate {
	func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocketClient) {
		switch event {
			case .connected(let headers):
				isConnected = true
				print("websocket is connected: \(headers)")
			case .disconnected(let reason, let code):
				isConnected = false
				print("websocket is disconnected: \(reason) with code: \(code)")
			case .text(let string):
				print("Received text: \(string)")
				do {
					if let data = string.data(using: .utf8) {
						let messageData = try JSONDecoder().decode(ReceiveMessageData.self, from: data)
						if messageData.status == "finished" {
							isTyping = false
						} else if messageData.status == "sentence_finished" {
							emotionStatus = messageData.result.emotion
							let item: MessageItemViewModel = .init(isOwn: false, text: messageData.result.answer)
							add(item: item)
							scrollViewProxy?.scrollTo(item.id)
						}
					}
					
				} catch {
					debugPrint(error)
				}
			case .binary(let data):
				print("Received data: \(data.count)")
			case .ping(_):
				break
			case .pong(_):
				break
			case .viabilityChanged(_):
				break
			case .reconnectSuggested(_):
				break
			case .cancelled:
				isConnected = false
			case .error(let error):
				isConnected = false
				debugPrint(error)
			case .peerClosed:
				break
		}
	}
}


class MessageItemViewModel: Identifiable, ObservableObject {
	
	let id: UUID = .init()
	let isOwn: Bool
	@Published var text: String
	
	init(isOwn: Bool = true, text: String) {
		self.isOwn = isOwn
		self.text = text
	}
}
