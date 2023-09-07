//
//  ReceiveMessageData.swift
//  ChatUI
//
//  Created by red on 2023/09/06.
//

import Foundation

enum EmotionStatus: String, Codable {
	case happiness = "Happiness"
	case sadness = "Sadness"
	case anger = "Anger"
	case anticipation = "Anticipation"
	case fear = "Fear"
	case loneliness = "Loneliness"
	case jealousy = "Jealousy"
	case disgust = "Disgust"
	case surprise = "Surprise"
	case trust = "Trust"
	case ask = "Ask"
}

struct ReceiveMessageData: Codable {
	let status: String
	let result: ReceiveMessageResult
	let token_usage: TokenUsage
}

struct ReceiveMessageResult: Codable {
	let action: String
	let user: String
	let emotion: EmotionStatus
	let recall_thought: String
	let remember_thought: String
	let answer: String
}

struct TokenUsage: Codable {
	let prompt_tokens: Int
	let completion_tokens: Int
}
