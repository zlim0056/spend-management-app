//
//  OverviewChart.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 21/09/2025.
//

import Foundation
import SwiftUI
import Charts

// Represents total income or expense per day
struct OverviewSummary: Identifiable {
    var id = UUID()
    var date: Date
    var type: FinancialType
    var totalAmount: Double
}

struct OverviewSummariesPieChartView: View {
    // Chart data (loaded dynamically)
    @State var summaries: [OverviewSummary] = []
    
    // Selected month and year
    var monthAndYear: MonthAndYear
    
    // Initializer
    init(monthAndYear: MonthAndYear) {
        self.monthAndYear = monthAndYear
    }
    
    var body: some View {
        VStack {
            // Show message if there are no records
            if summaries.isEmpty {
                Text("No records yet")
                    .foregroundColor(.gray)
            } else {
                // I acknowledge the use of ChatGPT (https://chatgpt.com/) to learn how to get entire month can displayed properly without conflict and crash together. The output (here) was showing how to using Calendar to display well the entire month in chart by using minus time interval for the 1st day of month and add time interval for last day of the month.
                let cal = Calendar.autoupdatingCurrent
                let monthStart = summaries.first!.date
                let oneDayTimeInterval = 24 * 60 * 60
                let monthStartBefore = monthStart.addingTimeInterval(TimeInterval(-oneDayTimeInterval / 2))
                let nextMonthStart = cal.date(byAdding: .month, value: 1, to: monthStart)!
                let barPerPage = 4

                // Bar chart
                Chart(summaries) {summary in
                    BarMark(
                        x: .value("Day", summary.date.startOfDay),
                        y: .value("Amount", summary.totalAmount),
                        width: .fixed(40)
                    )
                    .foregroundStyle(summary.type == .expense ? .red : .green)
                    .annotation(position: summary.type == .expense ? .bottom : .top) {
                        if summary.totalAmount != 0 {
                            Text(String(format: "%.2f", summary.totalAmount))
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding()
                .frame(maxHeight: .infinity)
                // Make the x-axis scale to display the entire month
                .chartXScale(domain: monthStartBefore...nextMonthStart)
                // Make the bar chart scrollable horizontally
                .chartScrollableAxes(.horizontal)
                // Make the visible domain as oneDayTimeInterval * barPerPage (don't display too many bar chart in a page as it will become too small)
                .chartXVisibleDomain(length: oneDayTimeInterval * barPerPage)
            }
        }
        // Refresh chart when screen appears
        .onAppear {
            loadData()
        }
        // Refresh chart when monthAndYear change
        .onChange(of: monthAndYear) {
            loadData()
        }
    }
    
    // Fetch data from Core Data based on selected monthAndYear
    func loadData() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let databaseController = appDelegate?.databaseController as? CoreDataController
        self.summaries = databaseController?.fetchOverviewBasedOnFinancialType(month: monthAndYear.month, year: monthAndYear.year) ?? []
    }
}
