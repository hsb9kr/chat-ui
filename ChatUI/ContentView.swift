//
//  ContentView.swift
//  ChatUI
//
//  Created by red on 2023/09/05.
//

import SwiftUI
import SwiftUIIntrospect

struct ContentView: View {
	
	@StateObject var viewModel: TherapySessionViewModel = .init()
	
    var body: some View {
		NavigationView {
			ScrollViewReader { proxy in
				VStack(spacing: 0) {
					ScrollView(.vertical) {
						LazyVStack(spacing: 8) {
							if viewModel.isTyping {
								RiveAnimationView(size: 16)
									.id("typing")
							}
							ForEach(viewModel.items.reversed()) { item in
								ItemView(viewModel: item)
									.flippedUpsideDown()
									.id(item.id)
							}
						}
						.padding()
					}
					.flippedUpsideDown()
					.frame(maxHeight: .infinity)
					.background(VStack {
						Spacer()
						Rectangle()
							.frame(width: 100, height: 100)
							.foregroundColor(Color.cyan)
							.offset(y: 50)
					})
					.onAppear {
						viewModel.scrollViewProxy = proxy
					}
					
					HStack {
						Group {
							if #available(iOS 16.0, *) {
								TextField("placeholder", text: $viewModel.text, axis: .vertical)
									.lineLimit(4)
									.onSubmit {
										viewModel.onSubmit()
									}
							} else {
								TextEditor(text: $viewModel.text)
									.frame(height: min(viewModel.height, 80))
									.frame(maxHeight: min(viewModel.height, 80))
									.introspect(.textEditor, on: .iOS(.v15)) { view in
										view.delegate = viewModel
										view.textContainer.lineFragmentPadding = 0
										view.textContainerInset = .zero
										view.contentInset = .zero
										view.backgroundColor = .clear
										viewModel.sizeToFit(textView: view)
									}
									.onSubmit {
										viewModel.onSubmit()
									}
							}
						}
						
						Button {
							viewModel.onSubmit()
						} label: {
							Image(systemName: "arrow.up.circle")
								.resizable()
								.frame(width: 28, height: 28)
								.background(Color.blue.opacity(0.1))
								.clipShape(Circle())
						}
						.disabled(viewModel.text.isEmpty)
					}
					.padding(8)
					.background(Color.white)
					.clipShape(RoundedRectangle(cornerRadius: 8))
					.padding(8)
				}
				.background(Color.brown)
			}
			
			.navigationTitle(Text("Chat"))
			.navigationBarTitleDisplayMode(.inline)
		}
    }
	
	struct ItemView: View {
		@ObservedObject var viewModel: MessageItemViewModel
		
		var body: some View {
			HStack(spacing: 30) {
				if viewModel.isOwn {
					Spacer()
				}
				Text(viewModel.text)
					.padding()
					.background(viewModel.isOwn ? Color.red : Color.yellow)
					.clipShape(RoundedRectangle(cornerRadius: 8))
				if !viewModel.isOwn {
					Spacer()
				}
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct FlippedUpsideDown: ViewModifier {
	func body(content: Content) -> some View {
		content
			.rotationEffect(Angle.radians(.pi))
			.scaleEffect(x: -1, y: 1, anchor: .center)
	}
}
extension View{
	func flippedUpsideDown() -> some View{
		self.modifier(FlippedUpsideDown())
	}
	
	
	@ViewBuilder
	public func modify<T: View>(
		@ViewBuilder transform: (Self) -> T
	) -> some View {
		transform(self)
	}
}
