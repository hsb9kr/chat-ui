//
//  MessageData.swift
//  ChatUI
//
//  Created by red on 2023/09/06.
//

import Foundation

struct SendMessageData: Codable {
	let dialog_id: String
	let user_id: String
	let message: String
}
