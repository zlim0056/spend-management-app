//
//  LocationChart.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 21/09/2025.
//

import Foundation
import SwiftUI
import Charts

// Represents a summary of total amount expense or income for all location
struct LocationSummary: Identifiable {
    var id = UUID()
    var locationName: String
    var totalAmount: Double
}

struct LocationSummariesPieChartView: View {
    // Data source for the chart
    @State var summaries: [LocationSummary] = []
    
    // Expense or income
    var type: FinancialType
    
    // Selected month and year
    var monthAndYear: MonthAndYear
    
    // Initializer
    init(type: FinancialType, monthAndYear: MonthAndYear) {
        self.type = type
        self.monthAndYear = monthAndYear
    }
    
    // Calculates total amount across all locations
    var totalAmount: Double {
        var total: Double = 0
        for record in summaries {
            total += record.totalAmount
        }
        return total
    }
    
    var body: some View {
        VStack {
            // Show message if there are no records
            if summaries.isEmpty {
                Text("No records yet")
                    .foregroundColor(.gray)
            } else {
                ZStack {
                    // Pie chart
                    Chart(summaries) { summary in
                        SectorMark(
                            angle: .value("Amount", summary.totalAmount),
                            innerRadius: .ratio(0.618),
                            angularInset: 1.5
                        )
                        .cornerRadius(5)
                        .foregroundStyle(by: .value("Location", summary.locationName))
                        
                        // Add text labels inside the pie chart (category and percentage)
                        .annotation(position: .overlay) {
                            VStack {
                                Text(summary.locationName)
                                    .font(.caption2)
                                    .bold()
                                    .foregroundColor(.primary)
                                
                                Text(String(format: "%.2f%%", percentage(for: summary)))
                                    .font(.caption2)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .chartLegend(.visible)
                    .chartLegend(position: .top)
                    .frame(maxHeight: .infinity)
                    .padding()
                    
                    // Show total amount in the middle of the donut
                    VStack {
                        Text("Total")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(String(format: "%.2f", totalAmount))
                            .font(.title2)
                            .bold()
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        // Refresh chart when screen appears
        .onAppear {
            loadData()
        }
        // Refresh chart when type change
        .onChange(of: type) {
            loadData()
        }
        // Refresh chart when monthAndYear change
        .onChange(of: monthAndYear) {
            loadData()
        }
    }
    
    // Calculate percentage contribution for a location
    func percentage(for summary: LocationSummary) -> Double {
        guard totalAmount > 0 else {
            return 0
        }
        return (summary.totalAmount / totalAmount) * 100
    }
    
    // Fetch data from Core Data based on selected type and monthAndYear
    func loadData() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let databaseController = appDelegate?.databaseController as? CoreDataController
        self.summaries = databaseController?.fetchLocationsBasedOnFinancialType(for: type, month: monthAndYear.month, year: monthAndYear.year) ?? []
    }
}
