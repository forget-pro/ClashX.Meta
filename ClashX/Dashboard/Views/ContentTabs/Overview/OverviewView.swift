//
//  OverviewView.swift
//  ClashX Dashboard
//
//

import SwiftUI

struct OverviewView: View {
	
	@EnvironmentObject var data: ClashOverviewData
	
	@State private var columnCount: Int = 4
	
	@State private var version: String = ""
	
    var body: some View {
		VStack(spacing: 25) {
			
			ZStack(alignment: .topLeading) {
				LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columnCount)) {
					
					OverviewTopItemView(name: "Upload", value: $data.uploadString)
					OverviewTopItemView(name: "Download", value: $data.downloadString)
					OverviewTopItemView(name: "Upload Total", value: $data.uploadTotal)
					OverviewTopItemView(name: "Download Total", value: $data.downloadTotal)
					
					OverviewTopItemView(name: "Active Connections", value: $data.activeConns)
					OverviewTopItemView(name: "Memory Usage", value: $data.memory)
					OverviewTopItemView(name: "Mihomo", value: $version)
				}
				GeometryReader { geometry in
					Rectangle()
						.fill(.clear)
						.frame(height: 1)
						.onChange(of: geometry.size.width) { newValue in
							updateColumnCount(newValue)
						}
						.onAppear {
							updateColumnCount(geometry.size.width)
						}
				}
				.frame(height: 1)
				.padding()
			}
			

			HStack {
				RoundedRectangle(cornerRadius: 2)
					.fill(Color(compatible: .systemBlue))
					.frame(width: 20, height: 13)
				Text("Down")
				
				RoundedRectangle(cornerRadius: 2)
					.fill(Color(compatible: .systemGreen))
					.frame(width: 20, height: 13)
				Text("Up")
			}
			
			
			TrafficGraphView(values: $data.downloadHistories,
							 graphColor: .systemBlue)

			TrafficGraphView(values: $data.uploadHistories,
							 graphColor: .systemGreen)

		}
		.padding()
		.onAppear {
			ApiRequest.requestVersion {
				self.version = $0?.version ?? ""
			}
		}
        .background(Color("SwiftUI Colors/WindowBackgroundColor"))
    }
	
	func updateColumnCount(_ width: Double) {
		let v = Int(Int(width) / 155)
		let new = v == 0 ? 1 : v
		
		if new != columnCount {
			columnCount = new
		}
	}
	
}

//struct OverviewView_Previews: PreviewProvider {
//    static var previews: some View {
//        OverviewView()
//    }
//}
