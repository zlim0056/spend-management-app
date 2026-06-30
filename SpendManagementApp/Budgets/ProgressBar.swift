//
//  ProgressBar.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 05/10/2025.
//

import SwiftUI

struct ProgressBar: View {
    // Current spent amount (amount1) and total budget (amount2)
    var amount1: CGFloat
    var amount2: CGFloat
    
    // Define bar size relative to screen width and height
    let width: CGFloat = UIScreen.main.bounds.width * 0.9
    let height: CGFloat = UIScreen.main.bounds.height * 0.05
    
    // Define colors for different progress levels
    let color1 = Color.green
    let color2 = Color.yellow
    let color3 = Color.red
    
    var body: some View {
        // Corner radius for the bar
        let radius: CGFloat = height / 7

        // Calculate the percentage of amount1 compared to amount2
        let percentTest = (amount1 / amount2) * 100
        let percent = percentTest > 100 ? 100 : percentTest
        
        ZStack(alignment: .leading) {
            // Background bar (base color)
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .frame(width: width, height: height)
                .foregroundColor(Color("ProgressBarColour"))
            
            // Filled portion (progress indicator)
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .frame(width: percent * (width / 100), height: height)
                // Background color changes based on usage percentage
                .background(percent > 80 ? color3 : (percent > 60 ? color2 : color1))
                .foregroundColor(.clear)
            
            // Overlay text showing numbers and percentage
            HStack {
                // Current amount spent
                Text(String(format: "  %.2f", amount1))
                    .bold()
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Percentage used
                Text(String(format: "%.2f%%", percentTest))
                    .bold()
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Total budget amount
                Text(String(format: "%.2f  ", amount2))
                    .bold()
                    .foregroundColor(.primary)
            }
            .frame(width: width, height: height)
        }
        // Round off the bar edges (without this, it will become sharp corner)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}
