//
//  RiveAnimationView.swift
//  ChatUI
//
//  Created by red on 2023/09/05.
//

import SwiftUI

struct RiveAnimationView: View {
	
	@State var state: [Bool]
	let animation: Animation
	let duration: CGFloat
	let size: CGFloat
	
	init(size: CGFloat = 30, count: Int = 3, duration: CGFloat = 1) {
		self.size = size
		self.state = .init(repeating: false, count: count)
		self.duration = duration
		self.animation = Animation.linear(duration: duration).repeatForever()
	}
	
	var body: some View {
		HStack {
			Group {
				Circle()
					.foregroundColor(state[0] ? .gray : .black)
				Circle()
					.foregroundColor(state[1] ? .gray : .black)
				Circle()
					.foregroundColor(state[2] ? .gray : .black)
			}
			.frame(width: size, height: size)
		}
		.onAppear {
			for i in 0..<state.count {
				withAnimation(animation.delay(duration / CGFloat(state.count) * CGFloat(i))) {
					state[i].toggle()
				}
			}
		}
	}
}
