//
//  ContentView.swift
//  MetalShare
//
//  Created by shaoqianming on 2021/6/18.
//

import SwiftUI

struct ContentView: View {
    var items:[String] = [
        "Demo Triangle",
        "Demo Texture",
        "Demo LookupFilter",
        "Demo BlendMode",
        "Demo AdjustFilter",
        "Demo GaussianBlur",
        "Demo Matting"
    ];
    
    var body: some View {
        NavigationView {
            List(items.indices , id:\.self){ index in
                NavigationLink(
                    destination: buildDetailPage(index: index),
                    label: {
                        ItemListRow(item: items[index])
                    })
            }.navigationTitle(Text("MetalShare"))
        }.navigationViewStyle(StackNavigationViewStyle())
    }
    
    func buildDetailPage(index : Int) -> some View {
        var enterFrom: String
        switch index {
        case 0:
            enterFrom = "Triangle"
        case 1:
            enterFrom = "Texture"
        case 2:
            enterFrom = "LookupFilter"
        case 3:
            enterFrom = "BlendMode"
        case 4:
            enterFrom = "Adjust"
        case 5:
            enterFrom = "GaussianBlur"
        case 6:
            enterFrom = "Matting"
        default:
            return AnyView(
                Text("I'm default detail page.")
            )
        }
        return AnyView(
            MetalBasicView(enterfrom: enterFrom).navigationTitle(enterFrom)
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ItemListRow: View {
    var item: String
    var body: some View {
        HStack {
            Text(item).font(.headline).padding(.leading, 20)
        }
    }
}

struct MetalBasicView: UIViewControllerRepresentable {
    var enterfrom: String
    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = MetalBasicViewController()
        vc.enterFrom = enterfrom
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}
